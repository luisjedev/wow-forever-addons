-- Two isolated addon instances, synthetic names/inventories and a controllable GUILD bus.
math.randomseed(17)
local clock, epoch, clients, bus, log = 0, 1800000000, {}, {}, {}
local filter
local secret = {}
local function Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}; for k, v in pairs(value) do result[k] = Copy(v) end; return result
end
local function Client(name)
    local client = {name = name, guild = 42, rosterReady = true, online = true, restricted = false,
        lockdown = false, inventory = {[2770] = {count = 7, bound = 1}}, frames = {}, timers = {}, result = 0}
    local env = setmetatable({}, {__index = _G})
    env._G, env.SlashCmdList = env, {}
    env.GetLocale = function() return "enUS" end
    env.GetTime, env.time = function() return clock end, function() return epoch + math.floor(clock) end
    env.canaccessvalue = function(value) return value ~= secret end
    env.InCombatLockdown = function() return false end
    env.IsInGuild = function() return client.guild ~= nil end
    env.GetProfessions = function() return 1, 2 end
    env.GetProfessionInfo = function(i) return "Synthetic", nil, nil, nil, nil, nil, i end
    env.C_TradeSkillUI = {GetProfessionInfoBySkillLineID = function(i) return {profession = i} end}
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
            assert(client.restricted == false and client.lockdown == false)
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
            for id, peer in ipairs(clients) do if peer.guild == client.guild and not peer.removed then ids[#ids + 1] = id end end
            return ids
        end,
        GetMemberInfo = function(_, id)
            local peer = clients[id]
            if client.unreadable == id then return {isSelf = false, presence = 4} end
            return {name = peer.name, isSelf = peer == client, presence = peer.online and 1 or 4}
        end,
    }
    local addon = {}
    for _, file in ipairs({"Locales", "GuildStock", "Probe", "ItemNames", "CatalogSeed", "Catalog", "Sync"}) do
        local fn = assert(loadfile("GuildStock/" .. file .. ".lua")); setfenv(fn, env); fn("GuildStock", addon)
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
    client:Event("CHAT_MSG_ADDON", "GuildStockS1", message, channel or "GUILD", sender.name)
