local _, addon = ...
local L = addon.L
local PREFIX, MAX_ITEMS, MAX_PARTS = "GuildStockS1", 1400, 350
local state = {status = "waiting", sent = 0, received = 0}
addon.sync = state
local world, registered, guild, session, published, revision, dirtyAt, fresh
local members, memberUntil, readyAt, lastHello, offerAt, lastOffer, snapshotAt, lastSnapshot
local queue, outgoing, peers, removed = {}, nil, {}, {}
local nextSend, retries, retryAt = 0, 0, 0

local function Refresh() if addon.ScheduleRefresh then addon.ScheduleRefresh() end end
local function Token() return string.format("%d-%d", time(), math.random(1, 2147483647)) end
local function ValidToken(value) return type(value) == "string" and #value <= 32 and value:match("^%d+%-%d+$") end
local function Integer(value, low, high)
    if type(value) ~= "string" or not value:match("^%d+$") or #value > 10 then return end
    value = tonumber(value)
    if addon.Integer(value, low, high) then return value end
end
local function ClearTransport()
    session, published, revision, dirtyAt, fresh = Token(), nil, 0, nil, false
    queue, outgoing, peers = {}, nil, {}
    readyAt, lastHello, offerAt, lastOffer, snapshotAt, lastSnapshot = nil, nil, nil, nil, nil, nil
    retries, retryAt = 0, 0
