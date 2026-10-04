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
        lockdown = false, inventory = {[2770] = {count = 7, bound = 1}}, bank = {}, frames = {}, timers = {}, result = 0}
    local env = setmetatable({}, {__index = _G})
    env._G, env.SlashCmdList = env, {}
    env.GetLocale = function() return "enUS" end
    env.GetTime, env.time = function() return clock end, function() return epoch + math.floor(clock) end
    env.canaccessvalue = function(value) return value ~= secret end
    env.InCombatLockdown = function() return client.combat or false end
    env.IsInGuild = function() return client.guild ~= nil end
    env.GetProfessions = function() return 1, 2 end
    env.GetProfessionInfo = function(i) return "Synthetic", nil, nil, nil, nil, nil, i end
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
            return {name = peer.name, isSelf = peer == client, presence = peer.online and 1 or 4, race = peer.race}
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

-- Recover the newest offline-owner record, persist it, and relay it through another hop.
do
    clients,bus,log,clock,filter = {},{},{},0,nil
    local reader,owner,holder=Client("Returning Example"),Client("Offline Owner Example"),Client("Holder Example")
    reader:Login();owner:Login();holder:Login();Step(60)
    local old=Copy(reader.env.GuildStockDB)
    reader.online=false
    owner.inventory[2770].count=40;owner.addon.Observe();Step(60)
    local original=Copy(Received(holder,owner))
    assert(original.snapshot.items[2770].count==40)
    owner.online=false
    reader=Reload(reader,old);Step(60)
    local recovered=Received(reader,owner)
    assert(recovered and recovered.relayed and recovered.revision==original.revision and recovered.snapshot.items[2770].count==40)
    assert(recovered.snapshot.observedAt==original.snapshot.observedAt and recovered.receivedAt>original.receivedAt,
        "relay reception must not rejuvenate the owner's observation")
    holder.online=false;reader=Reload(reader);Step(30)
    local newcomer=Client("Later Example");newcomer:Login();Step(60)
    assert(Received(newcomer,owner) and Received(newcomer,owner).snapshot.items[2770].count==40)
    assert(Received(newcomer,owner).snapshot.observedAt==original.snapshot.observedAt,
        "a second hop after reloading the holder preserves the original observation")
    assert(newcomer.addon.SyncMember(owner.name).offline)
    for _, entry in ipairs(newcomer.addon.MaterialOwners(2770,false)) do assert(entry.id~=owner.name) end
    local accepted=Received(newcomer,owner)
    Receive(newcomer,reader,"2|D|1-2|n2,"..old.guildHistory.characters[owner.name].revision)
    Receive(newcomer,reader,"2|T|1-2|n2|"..old.guildHistory.characters[owner.name].revision.."|1|1|"..reader.env.time().."|0,0|2770,7,0")
    Step(5)
    assert(Received(newcomer,owner)==accepted,"old data with a newer receipt timestamp cannot override a newer owner revision")
    newcomer:Event("CLUB_MEMBER_REMOVED",42,2)
    Receive(newcomer,reader,"2|D|1-2|n2,"..original.revision)
    Step(30);assert(not Received(newcomer,owner),"a confirmed departed owner cannot be resurrected by a relay")
end

-- Relayed empty withdrawals supersede stock; a stale holder cannot resurrect excluded items.
do
    clients,bus,log,clock,filter = {},{},{},0,nil
    local reader,owner,holder=Client("Private Returning Example"),Client("Private Owner Example"),Client("Private Holder Example")
    reader:Login();owner:Login();holder:Login();Step(60)
    local old=Copy(reader.env.GuildStockDB);reader.online=false
    owner.incomplete=true;owner.addon.Observe();owner.addon.SetSharingEnabled(false);Step(15)
    local withdrawal=Copy(Received(holder,owner))
    assert(next(withdrawal.snapshot.items)==nil)
    owner.online=false;reader=Reload(reader,old);Step(60)
    assert(Received(reader,owner).revision==withdrawal.revision and next(Received(reader,owner).snapshot.items)==nil)
    holder=Reload(holder,old);Step(60) -- old belongs to the same synthetic guild; includes the stale owner's record
    assert(next(Received(reader,owner).snapshot.items)==nil)