end
local a, b = Client("Alpha Example"), Client("Beta Example")
b.inventory = {[2589] = {count = 4, bound = 0}, [2835] = {count = 2, bound = 0}, [999999] = {count = 99, bound = 0}}
a:Login(); b:Login(); Step(90)
assert(Received(a,b) and Received(b,a), "login alone must exchange complete inventories in both directions")
assert(Received(b,a).snapshot.items[2770].count == 7 and Received(a,b).snapshot.items[2589].count == 4)
assert(not Received(a,b).snapshot.items[999999], "only catalog materials are shared")
assert(Received(a,b).skills[1] == "Alchemy" and Received(a,b).skills[2] == "Mining")
assert(#a.addon.GuildCharacters() == 1 and #a.addon.MaterialOwners(2589, true) == 1)
local quiet = #log; Step(600); assert(#log == quiet, "unchanged inventories must not emit heartbeats")

-- Fixed five-minute batch; multiple loots do not reset its deadline.
a.inventory[2770].count = 8; a.addon.Observe(); local changedAt = clock
Step(200); a.inventory[2770].count = 12; a.addon.Observe(); Step(99)
assert(#log == quiet and Received(b,a).snapshot.items[2770].count == 7)
Step(80)
assert(Received(b,a).snapshot.items[2770].count == 12 and clock - changedAt < 400)
quiet = #log
a.inventory[2770].count = 13; a.addon.Observe(); Step(100)
a.inventory[2770].count = 12; a.addon.Observe(); Step(300)
assert(#log == quiet, "a reverted change produces no publication")

-- A temporary return to the published quantity cannot restart an existing batch window.
a.inventory[2770].count = 14; a.addon.Observe(); changedAt = clock
Step(200); a.inventory[2770].count = 12; a.addon.Observe()
Step(99); a.inventory[2770].count = 15; a.addon.Observe(); Step(80)
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
for _, message in ipairs({"bad", "2|H|1-2|1", "1|S|1-2|1|0|1|0|0,0|2770,9,0", string.rep("x",241)}) do Receive(b,a,message) end
Receive(b,a,"1|H|1-2|999", "WHISPER")
Receive(b,{name="Unknown Example"},"1|H|1-2|999")
Receive(b,b,"1|H|1-2|999")
b.addon.ReceiveSync("GuildStockS1", secret, "GUILD", a.name)
assert(Received(b,a) == before)

-- Lost fragment repair retains the previous snapshot until all replacement parts arrive.
a.inventory = {}
local n = 0
for id in pairs(a.addon.catalogSeed) do n=n+1; a.inventory[id]={count=n,bound=0}; if n==12 then break end end
local held, lost = {}, false
filter = function(packet, client)
    if client == b and packet.sender == a.name and packet.message:match("^1|S|") then
        held[#held + 1] = packet.message
        local part = packet.message:match("^1|S|[^|]+|%d+|(%d+)|")
        if part == "2" and not lost then lost = true; return false end
    end
    return true
end
a.addon.Observe(); Step(315)
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
Receive(b,a,"1|H|"..oldSession.."|999")
Step(40)
assert(Received(b,a).snapshot.items[2770].count == 42)

-- Restrictions and lockdown block all outgoing packets, with local inventory still usable.
a.restricted = true; a.inventory[2770].count = 43; a.addon.Observe(); quiet = #log; Step(320)
for i=quiet+1,#log do assert(log[i].sender ~= a.name) end
assert(a.addon.snapshot.items[2770].count == 43 and a.addon.SyncStatus() == "Addon messages restricted")
a.restricted = false; a.lockdown = true; quiet = #log; Step(20)
for i=quiet+1,#log do assert(log[i].sender ~= a.name) end
a.lockdown = false; Step(100); assert(Received(b,a).snapshot.items[2770].count == 43)

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
    if receiver==d and packet.sender==c.name and packet.message:match("^1|S|") then reverse[#reverse+1]=packet.message; return false end
    return true
end
c:Login();d:Login();Step(90)
assert(#reverse>=5 and not Received(d,c))
for i=#reverse,2,-1 do Receive(d,c,reverse[i]) end
-- Repeated resends may contain part 1: finish all packets and verify exact absolute counts.
for i=#reverse,1,-1 do Receive(d,c,reverse[i]) end
assert(Received(d,c))
for id,item in pairs(c.inventory) do assert(Received(d,c).snapshot.items[id].count==item.count) end
filter=nil

-- Initial readiness, unavailable flags, unknown saved schemas and failed registration fail closed.
clients,bus,log,clock = {},{},{},0
local e,f=Client("Epsilon Example"),Client("Zeta Example")
e.rosterReady=false; f.restricted=true; e:Login();f:Login();Step(60);assert(#log==0)
e.rosterReady=true; e.restricted=secret;Step(30);assert(#log==0)
e.restricted=false;e.lockdown=secret;Step(30);assert(#log==0)
e.lockdown=false;f.restricted=false;Step(120);assert(Received(e,f) and Received(f,e))
clients,bus,log,clock = {},{},{},0
local g,h=Client("Eta Example"),Client("Theta Example")
g.registration=2;h.env.GuildStockDB={version=99,hiddenItems="preserve"}
g:Login();h:Login();Step(120);assert(#log==0 and h.env.GuildStockDB.version==99)
assert(h.env.GuildStockDB.hiddenItems=="preserve" and g.addon.snapshot)

-- API failure attempts are bounded; they never masquerade as remote receipts.
clients,bus,log,clock = {},{},{},0
local j,k=Client("Iota Example"),Client("Kappa Example")
j.result=3;k.restricted=true;j:Login();k:Login();Step(180)
local attempts=0;for _,packet in ipairs(log) do if packet.sender==j.name then attempts=attempts+1 end end
assert(attempts==3 and j.addon.sync.result=="AddonMessageThrottle" and not Received(k,j))
quiet=#log;Step(300);assert(#log==quiet,"bounded failures do not become a periodic retry broadcast")

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
            if packet.sender==m.name and packet.message:match("^1|S|") then
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
print("GuildStock sync: automatic exchange, fixed batching, privacy, zero, repair, sessions, transitions, restrictions and bounded traffic OK")