end
local function SavedID(value)
    return (type(value) == "string" and #value > 0 and #value <= 200)
        or addon.Integer(value, 0, 9007199254740991)
end
local function History()
    if not addon.db or addon.temporary then return end
    local history = addon.db.guildHistory
    if type(history) == "table" and history.version == 1 and SavedID(history.guildID)
        and type(history.characters) == "table" then return history end
end
local function HistoricalCopy(name, character)
    if type(name) ~= "string" or #name == 0 or #name > 200 or type(character) ~= "table"
        or character.name ~= name or not SavedID(character.memberID)
        or not addon.Integer(character.receivedAt, 0, time())
        or not addon.ValidSnapshot(character.snapshot) or type(character.skills) ~= "table" then return end
    local skills, items, count = {}, {}, 0
    for i = 1, 2 do
        local key = character.skills[i]
        if key ~= nil then
            local valid
            for index, profession in ipairs(addon.professions) do
                if index ~= 7 and index ~= 8 and index ~= 9 and key == profession[1] then valid = true end
            end
            if not valid then return end
            skills[i] = key
        end
    end
    for id, item in pairs(character.snapshot.items) do
        count = count + 1
        if count > MAX_ITEMS then return end
        items[id] = {count = item.count, bound = item.bound}
    end
    -- Transport sessions and revisions must be negotiated again after login.
    return {name = name, memberID = character.memberID, skills = skills, receivedAt = character.receivedAt,
        snapshot = {observedAt = character.snapshot.observedAt, items = items}}
end
local function RestoreHistory()
    local history = History()
    if not addon.db or addon.temporary then return end
    if addon.db.guildHistory ~= nil and not history then return end -- Preserve unsupported saved data.
    if not guild then addon.db.guildHistory = nil; return end
    if not history or history.guildID ~= guild then
        if SavedID(guild) then addon.db.guildHistory = {version = 1, guildID = guild, characters = {}} end
        return
    end
    local count = 0
    for name, character in pairs(history.characters) do
        count = count + 1
        if count > 2000 then break end
        addon.guildData.characters[name] = HistoricalCopy(name, character)
    end
end
local function Scope()
    local current = addon.Read(C_Club and C_Club.GetGuildClubId)
    local absent = addon.Read(IsInGuild) == false
    if (absent and guild ~= nil) or (not absent and current ~= nil and current ~= guild) then
        if absent then guild = nil else guild = current end
        addon.guildData = guild and {guildID = guild, characters = {}} or nil
        RestoreHistory()
        members, memberUntil, removed = nil, nil, {}
        ClearTransport()
        if world and guild and addon.ScheduleScan then addon.ScheduleScan() end
    end
    return not absent and current ~= nil and current == guild
end
local function Unlocked()
    return world and addon.Read(InCombatLockdown) == false
        and addon.Read(C_ChatInfo and C_ChatInfo.InChatMessagingLockdown) == false
end
local function Roster()
    if not Unlocked() or not Scope()
        or addon.Read(C_Club and C_Club.AreMembersReady, guild) ~= true then return end
    if members and GetTime() < memberUntil then return members end
    local ids = addon.Read(C_Club and C_Club.GetClubMembers, guild)
    if type(ids) ~= "table" or #ids == 0 or #ids > 2000 then return end
    local found, own = {}, nil
    local presence = Enum and Enum.ClubMemberPresence
    if not presence then return end
    for _, id in ipairs(ids) do
        local info = addon.Accessible(id) and addon.Read(C_Club.GetMemberInfo, guild, id)
        if type(info) == "table" and addon.Accessible(info.name) and type(info.name) == "string"
            and #info.name > 0 and #info.name <= 200 and addon.Accessible(info.isSelf)
            and type(info.isSelf) == "boolean" and addon.Accessible(info.presence) and not removed[id] then
            local online = info.presence == presence.Online or info.presence == presence.Away or info.presence == presence.Busy
            found[info.name] = {id = id, isSelf = info.isSelf, online = online,
                offline = info.presence == presence.Offline,
                race = addon.Integer(info.race, 1, 2147483647) and info.race or nil}
            if info.isSelf then own = info.name end
        end
    end
    if not own then return end -- Empty/partial initialization must not erase cached peers.
    members, memberUntil = found, GetTime() + 5
    return members
end
function addon.SyncMember(name)
    local roster = Roster()
    return roster and roster[name]
end
local function Peer(name)
    local member = addon.SyncMember(name)
    if member and not member.isSelf and member.online then return member end
end
local function CanSend()
    if not registered or not Unlocked() then state.status = "waiting"; return false end
    -- Forever 70205 can report restricted=true while the native GUILD send returns Success.
    -- The native send result is authoritative; retain combat/lockdown gates and bounded retries.
    if not Roster() then state.status = "waiting"; return false end
    if addon.temporary or not addon.ShareableSnapshot() then state.status = "waiting"; return false end
    return true
end
local function Enqueue(message, recipient)
    if #message > 240 or #queue >= 128 then return false end
    for _, entry in ipairs(queue) do if entry.message == message then return true end end
    queue[#queue + 1] = {message = message, recipient = recipient, expires = GetTime() + 180}
    return true
end
local function PrimarySkills()
    local skills = {0, 0}
    if type(GetProfessions) ~= "function" or type(GetProfessionInfo) ~= "function" then return "0,0" end
    local indices = {pcall(GetProfessions)}
    if not indices[1] then return "0,0" end
    for i = 1, 2 do
        if addon.Integer(indices[i + 1], 1, 1000) then
            local info = {pcall(GetProfessionInfo, indices[i + 1])}
            if info[1] and addon.Integer(info[8], 1, 2147483647) then
                local data = addon.Read(C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID, info[8])
                if type(data) == "table" and addon.Integer(data.profession, 0, 100) then
                    for index, profession in ipairs(addon.professions) do
                        if index ~= 7 and index ~= 8 and index ~= 9 and Enum.Profession
                            and Enum.Profession[profession[1]] == data.profession then skills[i] = index end
                    end
                end
            end
        end
    end
    return table.concat(skills, ",")
end
local function Build()
    if not fresh or addon.incomplete then return end
    local snapshot = addon.ShareableSnapshot()
    if not snapshot then return end
    local ids, catalog = {}, addon.Catalog()
    for id in pairs(snapshot.items) do if type(catalog[id]) == "table" then ids[#ids + 1] = id end end
    if #ids > MAX_ITEMS then state.status = "limited"; return end
    table.sort(ids)
    local values = {}
    for _, id in ipairs(ids) do
        local item = snapshot.items[id]
        values[#values + 1] = string.format("%d,%d,%d", id, item.count, item.bound)
    end
    local skills = PrimarySkills()
    return {values = values, skills = skills, observedAt = snapshot.observedAt,
        key = skills .. ":" .. table.concat(values, ";")}
end
function addon.SyncChanged()
    if world then Scope() end
    fresh = not addon.incomplete
    local current = Build()
    if not current then outgoing = nil; return end
    if published and current.key ~= published.key then
        if not dirtyAt then dirtyAt = GetTime() end -- Fixed deadline; activity cannot postpone it.
        outgoing = nil -- Never finish a transfer containing newly excluded or changed items.
    end
end
local function ScheduleSnapshot()
    local due = math.max(GetTime() + math.random(2, 8), (lastSnapshot or -30) + 30)
    snapshotAt = snapshotAt and math.min(snapshotAt, due) or due
end
local function Offer(discovery)
    if not published then return end
    Enqueue("1|" .. (discovery and "H" or "O") .. "|" .. session .. "|" .. revision)
    lastOffer = GetTime()
    if discovery then lastHello = GetTime() end
end
function addon.SyncDiscover()
    if published and CanSend() and (not lastHello or GetTime() - lastHello >= 60) then
        for _, peer in pairs(peers) do
            if not peer.token and not peer.due then peer.offered = nil end
        end
        Offer(true)
    end
end
local function Publish(current)
    published, revision, dirtyAt = current, revision + 1, nil
    if revision == 1 then Offer(true) else Offer(false) end
    ScheduleSnapshot()
end
local function Request(name, peer)
    if peer.attempts >= 3 then return end
    peer.attempts = peer.attempts + 1
    peer.token, peer.due, peer.timeout = Token(), nil, GetTime() + 300
    Enqueue("1|Q|" .. peer.wanted .. "|" .. session .. "|" .. peer.token, name)
end
local function Commit(name, peer)
    local transfer = peer.transfer
    if not transfer or not transfer.complete or peer.allowed ~= transfer.session then return end
    if (peer.minimum and transfer.revision < peer.minimum)
        or (peer.wanted == transfer.session and peer.offered and transfer.revision < peer.offered) then
        peer.transfer = nil; return
    end
    local previous = addon.guildData.characters[name]
    if previous and previous.session == transfer.session and previous.revision >= transfer.revision then
        peer.transfer = nil; return
    end
    addon.guildData.characters[name] = {name = name, memberID = peer.memberID, session = transfer.session,
        revision = transfer.revision, skills = transfer.skills, receivedAt = time(),
        snapshot = {items = transfer.items, observedAt = math.min(time(), transfer.observedAt)}}
    local history = History()
    if history and history.guildID == guild then
        history.characters[name] = HistoricalCopy(name, addon.guildData.characters[name])
    end
    peer.transfer, peer.timeout, peer.token, peer.due, peer.attempts = nil, nil, nil, nil, 0
    state.received = state.received + 1
    Refresh()
end
local function DecodeSkills(value)
    local a, b = value:match("^(%d+),(%d+)$")
    a, b = Integer(a, 0, 12), Integer(b, 0, 12)
    if not a or not b or a == 7 or a == 8 or a == 9 or b == 7 or b == 8 or b == 9 then return end
    return {[1] = a > 0 and addon.professions[a][1] or nil, [2] = b > 0 and addon.professions[b][1] or nil}
end
local function Snapshot(name, peer, fields)
    local remote, rev = fields[3], Integer(fields[4], 1, 2147483647)
    local part, total = Integer(fields[5], 1, MAX_PARTS), Integer(fields[6], 1, MAX_PARTS)
    local observed = Integer(fields[7], math.max(0, time() - 604800), time() + 300)
    local skills = fields[8] and DecodeSkills(fields[8])
    if #fields ~= 9 or not rev or not part or not total or part > total or not observed or not skills
        or (remote ~= peer.allowed and remote ~= peer.wanted) then return end
    if remote == peer.wanted and peer.offered and rev < peer.offered then return end
    if remote == peer.allowed and peer.minimum and rev < peer.minimum then return end
    local previous = addon.guildData.characters[name]
    if previous and previous.session == remote and rev <= previous.revision then return end
    local transfer = peer.transfer
    if transfer and transfer.session == remote and rev < transfer.revision then return end
    if not transfer or transfer.session ~= remote or transfer.revision ~= rev then
        local count = 0
        for _, value in pairs(peers) do if value.transfer then count = count + 1 end end
        if count >= 16 then return end
        transfer = {session = remote, revision = rev, total = total, observedAt = observed, skills = skills,
            skillText = fields[8], parts = {}, items = {}, count = 0, started = GetTime()}
        peer.transfer = transfer
    end
    if total ~= transfer.total or observed ~= transfer.observedAt or fields[8] ~= transfer.skillText then return end
    if transfer.parts[part] then return end
    local items, count = {}, 0
    if fields[9] ~= "" then
        for entry in (fields[9] .. ";"):gmatch("(.-);") do
            local id, quantity, bound = entry:match("^(%d+),(%d+),(%d+)$")
            id, quantity = Integer(id, 1, 2147483647), Integer(quantity, 1, 2147483647)
            bound = Integer(bound, 0, quantity or 0)
            if not id or not quantity or not bound or items[id] or transfer.items[id] then return end
            count = count + 1
            if count > 4 then return end
            items[id] = {count = quantity, bound = bound}
        end
    elseif total ~= 1 then return end
    for id, item in pairs(items) do transfer.items[id] = item end
    transfer.parts[part], transfer.count = true, transfer.count + 1
    transfer.complete = transfer.count == total
    Commit(name, peer)
end
function addon.ReceiveSync(prefix, message, channel, sender)
    for _, value in ipairs({prefix, message, channel, sender}) do
        if not addon.Accessible(value) or type(value) ~= "string" then return end
    end
    if type(message) ~= "string" or type(sender) ~= "string" or prefix ~= PREFIX or channel ~= "GUILD"
        or #message > 240 or #sender > 200 or not registered then return end
    local member = Peer(sender)
    if not member then return end
    local fields = {}
    for field in (message .. "|"):gmatch("(.-)|") do fields[#fields + 1] = field end
    if fields[1] ~= "1" or not ValidToken(fields[3]) then return end
    local kind, remote = fields[2], fields[3]
    local peer = peers[sender]
    if not peer then
        local count = 0
        for _ in pairs(peers) do count = count + 1 end
        if count >= 200 then state.status = "limited"; return end
        peer = {memberID = member.id, attempts = 0}; peers[sender] = peer
    end
    if kind == "H" or kind == "O" then
        local rev = Integer(fields[4], 1, 2147483647)
        if #fields ~= 4 or not rev then return end
        local previous = addon.guildData.characters[sender]
        if not previous or previous.session ~= remote or previous.revision < rev then
            if not peer.token and not peer.due and (peer.wanted ~= remote or peer.offered ~= rev) then
                peer.wanted, peer.offered, peer.attempts = remote, rev, 0
                peer.due = GetTime() + math.random(2, 12)
            end
        end
        if kind == "H" then
            -- A recent offer may predate this client's login. Defer its reply rather than
            -- dropping it: otherwise the newcomer can remain without peer inventories while idle.
            offerAt = offerAt or math.max(GetTime() + math.random(2, 12), (lastOffer or -30) + 30)
        end
    elseif kind == "Q" then
        if #fields ~= 5 or remote ~= session or not ValidToken(fields[4]) or not ValidToken(fields[5])
            or not published or (peer.lastReply and GetTime() - peer.lastReply < 30) or not CanSend() then return end
        peer.lastReply = GetTime()
        Enqueue("1|A|" .. session .. "|" .. revision .. "|" .. fields[4] .. "|" .. fields[5], sender)
        ScheduleSnapshot() -- Coalesced GUILD snapshot serves every waiting guild client.
    elseif kind == "A" then
        if #fields ~= 6 or fields[5] ~= session or fields[6] ~= peer.token or remote ~= peer.wanted
            or not peer.timeout or GetTime() >= peer.timeout or not Integer(fields[4], 1, 2147483647) then return end
        peer.allowed = remote -- A new session must answer this client's fresh challenge.
        peer.minimum = Integer(fields[4], 1, 2147483647)
        Commit(sender, peer)
    elseif kind == "S" then Snapshot(sender, peer, fields) end
end
local function Flush()
    if GetTime() < nextSend or GetTime() < retryAt or not CanSend() then return end
    while queue[1] and (GetTime() >= queue[1].expires or (queue[1].recipient and not Peer(queue[1].recipient))) do
        table.remove(queue, 1)
    end
    local message = queue[1] and queue[1].message
    if not message and outgoing then
        local values = {}
        for i = (outgoing.part - 1) * 4 + 1, math.min(outgoing.part * 4, #published.values) do
            values[#values + 1] = published.values[i]
        end
        message = table.concat({"1", "S", session, revision, outgoing.part, outgoing.total,
            published.observedAt, published.skills, table.concat(values, ";")}, "|")
    end
    if not message then return end
    if #message > 240 then outgoing, queue = nil, {}; state.status = "limited"; return end
    -- Rebuild from the filtered observation immediately before each data packet.
    if not queue[1] then
        local current = Build()
        if not current or current.key ~= published.key then outgoing = nil; return end
    end
    local result = addon.Read(C_ChatInfo and C_ChatInfo.SendAddonMessage, PREFIX, message, "GUILD")
    state.result = addon.ResultName(Enum and Enum.SendAddonMessageResult, result)
    nextSend = GetTime() + 0.5 -- <= 2 packets / 480 payload bytes per second, without catch-up bursts.
    if Enum and Enum.SendAddonMessageResult and result == Enum.SendAddonMessageResult.Success then
        retries, retryAt = 0, 0
        state.sent, state.status = state.sent + 1, "ready"
        if queue[1] then table.remove(queue, 1)
        else
            outgoing.part = outgoing.part + 1
            if outgoing.part > outgoing.total then outgoing = nil; Offer(false) end
        end
    else
        retries = retries + 1
        retryAt, state.status = GetTime() + math.min(30, 2 ^ retries), "failed"
        if retries >= 3 then
            queue, outgoing, snapshotAt, offerAt = {}, nil, nil, nil
            retries = 0; retryAt = GetTime() + 60
        end
    end
end
function addon.SyncTick()
    if not world or not addon.db then return end
    if not Scope() then state.status = "waiting"; return end
    if not CanSend() then return end
    local now = GetTime()
    local current = Build()
    if not current then state.status = "waiting"; return end
    if not readyAt then readyAt = now + math.random(2, 8) end
    if now < readyAt then return end
    if not published then Publish(current)
    else
        if current.key ~= published.key and not dirtyAt then dirtyAt = now end
        if dirtyAt and now - dirtyAt >= 300 then
            if current.key ~= published.key then Publish(current) else dirtyAt = nil end
        end
    end
    if offerAt and now >= offerAt then offerAt = nil; Offer(false) end
    if snapshotAt and now >= snapshotAt and not dirtyAt and not outgoing then
        snapshotAt, lastSnapshot = nil, now
        outgoing = {part = 1, total = math.max(1, math.ceil(#published.values / 4))}
    end
    for name, peer in pairs(peers) do
        if peer.transfer and now - peer.transfer.started >= 300 then
            if not peer.token and peer.attempts < 3 then
                peer.wanted, peer.offered = peer.transfer.session, peer.transfer.revision
                peer.due = now + math.random(2, 12)
            end
            peer.transfer = nil
        end
        if peer.timeout and now >= peer.timeout then
            peer.token, peer.timeout, peer.transfer = nil, nil, nil
            if peer.attempts < 3 then peer.due = now + math.random(2, 12) end
        end
        if peer.due and now >= peer.due then
            peer.due = nil
            if Peer(name) then Request(name, peer) end
        end
    end
    Flush()
end
function addon.SyncStatus()
    local titles = {waiting = "Waiting for guild, bags or messaging permissions", ready = "Automatic guild synchronization",
        failed = "Guild synchronization interrupted", limited = "Guild synchronization limit reached"}
    return L[titles[state.status] or titles.waiting], L["Changes are grouped for five minutes. Received inventories show their observation time."]
end
local events = CreateFrame("Frame")
for _, event in ipairs({"PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_LEAVING_WORLD", "PLAYER_GUILD_UPDATE", "SHARD_TRANSFER",
    "CLUB_MEMBERS_UPDATED", "CLUB_MEMBER_ADDED", "CLUB_MEMBER_REMOVED", "CLUB_MEMBER_UPDATED",
    "CLUB_MEMBER_PRESENCE_UPDATED", "CHAT_MSG_ADDON", "SKILL_LINES_CHANGED"}) do events:RegisterEvent(event) end
local elapsedTime = 0
events:SetScript("OnUpdate", function(_, elapsed)
    elapsedTime = elapsedTime + elapsed
    if elapsedTime >= 0.5 then
        elapsedTime = 0
        local previous = state.status
        addon.SyncTick()
        if state.status ~= previous then Refresh() end
    end
end)
events:SetScript("OnEvent", function(_, event, a, b, c, d)
    if event == "CHAT_MSG_ADDON" then addon.ReceiveSync(a, b, c, d)
    elseif event == "PLAYER_LOGIN" then
        local result = addon.Read(C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix, PREFIX)
        local values = Enum and Enum.RegisterAddonMessagePrefixResult
        registered = values and (result == values.Success or result == values.DuplicatePrefix)
        state.registration = addon.ResultName(values, result)
    elseif event == "PLAYER_LEAVING_WORLD" or event == "PLAYER_ENTERING_WORLD" or event == "SHARD_TRANSFER" then
        world = event ~= "PLAYER_LEAVING_WORLD"
        members, memberUntil = nil, nil
        ClearTransport() -- Retain dated same-guild records through shard/world transitions.
        if world and addon.ScheduleScan then addon.ScheduleScan() end
    elseif event == "SKILL_LINES_CHANGED" then addon.SyncChanged()
    else
        members, memberUntil = nil, nil
        if event == "CLUB_MEMBER_REMOVED" and addon.Accessible(a) and addon.Accessible(b) and b ~= nil and a == guild then
            removed[b] = true
            local history = History()
            if history and history.guildID == guild then
                for name, character in pairs(history.characters) do
                    if type(character) == "table" and character.memberID == b then history.characters[name] = nil end
                end
            end
            if addon.guildData then
                for name, character in pairs(addon.guildData.characters) do
                    if character.memberID == b then addon.guildData.characters[name], peers[name] = nil, nil end
                end
            end
            for name, peer in pairs(peers) do if peer.memberID == b then peers[name] = nil end end
        elseif event == "CLUB_MEMBER_ADDED" and addon.Accessible(a) and addon.Accessible(b) and b ~= nil and a == guild then removed[b] = nil end
        Scope()
        if event == "PLAYER_GUILD_UPDATE" and addon.ScheduleScan then addon.ScheduleScan() end
        Refresh()
    end
end)