end

-- Missing history fragments repair with bounded attempts and atomic replacement.
do
    clients,bus,log,clock,filter = {},{},{},0,nil
    local owner,holder=Client("Repair Owner Example"),Client("Repair Holder Example")
    owner.inventory={};local n=0
    for id in pairs(owner.addon.catalogSeed) do n=n+1;owner.inventory[id]={count=n,bound=0};if n==100 then break end end
    owner:Login();holder:Login();Step(60);assert(Received(holder,owner))
    owner.online=false
    local reader=Client("Repair Reader Example")
    local lost,partial=false,false
    filter=function(packet,client)
        if client==reader and packet.message:match("^2|T|") then
            local part=packet.message:match("^2|T|[^|]+|[^|]+|%d+|(%d+)|")
            if part=="2" and not lost then lost=true;return false end
            if lost and not Received(reader,owner) then partial=true end
        end
        return true
    end
    reader:Login();Step(20)
    assert(lost and partial and not Received(reader,owner),"partial relays are never visible")
    Step(60);filter=nil
    assert(Received(reader,owner) and Received(reader,owner).snapshot.items[next(owner.inventory)])
    local requests=0
    for _,packet in ipairs(log) do if packet.sender==reader.name and packet.message:match("^2|R|") then requests=requests+1 end end
    assert(requests==2,"one missing fragment repairs once after an inactivity timeout")
    local quiet=#log;Step(600);assert(#log==quiet,"relaying settles without an idle network heartbeat")
end

-- A donor announcement invalidates its older cached copy even if the replacement never arrives.
do
    clients,bus,log,clock,filter = {},{},{},0,nil
    local owner,holder=Client("Withdrawal Owner Example"),Client("Withdrawal Holder Example")
    owner:Login();holder:Login();Step(60)
    local earlier=Received(holder,owner).revision
    filter=function(packet,client) return not (client==holder and packet.sender==owner.name and packet.message:match("^2|S|")) end
    owner.addon.SetSharingEnabled(false);Step(15)
    assert(Received(holder,owner).supersededBy>earlier)
    owner.online=false;filter=nil;holder=Reload(holder)
    local reader=Client("Withdrawal Reader Example");reader:Login();Step(90)
    assert(not Received(reader,owner),"known superseded inventory must not be advertised after a holder reload")
end

-- Old history remains readable but has no invented relay version; future schemas survive untouched.
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

-- Native IDs stay opaque, including large numeric IDs and punctuation in string IDs.
for _,nativeID in ipairs({9007199254740991,"member|opaque,with%;punctuation"}) do
    clients,bus,log,clock,filter = {},{},{},0,nil
    local owner,holder=Client("Opaque Owner Example"),Client("Opaque Holder Example")
    owner.memberID=nativeID;owner:Login();holder:Login();Step(60);owner.online=false
    local reader=Client("Opaque Reader Example");reader:Login();Step(60)
    assert(Received(reader,owner) and Received(reader,owner).memberID==nativeID,
        "relay identities must retain the exact native guild member ID")
end

-- Exhausted relay retries stay quiet; local rediscovery can request the same missing revision again.
do
    clients,bus,log,clock,filter = {},{},{},0,nil
    local owner,holder=Client("Lost Owner Example"),Client("Lost Holder Example")
    owner:Login();holder:Login();Step(60);owner.online=false
    local reader=Client("Lost Reader Example")
    filter=function(packet,client) return not (client==reader and packet.message:match("^2|T|")) end
    reader:Login();Step(180)
    local requests=0
    for _,packet in ipairs(log) do if packet.sender==reader.name and packet.message:match("^2|R|") then requests=requests+1 end end
    assert(requests==3 and not Received(reader,owner))
    local quiet=#log;Step(120);assert(#log==quiet)
    filter=nil;reader.addon.SyncDiscover();Step(60)
    assert(Received(reader,owner),"explicit bounded rediscovery recovers after exhausted history retries")
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

print("GuildStock sync: fast login, 30-second batching, frozen snapshots, offline relays, durable versions, privacy, repair, migrations and bounded traffic OK")
