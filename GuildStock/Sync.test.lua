-- Two isolated addon instances, synthetic names/inventories and a controllable GUILD bus.
math.randomseed(17)
local clock, epoch, clients, bus, log = 0, 1800000000, {}, {}, {}
local filter
local secret = {}
local function Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}; for k, v in pairs(value) do result[k] = Copy(v) end; return result
end
local function Client(name, syncPath)
    local client = {name = name, guild = 42, rosterReady = true, online = true, restricted = false,
        lockdown = false, inventory = {[2770] = {count = 7, bound = 1}}, bank = {}, frames = {}, timers = {}, result = 0}
    local env = setmetatable({}, {__index = _G})
    env._G, env.SlashCmdList = env, {}
    env.GetLocale = function() return "enUS" end
    env.GetTime, env.time = function() return clock end, function() return epoch + math.floor(clock) end
    env.canaccessvalue = function(value) return value ~= secret end
    env.InCombatLockdown = function() return client.combat or false end
    env.IsInGuild = function() return client.guild ~= nil end
    env.GetProfessions = function() return 1, 2 end
    env.GetProfessionInfo = function(i) return "Synthetic", nil, (client.ranks or {52, 1})[i], 75, nil, nil, i end
    env.C_TradeSkillUI = {GetProfessionInfoBySkillLineID = function(i) return {profession = i} end}
    env.C_Item = {GetItemCount = function(id, includeBank, uses, reagentBank, accountBank)
        assert(includeBank == true and uses == false and reagentBank == false and accountBank == false)
        return (client.inventory[id] and client.inventory[id].count or 0) + (client.bank[id] or 0)
    end}
    env.Enum = {RegisterAddonMessagePrefixResult = {Success = 0, DuplicatePrefix = 1, InvalidPrefix = 2},
        SendAddonMessageResult = {Success = 0, AddonMessageThrottle = 3, AddOnMessageLockdown = 11},
        ClubMemberPresence = {Online = 1, Away = 2, Busy = 3, Offline = 4, OnlineMobile = 5},
        Profession = {Alchemy = 1, Mining = 2}}
    env.C_Timer = {After = function(delay, fn) client.timers[#client.timers + 1] = {due = clock + delay, fn = fn} end}
    env.CreateFrame = function()
        local frame = {events = {}, scripts = {}}
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:SetScript(event, fn) self.scripts[event] = fn end
        client.frames[#client.frames + 1] = frame
        return frame
    end
    env.C_ChatInfo = {
        RegisterAddonMessagePrefix = function() return client.registration or 0 end,
        AreOutgoingAddonChatMessagesRestricted = function() return client.restricted end,
        InChatMessagingLockdown = function() return client.lockdown end,
        SendAddonMessage = function(prefix, message, channel, target)
            assert(channel == "GUILD" and target == nil and #message <= 240)
            if not syncPath then assert(not message:match("^2|[DRT]|"), "updated clients never send relay packets") end
            assert(not client.combat and client.lockdown == false)
            log[#log + 1] = {sender = name, message = message, at = clock, guild = client.guild}
            if client.result == 0 then bus[#bus + 1] = {sender = name, message = message, prefix = prefix, guild = client.guild} end
            return client.result
        end,
    }
    env.C_Club = {
        GetGuildClubId = function() if not client.missingGuild then return client.guild end end,
        AreMembersReady = function() return client.rosterReady end,
        GetClubMembers = function()
            local ids = {}
            for id, peer in ipairs(clients) do if peer.guild == client.guild and not peer.removed then ids[#ids + 1] = peer.memberID or id end end
            return ids
        end,
        GetMemberInfo = function(_, id)
            local peer
            for index, value in ipairs(clients) do if (value.memberID or index) == id then peer = value; break end end
            if not peer then return end
            if client.unreadable == id then return {isSelf = false, presence = 4} end
            return {name = peer.name, isSelf = peer == client, presence = peer.online and 1 or 4, race = peer.race,
                profession1ID = peer.profession1ID, profession1Rank = peer.profession1Rank,
                profession2ID = peer.profession2ID, profession2Rank = peer.profession2Rank}
        end,
    }
    local addon = {}
    for _, file in ipairs({"Locales", "GuildStock", "Probe", "ItemNames", "CatalogSeed", "Catalog", "Sync", "Prices"}) do
        local fn = assert(loadfile(file == "Sync" and syncPath or "GuildStock/" .. file .. ".lua")); setfenv(fn, env); fn("GuildStock", addon)
    end
    client.addon, client.env = addon, env
    addon.CreateMinimapButton = function() end
    addon.ScanBags = function()
        if client.incomplete then return end
        return {observedAt = env.time(), items = Copy(client.inventory)}
    end
    function client:Event(event, ...)
        for _, frame in ipairs(self.frames) do if frame.events[event] then frame.scripts.OnEvent(frame, event, ...) end end
    end
    function client:Login()
        self:Event("ADDON_LOADED", "GuildStock"); self:Event("PLAYER_LOGIN"); self:Event("PLAYER_ENTERING_WORLD")
    end
    clients[#clients + 1] = client
    return client
end
local function Step(seconds)
    for _ = 1, seconds * 2 do
        clock = clock + 0.5
        for _, client in ipairs(clients) do if client.online and not client.disabled then
            local timers = client.timers; client.timers = {}
            for _, timer in ipairs(timers) do
                if timer.due <= clock then timer.fn() else client.timers[#client.timers + 1] = timer end
            end
            for _, frame in ipairs(client.frames) do if frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame, 0.5) end end
        end end
        local messages = bus; bus = {}
        for _, packet in ipairs(messages) do
            for _, client in ipairs(clients) do if client.online and not client.disabled and client.guild == packet.guild then
                if not filter or filter(packet, client) then client:Event("CHAT_MSG_ADDON", packet.prefix, packet.message, "GUILD", packet.sender) end
            end end
        end
    end
end
local function Received(client, owner) return client.addon.guildData and client.addon.guildData.characters[owner.name] end
local function Receive(client, sender, message, channel)
    client:Event("CHAT_MSG_ADDON", "GuildStockS2", message, channel or "GUILD", sender.name)
end
local a, b = Client("Alpha Example"), Client("Beta Example")
a.race, b.race = 1, 7
a.restricted, b.restricted = true, true -- Reported flag can disagree with native send permission.
b.inventory = {[2589] = {count = 4, bound = 0}, [2835] = {count = 2, bound = 0}, [999999] = {count = 99, bound = 0}}
a:Login(); b:Login(); Step(90)
assert(Received(a,b) and Received(b,a), "login alone must exchange complete inventories in both directions")
assert(Received(b,a).snapshot.items[2770].count == 7 and Received(a,b).snapshot.items[2589].count == 4)
assert(not Received(a,b).snapshot.items[999999], "only catalog materials are shared")
assert(Received(a,b).skills[1] == "Alchemy" and Received(a,b).skills[2] == "Mining")
assert(a.addon.SyncStatus() == "Automatic guild synchronization")
assert(#a.addon.GuildCharacters() == 1 and #a.addon.MaterialOwners(2589, true) == 1)
local quiet = #log; Step(600); assert(#log == quiet, "unchanged inventories must not emit heartbeats")
do
    a.env.C_AuctionHouse = {
        ReplicateItems = function() end,
        HasFullCommoditySearchResults = function() return true end,
        GetNumCommoditySearchResults = function() return 1 end,
        GetCommoditySearchResultInfo = function() return {quantity = 3, unitPrice = 81726345} end,
    }
    a:Event("AUCTION_HOUSE_SHOW")
    a:Event("COMMODITY_SEARCH_RESULTS_UPDATED", 2770)
    a:Event("AUCTION_HOUSE_CLOSED")
    Step(60)
    assert(a.addon.AuctionPrice(2770).copper == 81726345 and not b.addon.AuctionPrice(2770))
    assert(#log == quiet and Received(b,a).snapshot.items[2770].copper == nil,
        "auction observations stay local and cannot schedule or enter guild messages")
end
assert(a.addon.GuildCharacters()[1].race == 7 and a.addon.MaterialOwners(2589, true)[1].race == 7)
for _, race in ipairs({secret, "7", 0, 1.5}) do
    b.race = race; a:Event("CLUB_MEMBER_UPDATED", 42, 2)
    assert(a.addon.GuildCharacters()[1].race == nil, "invalid roster race does not discard the member or expose restricted data")
end
b.race = nil; a:Event("CLUB_MEMBER_UPDATED", 42, 2)
assert(a.addon.GuildCharacters()[1].race == nil, "optional race may be absent")
b.race = 5; a:Event("CLUB_MEMBER_UPDATED", 42, 2)
assert(a.addon.GuildCharacters()[1].race == 5 and #log == quiet, "roster changes update badges without new traffic")

-- Fixed thirty-second batch; multiple loots do not reset its deadline.
a.inventory[2770].count = 8; a.addon.Observe(); local changedAt = clock
Step(20); a.inventory[2770].count = 12; a.addon.Observe(); Step(9)
assert(#log == quiet and Received(b,a).snapshot.items[2770].count == 7)
Step(80)
assert(Received(b,a).snapshot.items[2770].count == 12 and clock - changedAt < 400)
quiet = #log
a.inventory[2770].count = 13; a.addon.Observe(); Step(10)
a.inventory[2770].count = 12; a.addon.Observe(); Step(300)
assert(#log == quiet, "a reverted change produces no publication")

-- A temporary return to the published quantity cannot restart an existing batch window.
a.inventory[2770].count = 14; a.addon.Observe(); changedAt = clock
Step(20); a.inventory[2770].count = 12; a.addon.Observe()
Step(9); a.inventory[2770].count = 15; a.addon.Observe(); Step(80)
assert(Received(b,a).snapshot.items[2770].count == 15 and clock-changedAt < 400)
a.inventory[2770].count = 12; a.addon.Observe(); Step(380)

-- Exclusions revoke quantities via atomic replacement; zero is a complete empty observation.
a.addon.SetItemHidden(2770, true); Step(380)
assert(next(Received(b,a).snapshot.items) == nil and a.addon.snapshot.items[2770].count == 12)
a.addon.SetItemHidden(2770, false); Step(380); assert(Received(b,a).snapshot.items[2770].count == 12)
a.inventory = {}; a.addon.Observe(); Step(380); assert(next(Received(b,a).snapshot.items) == nil)
a.inventory = {[2770] = {count = 3, bound = 0}}; a.incomplete = true; a.addon.Observe()
quiet = #log; Step(400); assert(#log == quiet and next(Received(b,a).snapshot.items) == nil)
a.incomplete = false; a.addon.Observe(); Step(380); assert(Received(b,a).snapshot.items[2770].count == 3)

-- Invalid, wrong-channel, unknown and self traffic cannot affect a complete record.
local before = Received(b,a)
for _, message in ipairs({"bad", "1|H|1-2|1", "2|S|1-2|1|0|1|0|0,0|2770,9,0", string.rep("x",241)}) do Receive(b,a,message) end
Receive(b,a,"2|H|1-2|999", "WHISPER")
Receive(b,{name="Unknown Example"},"2|H|1-2|999")
Receive(b,b,"2|H|1-2|999")
b.addon.ReceiveSync("GuildStockS2", secret, "GUILD", a.name)
assert(Received(b,a) == before)

-- Lost fragment repair retains the previous snapshot until all replacement parts arrive.
a.inventory = {}
local n = 0
for id in pairs(a.addon.catalogSeed) do n=n+1; a.inventory[id]={count=n,bound=0}; if n==60 then break end end
local held, lost = {}, false
filter = function(packet, client)
    if client == b and packet.sender == a.name and packet.message:match("^2|S|") then
        held[#held + 1] = packet.message
        local part = packet.message:match("^2|S|[^|]+|%d+|(%d+)|")
        if part == "2" and not lost then lost = true; return false end
    end
    return true
end
a.addon.Observe(); Step(38)
assert(lost and Received(b,a) == before, "a partial transfer must not erase the previous complete inventory")
Step(360); filter = nil
assert(Received(b,a) ~= before and Received(b,a).snapshot.items[next(a.inventory)])
local complete = Received(b,a)
for i=#held,1,-1 do Receive(b,a,held[i]) end
assert(Received(b,a) == complete, "duplicate/out-of-order completed revisions cannot add counts")

-- Reload gets a new session; old snapshots and old discovery cannot restore previous data.
local oldPackets = held
local oldSession = Received(b,a).session
a.disabled = true
a = Client("Alpha Example")
clients = {a,b} -- A new process with the same full regional identity.
a.inventory = {[2770]={count=42,bound=0}}; a:Login(); Step(240)
assert(Received(b,a).session ~= oldSession and Received(b,a).snapshot.items[2770].count == 42)
for _, message in ipairs(oldPackets) do Receive(b,a,message) end
Receive(b,a,"2|H|"..oldSession.."|999")
Step(40)
assert(Received(b,a).snapshot.items[2770].count == 42)

-- Actual lockdown blocks outgoing packets, with local inventory still usable.
a.lockdown = true; a.inventory[2770].count = 43; a.addon.Observe(); quiet = #log; Step(320)
for i=quiet+1,#log do assert(log[i].sender ~= a.name) end
assert(a.addon.snapshot.items[2770].count == 43 and a.addon.sync.status == "waiting")
a.lockdown = false; a.combat = true; quiet = #log; Step(20)
for i=quiet+1,#log do assert(log[i].sender ~= a.name) end
a.combat = false; Step(100); assert(Received(b,a).snapshot.items[2770].count == 43)

-- Temporary roster/guild unavailability hides, but does not delete, dated records.
b.rosterReady = false; local record = Received(b,a)
assert(#b.addon.GuildCharacters() == 0 and Received(b,a) == record)
b.rosterReady = true; b.missingGuild = true; assert(#b.addon.GuildCharacters() == 0)
b.missingGuild = false; assert(Received(b,a) == record)
a.online = false; b:Event("CLUB_MEMBER_PRESENCE_UPDATED",42,1,4)
assert(#b.addon.MaterialOwners(2770,false) == 0 and #b.addon.MaterialOwners(2770,true) == 1)
local whispered
b.env.ChatFrameUtil = {SendTell = function(name) whispered=name end}
b.addon.WhisperCharacter(a.name); assert(not whispered)
a.online=true; b:Event("CLUB_MEMBER_PRESENCE_UPDATED",42,1,1)
b.addon.WhisperCharacter(a.name); assert(whispered==a.name)
b:Event("CLUB_MEMBER_REMOVED",42,1); assert(not Received(b,a))
for _, message in ipairs(oldPackets) do Receive(b,a,message) end
assert(not Received(b,a), "confirmed removal rejects late traffic even against a stale roster")
b:Event("CLUB_MEMBER_ADDED",42,1)
b.guild=99; b:Event("PLAYER_GUILD_UPDATE","player"); assert(next(b.addon.guildData.characters)==nil)
Step(20); assert(not Received(b,a), "different guilds cannot exchange or display inventories")
-- Loading/world transitions cancel pending sessions but preserve dated same-guild observations.
b.guild=42; b:Event("PLAYER_GUILD_UPDATE","player"); Step(120)
local dated = Received(b,a)
assert(dated)
b:Event("PLAYER_LEAVING_WORLD")
quiet=#log; Step(20)
assert(Received(b,a)==dated)
for i=quiet+1,#log do assert(log[i].sender~=b.name) end
b:Event("PLAYER_ENTERING_WORLD"); Step(120)
assert(Received(b,a) and Received(b,a).snapshot.items[2770].count==43)

-- A fresh pair can reassemble a transfer in reverse order, without partial visibility.
clients,bus,log,clock = {},{},{},0
local c,d=Client("Gamma Example"),Client("Delta Example")
c.inventory={}; local num=0
for id in pairs(c.addon.catalogSeed) do num=num+1; c.inventory[id]={count=num,bound=0}; if num==20 then break end end
local reverse={}
filter=function(packet, receiver)
    if receiver==d and packet.sender==c.name and packet.message:match("^2|S|") then reverse[#reverse+1]=packet.message; return false end
    return true
end
c:Login();d:Login();Step(90)
assert(#reverse>=2 and not Received(d,c))
for i=#reverse,2,-1 do Receive(d,c,reverse[i]) end
-- Repeated resends may contain part 1: finish all packets and verify exact absolute counts.
for i=#reverse,1,-1 do Receive(d,c,reverse[i]) end
assert(Received(d,c))
for id,item in pairs(c.inventory) do assert(Received(d,c).snapshot.items[id].count==item.count) end
filter=nil

-- Initial readiness, unavailable flags, unknown saved schemas and failed registration fail closed.
clients,bus,log,clock = {},{},{},0
local e,f=Client("Epsilon Example"),Client("Zeta Example")
e.rosterReady=false; f.lockdown=true; e:Login();f:Login();Step(60);assert(#log==0)
e.rosterReady=true; e.lockdown=secret;Step(30);assert(#log==0)
e.lockdown=nil;Step(30);assert(#log==0)
e.lockdown=false;f.lockdown=false;e.restricted=secret;f.restricted=nil
Step(120);assert(Received(e,f) and Received(f,e))
clients,bus,log,clock = {},{},{},0
local g,h=Client("Eta Example"),Client("Theta Example")
g.registration=2;h.env.GuildStockDB={version=99,hiddenItems="preserve"}
g:Login();h:Login();Step(120);assert(#log==0 and h.env.GuildStockDB.version==99)
assert(h.env.GuildStockDB.hiddenItems=="preserve" and g.addon.snapshot)

-- API failure attempts are bounded; they never masquerade as remote receipts.
clients,bus,log,clock = {},{},{},0
local j,k=Client("Iota Example"),Client("Kappa Example")
j.result=3;k.lockdown=true;j:Login();k:Login();Step(180)
local attempts=0;for _,packet in ipairs(log) do if packet.sender==j.name then attempts=attempts+1 end end
assert(attempts==3 and j.addon.sync.result=="AddonMessageThrottle" and not Received(k,j))
quiet=#log;Step(300);assert(#log==quiet,"bounded failures do not become a periodic retry broadcast")

-- A native rejection is authoritative even if the preliminary lockdown flag is false.
clients,bus,log,clock = {},{},{},0
local rejected=Client("Rejected Example")
rejected.restricted=true;rejected.result=11;rejected:Login();Step(180)
assert(#log==3 and rejected.addon.sync.sent==0 and rejected.addon.sync.received==0)
assert(rejected.addon.sync.result=="AddOnMessageLockdown" and rejected.addon.sync.status=="failed")
assert(rejected.addon.SyncStatus()=="Guild synchronization interrupted")
quiet=#log;Step(300);assert(#log==quiet, "native denial must not create an endless retry loop")

-- No packet may contain an item excluded while a multipart snapshot is queued.
clients,bus,log,clock = {},{},{},0
local m,nclient=Client("Lambda Example"),Client("Mu Example")
m.inventory={};local ids={}
for id in pairs(m.addon.catalogSeed) do ids[#ids+1]=id;if #ids==40 then break end end
table.sort(ids);for _,id in ipairs(ids) do m.inventory[id]={count=1,bound=0} end
m:Login();nclient:Login()
local hidden=false
for _=1,120 do
    Step(0.5)
    if not hidden then
        for _,packet in ipairs(log) do
            if packet.sender==m.name and packet.message:match("^2|S|") then
                m.addon.SetItemHidden(ids[#ids],true);quiet=#log;hidden=true;break
            end
        end
    end
end
assert(hidden)
Step(380)
for i=quiet+1,#log do
    assert(not (log[i].sender==m.name and log[i].message:find(tostring(ids[#ids])..",1,0",1,true)))
end
assert(Received(nclient,m) and not Received(nclient,m).snapshot.items[ids[#ids]])
-- A maximum-size transfer must finish even when requests arrive while it is streaming.
clients,bus,log,clock = {},{},{},0
local large,small=Client("Large Example"),Client("Small Example")
large.inventory={};large.addon.Initialize();large.addon.db.catalog={}
for id=100000,101399 do
    large.inventory[id]={count=id,bound=0};large.addon.db.catalog[id]={Mining=true}
end
large:Login();small:Login();Step(280)
assert(Received(small,large))
local total=0;for id,item in pairs(Received(small,large).snapshot.items) do total=total+1;assert(item.count==id) end
assert(total==1400,"all maximum-size snapshot fragments arrive atomically")

-- Several simultaneous logins share coalesced broadcasts; idle clients stay quiet.
clients,bus,log,clock = {},{},{},0
local group={}
for i=1,4 do group[i]=Client("Guildmate Example "..i) end
for _,client in ipairs(group) do client:Login() end
Step(180)
for _,client in ipairs(group) do assert(#client.addon.GuildCharacters()==3) end
local previousSend={}
for _,packet in ipairs(log) do
    assert(not previousSend[packet.sender] or packet.at-previousSend[packet.sender]>=0.5)
    previousSend[packet.sender]=packet.at
end
assert(#log<100,"simultaneous login replies are bounded and full snapshots are coalesced")
quiet=#log;Step(600);assert(#log==quiet)
group[1].unreadable=4;group[1]:Event("CLUB_MEMBERS_UPDATED",42)
assert(#group[1].addon.GuildCharacters()==2 and Received(group[1],group[4]),
    "one unavailable member is hidden and retained without blocking other verified members")
-- A new client can arrive inside an existing participant's offer cooldown.
clients,bus,log,clock = {},{},{},0
local early=Client("Early Example")
early:Login();Step(90)
early.addon.SyncDiscover();Step(1)
local late=Client("Late Example")
late:Login();Step(180)
assert(Received(early,late) and Received(late,early), "a cooldown must defer, not discard, discovery replies")
quiet=#log;Step(600);assert(#log==quiet,"deferred discovery must settle without a heartbeat")

-- A slow native roster can miss every initial announcement from the other client.
clients,bus,log,clock = {},{},{},0
local fast=Client("Fast Example")
local slow=Client("Slow Example")
slow.rosterReady=false
fast:Login();slow:Login();Step(15)
slow.rosterReady=true;Step(180)
assert(Received(fast,slow) and Received(slow,fast), "late roster readiness must recover both directions")
quiet=#log;Step(600);assert(#log==quiet)

-- Members-ready can precede a peer's presence/name data. Fast startup must not
-- exhaust every announcement before that peer can be verified.
for _, scenario in ipairs({{delay=5}, {delay=20}, {delay=40}, {delay=20, missingName=true}}) do
    local delay=scenario.delay
    clients,bus,log,clock,filter = {},{},{},0,nil
    math.randomseed(1)
    local first,second=Client("Delayed First Example"),Client("Delayed Second Example")
    for _,client in ipairs(clients) do
        local native=client.env.C_Club.GetMemberInfo
        client.env.C_Club.GetMemberInfo=function(...)
            local info=native(...)
            if not info.isSelf and clock<delay then
                if scenario.missingName then info.name=nil else info.presence=4 end
            end
            return info
        end
        client:Login()
    end
    Step(delay)
    for _,client in ipairs(clients) do client:Event("CLUB_MEMBER_PRESENCE_UPDATED",42,1,1) end
    Step(70-delay)
    assert(Received(first,second) and Received(second,first),
        "startup discovery must recover when native peer presence arrives late")
    quiet=#log;Step(600);assert(#log==quiet,"startup discovery retries must finish, not become a heartbeat")
end

-- Native send Success does not ensure delivery; lose all early peer traffic.
do
    clients,bus,log,clock,filter = {},{},{},0,nil
    local first,second=Client("Lost Hello First Example"),Client("Lost Hello Second Example")
    filter=function(packet,client) return packet.sender==client.name or clock>=20 end
    first:Login();second:Login();Step(70)
    assert(Received(first,second) and Received(second,first),"lost initial announcements must recover without manual discovery")
    quiet=#log;Step(600);assert(#log==quiet)
    filter=nil
end

-- An unanswered startup has a fixed announcement budget even with native Success.
do
    clients,bus,log,clock,filter = {},{},{},0,nil
    local alone=Client("Alone Example")
    alone:Login();Step(90)
    local hellos=0
    for _,packet in ipairs(log) do if packet.message:match("^2|H|") then hellos=hellos+1 end end
    assert(hellos==3,"startup must send one initial hello and only two delayed retries")
    quiet=#log;Step(600);assert(#log==quiet)
end

-- Delayed discovery still pauses during combat, and native denials cancel it.
do
    clients,bus,log,clock,filter = {},{},{},0,nil
    local alone=Client("Paused Discovery Example")
    alone:Login();Step(10)
    alone.combat=true;quiet=#log;Step(50);assert(#log==quiet)
    alone.combat=false;alone.lockdown=true;Step(20);assert(#log==quiet)
    alone.lockdown=false;alone.result=11;Step(100)
    assert(#log==quiet+3 and alone.addon.sync.status=="failed",
        "native rejection cancels startup discovery after the existing failure budget")
    quiet=#log;Step(600);assert(#log==quiet)
end

-- Complete peer history survives a fresh Lua environment without trusting old sessions.
clients,bus,log,clock = {},{},{},0
local historian,source=Client("History Example"),Client("Source Example")
historian:Login();source:Login();Step(90)
local history=historian.env.GuildStockDB.guildHistory
local original=Copy(history)
assert(history.version==2 and history.guildID==42)
assert(history.characters[source.name].receivedAt==Received(historian,source).receivedAt)
assert(not history.characters[source.name].session and history.characters[source.name].revision)
local accepted=Received(historian,source)
Receive(historian,source,"2|O|"..accepted.session.."|"..(accepted.revision+1))
Receive(historian,source,"2|S|"..accepted.session.."|"..(accepted.revision+1).."|1|2|"..historian.env.time().."|0,0|2589,99,0")
assert(history.characters[source.name].receivedAt==original.characters[source.name].receivedAt
    and not history.characters[source.name].snapshot.items[2589], "partial transfers cannot replace saved history or its age")
local function Reload(client, saved)
    local index
    for i,value in ipairs(clients) do if value==client then index=i end end
    local replacement=Client(client.name)
    clients[#clients]=nil;clients[index]=replacement
    replacement.env.GuildStockDB=Copy(saved or client.env.GuildStockDB)
    replacement.guild, replacement.memberID=client.guild, client.memberID
    replacement:Login();replacement.addon.SyncTick()
    return replacement
end
source.online=false
historian=Reload(historian)
assert(Received(historian,source) and historian.addon.sync.received==0)
assert(#historian.addon.GuildCharacters()==1 and #historian.addon.MaterialOwners(2770,true)==1)
assert(#historian.addon.MaterialOwners(2770,false)==0, "history cannot invent online presence")
assert(not Received(historian,source).session)
local receipt=Received(historian,source).receivedAt
Step(90);assert(Received(historian,source).receivedAt==receipt, "idle history never becomes fresh by itself")
historian.rosterReady=false;historian:Event("CLUB_MEMBERS_UPDATED",42)
assert(#historian.addon.GuildCharacters()==0 and Received(historian,source))
historian=Reload(historian)
assert(Received(historian,source).receivedAt==receipt, "temporary roster gaps preserve saved history")
source.online=true;historian:Event("CLUB_MEMBERS_UPDATED",42);Step(180)
assert(historian.addon.sync.received>0 and Received(historian,source).session)
assert(Received(historian,source).receivedAt>receipt, "unchanged remote sessions are revalidated after reload")
source.inventory={};source.addon.Observe();Step(380)
historian=Reload(historian)
assert(next(Received(historian,source).snapshot.items)==nil, "empty replacement also persists")
historian:Event("CLUB_MEMBER_REMOVED",42,2)
assert(not historian.env.GuildStockDB.guildHistory.characters[source.name])
source.online=false;historian=Reload(historian)
assert(not Received(historian,source), "confirmed departures cannot reappear from disk")
local saved=Copy(historian.env.GuildStockDB);saved.guildHistory=original
historian.guild=43;historian=Reload(historian,saved)
assert(next(historian.addon.guildData.characters)==nil and historian.env.GuildStockDB.guildHistory.guildID==43)
historian.env.IsInGuild=function() return false end -- Club ID can still be stale during departure.
historian:Event("PLAYER_GUILD_UPDATE")
assert(not historian.addon.guildData and not historian.env.GuildStockDB.guildHistory)
-- Future schemas and malformed records remain on disk, without being displayed or trusted.
historian.guild=42
saved.guildHistory=Copy(original);saved.guildHistory.version=99
historian=Reload(historian,saved)
assert(next(historian.addon.guildData.characters)==nil and historian.env.GuildStockDB.guildHistory.version==99)
source.online=true;Step(180)
assert(historian.env.GuildStockDB.guildHistory.version==99)
saved.guildHistory=Copy(original);saved.guildHistory.characters[source.name].snapshot.items[2770].count=-1
historian=Reload(historian,saved)
assert(not Received(historian,source) and historian.env.GuildStockDB.guildHistory.characters[source.name].snapshot.items[2770].count==-1)
saved.guildHistory=Copy(original);saved.guildHistory.characters[source.name].receivedAt=epoch-864000
saved.guildHistory.characters[source.name].snapshot.observedAt=epoch-864000
historian=Reload(historian,saved)
assert(Received(historian,source), "dated local history can outlive network packet timestamp bounds")
historian.addon.guildData.characters[source.name].memberID=99
assert(#historian.addon.GuildCharacters()==0, "saved names cannot impersonate a different current member")
historian=Reload(historian,{version=99,guildHistory=original})
assert(historian.addon.temporary and historian.env.GuildStockDB.version==99)
assert(not historian.env.GuildStockDB.guildHistory.characters[source.name].session)

-- The global opt-out withdraws existing stock promptly and still receives guild inventories.
clients,bus,log,clock = {},{},{},0
local private,reader=Client("Private Example"),Client("Reader Example")
private.inventory[2589]={count=4,bound=0}
private.addon.Initialize();private.addon.SetItemHidden(2589,true)
private:Login();reader:Login();Step(90)
assert(Received(reader,private).snapshot.items[2770] and not Received(reader,private).snapshot.items[2589])
private.incomplete=true;private.addon.Observe()
private.addon.SetSharingEnabled(false);quiet=#log;Step(60)
assert(next(Received(reader,private).snapshot.items)==nil, "opt-out bypasses the thirty-second batch even with incomplete bags")
assert(next(reader.env.GuildStockDB.guildHistory.characters[private.name].snapshot.items)==nil)
local function AssertNoItemsSince(client, first)
    local snapshots=0
    for i=first+1,#log do
        local packet=log[i]
        if packet.sender==client.name and packet.message:match("^2|S|") then
            assert(packet.message:match("|$"), "disabled sharing must send no item IDs or quantities")
            snapshots=snapshots+1
        end
    end
    return snapshots
end
assert(AssertNoItemsSince(private,quiet)>0)
reader.inventory[2770].count=19;reader.addon.Observe();Step(380)
assert(Received(private,reader).snapshot.items[2770].count==19, "receiving remains active while sharing is off")
AssertNoItemsSince(private,quiet)
private=Reload(private);Step(90)
assert(not private.addon.IsSharingEnabled() and private.addon.IsItemHidden(2589))
assert(next(Received(reader,private).snapshot.items)==nil, "reload restores global opt-out before discovery")
private.inventory={[2770]={count=23,bound=2},[2589]={count=8,bound=0}}
private.addon.Observe();local idle=#log;Step(600);assert(#log==idle, "private bag changes never publish counts")
private.addon.SetSharingEnabled(true);Step(380)
assert(Received(reader,private).snapshot.items[2770].count==23 and not Received(reader,private).snapshot.items[2589],
    "reenabling shares current stock with the original per-item exclusions")

-- Stop a multipart transfer immediately; no remaining fragment may contain stock.
clients,bus,log,clock = {},{},{},0
private,reader=Client("Private Transfer Example"),Client("Transfer Reader Example")
private.inventory={}
local quantity=0
for id in pairs(private.addon.catalogSeed) do
    quantity=quantity+1;private.inventory[id]={count=quantity,bound=0};if quantity==40 then break end
end
private:Login();reader:Login()
local stopped
for _=1,120 do
    Step(0.5)
    if not stopped then
        for _,packet in ipairs(log) do
            if packet.sender==private.name and packet.message:match("^2|S|") then
                private.addon.SetSharingEnabled(false);quiet=#log;stopped=true;break
            end
        end
    end
end
assert(stopped);Step(90)
assert(AssertNoItemsSince(private,quiet)>0 and next(Received(reader,private).snapshot.items)==nil)

-- A saved opt-out can discover peers before the first successful bag read.
clients,bus,log,clock = {},{},{},0
private,reader=Client("Private Login Example"),Client("Login Reader Example")
private.env.GuildStockDB={version=1,settings={shareInventory=false},hiddenItems={[2589]=true}}
private.incomplete=true;private:Login();reader:Login();Step(90)
assert(not private.addon.snapshot and Received(private,reader) and next(Received(reader,private).snapshot.items)==nil)
assert(AssertNoItemsSince(private,0)>0)
private.addon.SetSharingEnabled(true);quiet=#log;Step(380)
for i=quiet+1,#log do assert(log[i].sender~=private.name, "reenabling must wait for a complete bag read") end
private.incomplete=false;private.addon.Observe();Step(380)
assert(Received(reader,private).snapshot.items[2770].count==7)
private.combat=true;private.addon.SetSharingEnabled(false);quiet=#log;Step(60)
for i=quiet+1,#log do assert(log[i].sender~=private.name, "privacy withdrawal respects combat lockdown") end
private.combat=false;private.lockdown=true;Step(60)
for i=quiet+1,#log do assert(log[i].sender~=private.name, "privacy withdrawal respects messaging lockdown") end
private.lockdown=false;Step(90)
assert(AssertNoItemsSince(private,quiet)>0 and next(Received(reader,private).snapshot.items)==nil)

-- The saved material registry supplies bank-only stock; storage moves do not add units.
clients,bus,log,clock = {},{},{},0
filter = nil
do
    local owner, reader = Client("Bank Owner Example"), Client("Bank Reader Example")
    owner.inventory, owner.bank = {[2840] = {count = 2, bound = 0}}, {[2840] = 1, [2589] = 20}
    owner.env.GuildStockDB = {version = 1, knownMaterials = {[2589] = true}}
    owner:Login(); reader:Login(); Step(90)
    local stock = Received(reader,owner).snapshot.items
    assert(stock[2840].count == 3 and stock[2589].count == 20)
    local before = #log
    owner.inventory[2840].count, owner.bank[2840] = 1, 2
    owner:Event("BAG_UPDATE_DELAYED"); owner:Event("ITEM_COUNT_CHANGED", 2840); Step(380)
    assert(#log == before, "moving unbound units between bags and bank does not republish the same total")
    owner.bank[2589] = 0; owner:Event("ITEM_COUNT_CHANGED", 2589); Step(380)
    assert(not Received(reader,owner).snapshot.items[2589] and owner.addon.knownMaterials[2589])
    owner.addon.SetItemHidden(2840, true); Step(380)
    assert(next(Received(reader,owner).snapshot.items) == nil and owner.addon.snapshot.items[2840].count == 3)
    owner.addon.SetItemHidden(2840, false); Step(380)
    assert(Received(reader,owner).snapshot.items[2840].count == 3)
    owner.addon.SetSharingEnabled(false); Step(90)
    assert(next(Received(reader,owner).snapshot.items) == nil)
end

-- Newcomers bypass the ordinary batch, including an existing participant's roster cache.
do
    clients,bus,log,clock,filter = {},{},{},0,nil
    math.randomseed(17)
    local owner=Client("Quick Owner Example");owner:Login();Step(90)
    owner.inventory[2770].count=18;owner.addon.Observe()
    local reader=Client("Quick Reader Example");reader:Login()
    local joined=clock
    while not Received(reader,owner) and clock-joined<20 do Step(0.5) end
    assert(Received(reader,owner) and Received(reader,owner).snapshot.items[2770].count==18,
        "joining during a pending change must receive the current inventory within 20 seconds")
    assert(clock-joined<30)
end

-- Ordinary gameplay cannot starve a frozen multipart snapshot, even beyond the batch deadline.
do
    clients,bus,log,clock,filter = {},{},{},0,nil
    local owner,reader=Client("Busy Owner Example"),Client("Busy Reader Example")
    owner.inventory={};owner.addon.Initialize();owner.addon.db.catalog={}
    for id=100000,101399 do owner.inventory[id]={count=2147483647,bound=2147483647};owner.addon.db.catalog[id]={Mining=true} end
    owner:Login();reader:Login()
    local started
    for _=1,520 do
        Step(0.5)
        for _,packet in ipairs(log) do if packet.sender==owner.name and packet.message:match("^2|S|") then started=true;break end end
        if started then owner.inventory[100000].count=100;owner.inventory[100000].bound=0;owner.addon.Observe() end
        if Received(reader,owner) then break end
    end
    assert(Received(reader,owner) and Received(reader,owner).snapshot.items[100000].count==2147483647,
        "a complete frozen revision must arrive while ordinary quantities change")
    Step(260)
    assert(Received(reader,owner).snapshot.items[100000].count==100)
    for _,packet in ipairs(log) do assert(#packet.message<=240) end
end

-- A returning reader keeps its own dated direct history until the owner returns.
do
    clients,bus,log,clock,filter = {},{},{},0,nil
    local reader,owner,holder=Client("Returning Example"),Client("Offline Owner Example"),Client("Holder Example")
    reader:Login();owner:Login();holder:Login();Step(60)
    local old=Copy(reader.env.GuildStockDB)
    local original=Copy(Received(reader,owner))
    reader.online=false
    owner.inventory[2770].count=40;owner.addon.Observe();Step(60)
    assert(Received(holder,owner).snapshot.items[2770].count==40)
    owner.online=false
    reader=Reload(reader,old);Step(90)
    local retained=Received(reader,owner)
    assert(retained.snapshot.items[2770].count==7 and retained.revision==original.revision)
    assert(retained.snapshot.observedAt==original.snapshot.observedAt and retained.receivedAt==original.receivedAt,
        "another participant cannot refresh the reader's offline history")
    assert(reader.addon.SyncMember(owner.name).offline)
    for _,entry in ipairs(reader.addon.MaterialOwners(2770,false)) do assert(entry.id~=owner.name) end
    holder=Reload(holder);reader=Reload(reader);Step(90)
    local newcomer=Client("Later Example");newcomer:Login();Step(90)
    assert(not Received(newcomer,owner),"a new participant must wait for the owner, even when others have its history")
    assert(Received(reader,owner).snapshot.items[2770].count==7)
    owner.online=true;owner:Event("PLAYER_ENTERING_WORLD")
    for _,client in ipairs({reader,holder,newcomer}) do client:Event("CLUB_MEMBERS_UPDATED",42) end
    Step(90)
    assert(Received(reader,owner).snapshot.items[2770].count==40 and Received(newcomer,owner).snapshot.items[2770].count==40)
    assert(Received(reader,owner).session and Received(reader,owner).receivedAt>original.receivedAt)
end

-- A missed privacy withdrawal also waits for direct contact; peers never relay it.
do
    clients,bus,log,clock,filter = {},{},{},0,nil
    local reader,owner,holder=Client("Private Returning Example"),Client("Private Owner Example"),Client("Private Holder Example")
    reader:Login();owner:Login();holder:Login();Step(60)
    local old=Copy(reader.env.GuildStockDB);reader.online=false
    owner.incomplete=true;owner.addon.Observe();owner.addon.SetSharingEnabled(false);Step(15)
    assert(next(Received(holder,owner).snapshot.items)==nil)
    owner.online=false;reader=Reload(reader,old);Step(90)
    assert(Received(reader,owner).snapshot.items[2770].count==7,"missed withdrawals cannot remotely erase old direct history")
    owner.online=true;owner:Event("PLAYER_ENTERING_WORLD");reader:Event("CLUB_MEMBERS_UPDATED",42);Step(90)
    assert(next(Received(reader,owner).snapshot.items)==nil,"the owner's empty replacement still withdraws stock")
end

-- Retired packets cannot poison a direct record, trigger replies or create an offline owner.
do
    clients,bus,log,clock,filter = {},{},{},0,nil
    local reader,owner,sender=Client("Safe Reader Example"),Client("Safe Owner Example"),Client("Untrusted Sender Example")
    reader:Login();owner:Login();sender:Login();Step(120)
    local accepted=Received(reader,owner)
    local readerSession=Received(sender,reader).session
    owner.online=false;reader:Event("CLUB_MEMBERS_UPDATED",42)
    local first,received=#log,reader.addon.sync.received
    Receive(reader,sender,"2|D|1-2|n2,999999999999")
    Step(3)
    Receive(reader,sender,"2|T|1-2|n2|999999999999|1|1|"..reader.env.time().."|0,0|2770,999,0")
    Receive(reader,sender,"2|R|"..readerSession.."|n2|"..accepted.revision)
    Step(120)
    assert(Received(reader,owner)==accepted and reader.addon.sync.received==received and #log==first)
    local newcomer=Client("Safe Newcomer Example");newcomer:Login();Step(120)
    Receive(newcomer,sender,"2|D|1-2|n2,999999999999");Step(3)
    Receive(newcomer,sender,"2|T|1-2|n2|999999999999|1|1|"..newcomer.env.time().."|0,0|2770,999,0")
    Step(30);assert(not Received(newcomer,owner))
    owner.online=true;owner.inventory[2770].count=11;owner:Event("PLAYER_ENTERING_WORLD")
    reader:Event("CLUB_MEMBERS_UPDATED",42);newcomer:Event("CLUB_MEMBERS_UPDATED",42);Step(90)
    assert(Received(reader,owner).snapshot.items[2770].count==11 and Received(newcomer,owner).snapshot.items[2770].count==11)
end

-- Upgrades remove only marked relay history, including revisions that previously blocked owners.
for _,version in ipairs({1,2}) do
    clients,bus,log,clock,filter = {},{},{},0,nil
    local reader,owner,direct=Client("Upgrade Reader Example"),Client("Upgrade Owner Example"),Client("Direct History Example")
    reader:Login();owner:Login();direct:Login();Step(90)
    local saved=Copy(reader.env.GuildStockDB)
    saved.settings={shareInventory=false,language="enUS"};saved.hiddenItems={[2589]=true};saved.favorites={[2770]=true}
    saved.guildHistory.version=version
    local poisoned=saved.guildHistory.characters[owner.name]
    poisoned.relayed=true;poisoned.revision=999999999999;poisoned.supersededBy=999999999999
    poisoned.snapshot.items[2770].count=999
    -- Retired direct-only metadata may coexist with a valid record and must not erase it.
    saved.guildHistory.characters[direct.name].supersededBy=999999999999
    local retained=Copy(saved.guildHistory.characters[direct.name])
    owner.online=false;direct.online=false
    reader=Reload(reader,saved)
    assert(not Received(reader,owner) and not reader.env.GuildStockDB.guildHistory.characters[owner.name])
    assert(Received(reader,direct).snapshot.items[2770].count==retained.snapshot.items[2770].count)
    assert(Received(reader,direct).snapshot.observedAt==retained.snapshot.observedAt
        and Received(reader,direct).receivedAt==retained.receivedAt and Received(reader,direct).professionRanks[1]==52)
    assert(reader.env.GuildStockDB.settings.shareInventory==false and reader.env.GuildStockDB.settings.language=="enUS")
    assert(reader.env.GuildStockDB.hiddenItems[2589] and reader.env.GuildStockDB.favorites[2770]
        and reader.env.GuildStockDB.own.items[2770].count==saved.own.items[2770].count)
    Step(90);reader=Reload(reader);Step(90)
    assert(not Received(reader,owner) and Received(reader,direct),"removed relays stay absent after another reload")
    owner.online=true;owner.inventory[2770].count=11;owner:Event("PLAYER_ENTERING_WORLD")
    reader:Event("CLUB_MEMBERS_UPDATED",42);Step(90)
    assert(Received(reader,owner).snapshot.items[2770].count==11 and Received(reader,owner).revision<999999999999,
        "the owner's ordinary direct revision recovers from poisoned saved history")
    assert(not reader.env.GuildStockDB.guildHistory.characters[owner.name].relayed)
    saved.guildHistory.version=99
    reader=Reload(reader,saved)
    assert(reader.env.GuildStockDB.guildHistory.characters[owner.name].relayed
        and reader.env.GuildStockDB.guildHistory.characters[owner.name].revision==999999999999
        and not Received(reader,owner),"unsupported schemas remain untouched and are not displayed")
    saved.guildHistory.version=2;saved.version=99
    reader=Reload(reader,saved)
    assert(reader.addon.temporary and reader.env.GuildStockDB.guildHistory.characters[owner.name].relayed,
        "an unsupported root schema must not be migrated")
end

-- Old direct history remains readable without invented revisions; future schemas survive untouched.
do
    clients,bus,log,clock,filter = {},{},{},0,nil
    local owner,holder=Client("Legacy Owner Example"),Client("Legacy Holder Example")
    owner:Login();holder:Login();Step(60);owner.online=false
    local saved=Copy(holder.env.GuildStockDB);saved.guildHistory.version=1
    saved.guildHistory.characters[owner.name].revision=nil
    holder=Reload(holder,saved)
    assert(Received(holder,owner) and not Received(holder,owner).revision and holder.env.GuildStockDB.guildHistory.version==2)
    local reader=Client("Legacy Reader Example");reader:Login();Step(60)
    assert(not Received(reader,owner),"v1 history is display-only until refreshed directly")
    local before=holder.env.GuildStockDB.syncClock.revision
    holder=Reload(holder);Step(20)
    assert(holder.env.GuildStockDB.syncClock.revision>before,"owner revisions advance across reload")
    saved=Copy(holder.env.GuildStockDB);saved.syncClock={version=99,revision=12,preserve=true}
    holder=Reload(holder,saved);local first=#log;Step(60)
    assert(holder.env.GuildStockDB.syncClock.version==99 and holder.env.GuildStockDB.syncClock.preserve)
    for i=first+1,#log do assert(log[i].sender~=holder.name,"unsupported publication clocks fail closed") end
end

-- Forty simultaneous logins must drain their control queues without losing challenges.
do
    clients,bus,log,clock,filter = {},{},{},0,nil
    math.randomseed(17)
    local group={}
    for i=1,40 do group[i]=Client("Crowded Guild Example "..i);group[i]:Login() end
    Step(180)
    for _,client in ipairs(group) do assert(#client.addon.GuildCharacters()==39,"every simultaneous participant eventually receives every other inventory") end
    assert(#log<12800,"retry and control traffic remain bounded during simultaneous joins")
    local quiet=#log;Step(90);assert(#log==quiet)
end

-- Per-item privacy changes can withdraw data using the last complete observation.
do
    clients,bus,log,clock,filter = {},{},{},0,nil
    local owner,reader=Client("Excluded Owner Example"),Client("Excluded Reader Example")
    owner.inventory[2589]={count=3,bound=0};owner:Login();reader:Login();Step(60)
    owner.incomplete=true;owner.addon.Observe();owner.addon.SetItemHidden(2770,true);Step(15)
    local record=Received(reader,owner)
    assert(not record.snapshot.items[2770] and record.snapshot.items[2589].count==3,
        "an exclusion is not held behind incomplete inventory reads or the normal batch")
end

-- Direct history retains opaque member IDs without encoding or truncating them.
for _,nativeID in ipairs({9007199254740991,"member|opaque,with%;punctuation",string.rep("x",150)}) do
    clients,bus,log,clock,filter = {},{},{},0,nil
    local owner,reader=Client("Opaque Owner Example"),Client("Opaque Reader Example")
    owner.memberID=nativeID;owner:Login();reader:Login();Step(60);owner.online=false
    assert(Received(reader,owner).memberID==nativeID)
    reader=Reload(reader);Step(60)
    assert(Received(reader,owner).memberID==nativeID,"local history preserves the exact native member ID")
end

-- A verified replacement native member ID cannot inherit the old member's transport/version.
do
    clients,bus,log,clock,filter = {},{},{},0,nil
    local owner,reader=Client("Rejoined Owner Example"),Client("Rejoined Reader Example")
    owner:Login();reader:Login();Step(60)
    owner.memberID="new-membership"
    owner.inventory[2770].count=14;owner:Event("PLAYER_ENTERING_WORLD")
    reader:Event("CLUB_MEMBERS_UPDATED",42);Step(30)
    assert(Received(reader,owner).memberID=="new-membership" and Received(reader,owner).snapshot.items[2770].count==14)
end

-- Idle transport must not rebuild/export unchanged inventories on its half-second timer.
do
    clients,bus,log,clock,filter = {},{},{},0,nil
    local owner,reader=Client("Idle Owner Example"),Client("Idle Reader Example")
    owner:Login();reader:Login();Step(90)
    local exports,skills=0,0
    local shareable,getProfessions=owner.addon.ShareableSnapshot,owner.env.GetProfessions
    owner.addon.ShareableSnapshot=function(...) exports=exports+1;return shareable(...) end
    owner.env.GetProfessions=function(...) skills=skills+1;return getProfessions(...) end
    local quiet=#log;Step(300)
    assert(exports==0 and skills==0,"idle ticks must reuse the prepared inventory without copying or reading professions")
    assert(#log==quiet,"idle transport stays silent")
    owner.inventory[2770].count=19;owner.addon.Observe();Step(20)
    assert(Received(reader,owner).snapshot.items[2770].count==7,"changes still wait for the normal batch")
    Step(25)
    assert(Received(reader,owner).snapshot.items[2770].count==19,"a changed observation replaces the prepared inventory")
    exports,skills=0,0;Step(60);assert(exports==0 and skills==0)
    owner.env.GetProfessions=function() return 2 end
    owner:Event("SKILL_LINES_CHANGED");Step(45)
    assert(Received(reader,owner).skills[1]=="Mining" and Received(reader,owner).skills[2]==nil,
        "profession events invalidate the prepared inventory")
    owner.inventory[99900]={count=5,bound=0};owner.addon.Observe();Step(45)
    assert(not Received(reader,owner).snapshot.items[99900])
    owner.env.C_TradeSkillUI.GetAllRecipeIDs=function() return {1} end
    owner.env.C_TradeSkillUI.GetProfessionInfoByRecipeID=function() return {profession=2} end
    owner.env.C_TradeSkillUI.GetRecipeSchematic=function()
        return {reagentSlotSchematics={{reagents={{itemID=99900}}}}}
    end
    owner:Event("TRADE_SKILL_LIST_UPDATE");Step(45)
    assert(Received(reader,owner).snapshot.items[99900].count==5,
        "recipe discovery invalidates prepared material selection without a bag quantity change")
    owner.addon.db.hiddenItems="unsupported"
    quiet=#log;owner.addon.SyncDiscover();Step(10)
    for i=quiet+1,#log do assert(log[i].sender~=owner.name,"cached inventories cannot bypass unsupported privacy data") end
    owner.addon.db.hiddenItems=nil
    owner.addon.SetItemHidden(2770,true);Step(15)
    assert(not Received(reader,owner).snapshot.items[2770],"exclusions still withdraw cached stock promptly")
    owner:Event("SHARD_TRANSFER");Step(60)
    assert(Received(reader,owner).snapshot.items[99900].count==5 and not Received(reader,owner).snapshot.items[2770],
        "world transitions rebuild the current privacy-filtered inventory")
end

-- Optional levels belong to the remote owner, independent of unreliable roster ranks.
do
    clients,bus,log,clock,filter = {},{},{},0,nil
    local owner,reader=Client("Profession Owner Example"),Client("Profession Reader Example")
    owner.ranks,reader.ranks={175,0},{52,1}
    owner.profession1ID,owner.profession1Rank,owner.profession2ID,owner.profession2Rank=2,1,1,1
    owner:Login();reader:Login();Step(90)
    local function Ranks() return Received(reader,owner).professionRanks end
    assert(Ranks()[1]==175 and Ranks()[2]==0, "remote levels must not come from the local player or roster slot order")
    assert(reader.addon.GuildCharacters()[1].professionRanks[1]==175)
    assert(Received(owner,reader).professionRanks[1]==52)
    local quiet=#log;Step(300);assert(#log==quiet,"levels do not add idle polling or heartbeats")
    owner.ranks={180,1};owner:Event("SKILL_LINES_CHANGED");Step(29)
    assert(Ranks()[1]==175,"profession-only updates retain the thirty-second batch")
    Step(70);assert(Ranks()[1]==180 and Ranks()[2]==1)
    local record=Received(reader,owner)
    local head="2|P|"..record.session.."|"..record.revision.."|1,10|"
    for _,payload in ipairs({"-1,1","1.5,1","10001,1","bad","1,1,1","?,"}) do Receive(reader,owner,head..payload) end
    Receive(reader,owner,head.."9,9","WHISPER")
    Receive(reader,owner,"2|P|1-2|"..record.revision.."|1,10|9,9")
    Receive(reader,owner,"2|P|"..record.session.."|"..(record.revision-1).."|1,10|9,9")
    assert(Ranks()[1]==180 and record.snapshot.items[2770].count==7,"bad, stale and unauthorized metadata cannot change the inventory or levels")
    Receive(reader,owner,"2|P|"..record.session.."|"..record.revision.."|10,1|9,9")
    assert(Ranks()[1]==180,"metadata for different professions cannot attach by slot alone")
    local stale=head.."9,9"
    owner=Reload(owner);owner.ranks={180,1};owner:Event("SKILL_LINES_CHANGED");Step(90)
    Receive(reader,owner,stale)
    assert(Ranks()[1]==180,"old-session metadata cannot replace the owner's new session")
    owner.ranks={secret,300};owner:Event("SKILL_LINES_CHANGED");Step(90)
    assert(Ranks()[1]==nil and Ranks()[2]==300,"inaccessible ranks clear only their slot")
    owner.online=false;reader=Reload(reader);Step(60)
    assert(Ranks()[1]==nil and Ranks()[2]==300,"last received ranks survive reload for an offline member")
    local saved=Copy(reader.env.GuildStockDB)
    saved.guildHistory.characters[owner.name].professionRanks={"bad",-1}
    reader=Reload(reader,saved);Step(10)
    assert(Received(reader,owner).snapshot.items[2770].count==7 and not Ranks()[1] and not Ranks()[2],
        "invalid optional saved levels cannot discard a valid inventory")
end

-- Lost levels never block inventory completion; normal existing offers can repair them.
do
    clients,bus,log,clock,filter = {},{},{},0,nil
    local owner,reader=Client("Loss Owner Example"),Client("Loss Reader Example")
    local dropped=0
    filter=function(packet,client)
        if packet.sender==owner.name and client==reader and packet.message:match("^2|P|") and dropped<2 then
            dropped=dropped+1;return false
        end
        return true
    end
    owner:Login();reader:Login();Step(120)
    assert(dropped==2 and Received(reader,owner).professionRanks[1]==52)
    filter=function(packet,client) return not (client==reader and packet.message:match("^2|P|")) end
    owner.ranks={200,200};owner.inventory[2770].count=8;owner.addon.Observe();Step(90)
    assert(Received(reader,owner).snapshot.items[2770].count==8 and not Received(reader,owner).professionRanks,
        "missing optional levels never hold up the new inventory or reuse stale ranks")
end

-- Metadata received before S/A waits for that exact authenticated snapshot.
do
    clients,bus,log,clock,filter = {},{},{},0,nil
    local owner,reader=Client("Order Owner Example"),Client("Order Reader Example")
    local held,metadata={},nil
    filter=function(packet,client)
        if packet.sender==owner.name and client==reader then
            if packet.message:match("^2|S|") or packet.message:match("^2|A|") then held[#held+1]=packet.message;return false end
            if packet.message:match("^2|P|") then metadata=packet.message end
        end
        return true
    end
    owner:Login();reader:Login();Step(10)
    assert(metadata and not Received(reader,owner),"metadata alone cannot create a character inventory")
    for _,message in ipairs(held) do Receive(reader,owner,message) end
    assert(Received(reader,owner).professionRanks[1]==52)
    filter=nil
end

-- Unlearning or replacing a profession must not reuse the previous profession's level.
do
    clients,bus,log,clock,filter = {},{},{},0,nil
    local owner,reader=Client("Skills Owner Example"),Client("Skills Reader Example")
    owner:Login();reader:Login();Step(90)
    owner.env.GetProfessions=function() return nil,2 end
    owner.ranks={52,200};owner:Event("SKILL_LINES_CHANGED");Step(90)
    local record=Received(reader,owner)
    assert(not record.skills[1] and not record.professionRanks[1] and record.professionRanks[2]==200)
    owner.env.GetProfessions=function() return 2 end
    owner:Event("SKILL_LINES_CHANGED");Step(90)
    record=Received(reader,owner)
    assert(record.skills[1]=="Mining" and record.professionRanks[1]==200 and not record.professionRanks[2])
    owner.env.GetProfessions=function() return nil end
    owner:Event("SKILL_LINES_CHANGED");Step(90)
    record=Received(reader,owner)
    assert(not next(record.skills) and not next(record.professionRanks) and record.snapshot.items[2770].count==7)
end

-- Run with a saved pre-change Sync.lua to exercise actual protocol-2 compatibility.
if os.getenv("GUILDSTOCK_LEGACY_SYNC") then
    clients,bus,log,clock,filter = {},{},{},0,nil
    local old=Client("Legacy Example",os.getenv("GUILDSTOCK_LEGACY_SYNC"))
    local new=Client("Updated Example")
    old:Login();new:Login();Step(120)
    assert(Received(old,new).snapshot.items[2770].count==7 and Received(new,old).snapshot.items[2770].count==7)
    local ranks=Received(new,old).professionRanks
    assert(not ranks or ranks[1]==52,"optional levels remain compatible when supplied by the older owner")
    new.inventory[2770].count=15;new.ranks={300,300};new.addon.Observe();Step(90)
    assert(Received(old,new).snapshot.items[2770].count==15,"old clients keep receiving inventory changes")
    old.inventory[2770].count=9;old.addon.Observe();Step(90)
    assert(Received(new,old).snapshot.items[2770].count==9,"new clients keep receiving old inventory changes")
    new.addon.SetSharingEnabled(false);Step(30)
    assert(next(Received(old,new).snapshot.items)==nil,"older clients still accept direct privacy withdrawals")
    new.addon.SetSharingEnabled(true);Step(90)
    assert(Received(old,new).snapshot.items[2770].count==15)
    local offline=Client("Legacy Offline Example",os.getenv("GUILDSTOCK_LEGACY_SYNC"))
    offline.inventory[2770].count=77;offline:Login();Step(90)
    assert(Received(old,offline) and Received(new,offline))
    offline.online=false
    local newcomer=Client("Mixed Newcomer Example");newcomer:Login();Step(120)
    local advertised=false
    for _,packet in ipairs(log) do
        if packet.sender==old.name and packet.message:match("^2|D|") then advertised=true end
    end
    assert(advertised and not Received(newcomer,offline),"real legacy relay advertisements are ignored")
    assert(Received(newcomer,old).snapshot.items[2770].count==9
        and Received(old,newcomer).snapshot.items[2770].count==7,"legacy relay traffic cannot interrupt direct discovery")
    offline.online=true;offline:Event("PLAYER_ENTERING_WORLD")
    newcomer:Event("CLUB_MEMBERS_UPDATED",42);Step(90)
    assert(Received(newcomer,offline).snapshot.items[2770].count==77,"older owners still refresh new readers directly")
end

print("GuildStock sync: fast login, 30-second batching, frozen snapshots, direct-only history, relay rejection/migration, durable versions, privacy, repair, optional profession levels and bounded traffic OK")
