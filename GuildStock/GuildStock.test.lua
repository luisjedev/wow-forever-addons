-- Run from the repository root with Lua 5.1 or LuaJIT. No client or saved files are accessed.
local clock, epoch, combat = 100, 1800000000, false
GetTime = function() return clock end
time = function() return epoch end
date = function(_, value) return tostring(value) end
InCombatLockdown = function() return combat end
GetLocale = function() return "enUS" end
local secret = setmetatable({}, { __tostring = function() error("secret used") end })
canaccessvalue = function(value) return value ~= secret end
local timers, frames, fontStrings = {}, {}, {}
C_Timer = { After = function(_, callback) timers[#timers + 1] = callback end }
local function Drain()
    local callbacks = timers
    timers = {}
    for _, callback in ipairs(callbacks) do callback() end
end
local methods = {}
for _, method in ipairs({ "SetSize", "SetFrameLevel", "SetFrameStrata", "SetClampedToScreen", "SetMovable",
    "EnableMouse", "RegisterForDrag", "RegisterForClicks", "SetHighlightTexture", "SetTexture", "SetWidth",
    "SetJustifyH", "SetJustifyV", "SetScrollChild", "UpdateScrollChildRect", "StartMoving", "StopMovingOrSizing", "SetBackdrop", "SetBackdropBorderColor", "SetAllPoints",
    "SetFont", "SetFontObject", "SetShadowOffset", "SetTextColor", "SetTexCoord", "SetVertexColor", "SetWordWrap", "SetAutoFocus",
    "SetMaxLetters", "ClearFocus", "SetOrientation", "SetMinMaxValues", "SetValueStep", "SetObeyStepOnDrag",
    "SetThumbTexture", "SetDesaturated", "SetAlpha" }) do
    methods[method] = function() end
end
function methods:SetRoundLayoutToNearestPixel() end
function methods:SetScript(event, fn) self.scripts[event] = fn end
function methods:HookScript(event, fn)
    local previous = self.scripts[event]
    self.scripts[event] = function(...)
        if previous then previous(...) end
        fn(...)
    end
end
function methods:GetScript(event) return self.scripts[event] end
hooksecurefunc = function(object, key, callback)
    local original = object[key]
    object[key] = function(...)
        original(...)
        callback(...)
    end
end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:UnregisterAllEvents() self.events = {} end
function methods:SetPoint(...) self.point = {...} end
function methods:ClearAllPoints() self.point = nil end
function methods:SetText(value)
    self.text = value
    if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end
end
function methods:GetText() return self.text or "" end
function methods:SetSize(width, height) self.width, self.height = width, height end
function methods:SetScale(value) self.scale = value end
function methods:GetScale() return self.scale or 1 end
function methods:SetBackdropColor(...) self.background = {...} end
function methods:SetBackdropBorderColor(...) self.border = {...} end
function methods:SetTexture(value) self.texture, self.atlas = value, nil end
function methods:AddMaskTexture(mask) self.mask = mask end
function methods:SetTexCoord(...) self.coords = {...} end
function methods:SetFont(path, size) self.fontPath, self.fontSize = path, size end
function methods:SetFontObject(value) self.fontObject = value end
function methods:SetFontHeight(value) self.fontSize = value end
function methods:SetAtlas(value) self.atlas = value end
function methods:SetEnabled(value) self.enabled = value end
function methods:SetChecked(value) self.checked = value end
function methods:SetFillToInterior(value) self.fillToInterior = value end
function methods:SetCustomOnMouseUpHandler(handler) self.customMouseUpHandler = handler end
function methods:GetChecked() return self.checked end
function methods:SetHeight(value) self.height = value end
function methods:SetWidth(value) self.width = value end
function methods:GetStringHeight() return #(self.text or "") end
function methods:GetFrameLevel() return 1 end
function methods:GetWidth() return self.width or 160 end
function methods:GetHeight() return self.height or 160 end
function methods:GetEffectiveScale() return 1 end
function methods:GetCenter() return 100, 100 end
function methods:GetValue() return self.value or 0 end
function methods:SetValue(value)
    if self.scroll then value = math.max(0, math.min(value, self.scroll:GetVerticalScrollRange())) end
    if self.value == value then return end
    self.value = value
    if self.scroll then self.scroll:SetVerticalScroll(value) end
end
function methods:SetScrollChild(child) self.child = child end
function methods:GetVerticalScrollRange() return self.child and math.max(0, self.child:GetHeight() - self:GetHeight()) or 0 end
function methods:GetVerticalScroll() return self.verticalScroll or 0 end
function methods:SetVerticalScroll(value)
    self.verticalScroll = value
    if self.scripts.OnVerticalScroll then self.scripts.OnVerticalScroll(self, value) end
end
function methods:IsShown() return self.shown end
function methods:SetShown(value)
    self.shown = value
    local fn = self.scripts[value and "OnShow" or "OnHide"]
    if fn then fn(self) end
end
function methods:Hide() self:SetShown(false) end
function methods:Show() self:SetShown(true) end
local function Frame() return setmetatable({scripts = {}, events = {}, shown = true}, {__index = methods}) end
methods.CreateTexture, methods.GetHighlightTexture, methods.GetThumbTexture = Frame, Frame, Frame
methods.CreateMaskTexture = Frame
methods.CreateAnimationGroup, methods.CreateAnimation = Frame, Frame
function methods:SetOrigin(...) self.origin = {...} end
function methods:SetScaleFrom(x, y) self.scaleFrom = {x, y} end
function methods:SetScaleTo(x, y) self.scaleTo = {x, y} end
function methods:SetDuration(value) self.duration = value end
function methods:SetSmoothing(value) self.smoothing = value end
function methods:GetSmoothProgress() return self.progress or 0 end
function methods:IsPlaying() return self.playing == true end
function methods:Play() self.playing = true; self.playCount = (self.playCount or 0) + 1 end
function methods:Stop() self.playing = false end
function methods:CreateFontString()
    local label = Frame()
    fontStrings[#fontStrings + 1] = label
    return label
end
CreateFrame = function(_, name, parent, template)
    local f = Frame()
    f.parent = parent
    f.template = template
    f.TitleText, f.ScrollBar = Frame(), Frame()
    if template == "LargeSideTabButtonTemplate" then f.Icon = Frame() end
    f.ScrollBar.scroll = f
    frames[#frames + 1] = f
    if name then _G[name] = f end
    return f
end
UIParent, Minimap, GameTooltip = Frame(), Frame(), Frame()
UIParent:SetSize(1920, 1080)
STANDARD_TEXT_FONT = "Fonts/example.ttf"
methods.AddLine = function() end
function methods:SetOwner(owner, anchor) self.owner, self.anchor = owner, anchor end
function methods:IsOwned(owner) return self.owner == owner end
GetCursorPosition = function() return 150, 100 end
GetBuildInfo = function() return "1.60.1", "70205", "", 16001 end
UISpecialFrames, SlashCmdList = {}, {}
Constants = { InventoryConstants = { NumBagSlots = 4, NumReagentBagSlots = 1 } }
Enum = {
    CraftingReagentType = {Basic = 1, Modifying = 2},
    Profession = {Mining = 1, Engineering = 2, FirstAid = 3, Cooking = 4, Fishing = 5},
    BagIndex = { Backpack = 0, ReagentBag = 5 },
    RegisterAddonMessagePrefixResult = { Success = 0, DuplicatePrefix = 1, InvalidPrefix = 2 },
    SendAddonMessageResult = { Success = 0, AddonMessageThrottle = 3, AddOnMessageLockdown = 11 },
    ClubMemberPresence = { Online = 1, OnlineMobile = 2, Offline = 3, Away = 4, Busy = 5 },
}
local function Item(id, count, bound) return { itemID = id, stackCount = count, isBound = bound, isLocked = false } end
local bags, sizes, equipped = {}, {}, {}
local reads = {}
C_Container = {
    GetContainerNumSlots = function(bag)
        assert(bag >= 0 and bag <= 5, "never scan bank storage")
        reads[bag] = true
        return sizes[bag] or 0
    end,
    GetContainerNumFreeSlots = function(bag)
        local occupied = 0
        for _ in pairs(bags[bag] or {}) do occupied = occupied + 1 end
        return sizes[bag] - occupied
    end,
    GetContainerItemInfo = function(bag, slot) return (bags[bag] or {})[slot] end,
    ContainerIDToInventoryID = function(bag) return 19 + bag end,
}
GetInventoryItemID = function(_, slot) return equipped[slot] end
GetProfessions = function() return nil, 2, nil, nil, 5 end
GetProfessionInfo = function(index) return index == 2 and "Engineering" or "Cooking", nil, nil, nil, nil, nil, index * 100 end
C_Item = { GetItemInfo = function(id)
    if id == 10 then return "Sample item", nil, nil, nil, nil, nil, nil, nil, nil, 123, nil, nil, nil, nil, nil, nil, true end
end }
C_TradeSkillUI = {
    GetAllRecipeIDs = function() return {1, 2} end,
    GetProfessionInfoBySkillLineID = function(id)
        return {profession = ({[100] = 1, [200] = 2, [300] = 3, [400] = 5, [500] = 4})[id]}
    end,
    GetProfessionInfoByRecipeID = function(id) return {profession = id == 1 and 2 or 4} end,
    GetRecipeSchematic = function(id)
        return {reagentSlotSchematics = {{reagents = {{itemID = id == 1 and 10 or 20}}}}}
    end,
}
local sent, restriction, sendResult, registerResult, club = {}, false, 0, 0, 123
local chatLockdown = false
local members = {
    {name = "Self Example", isSelf = true, presence = 1},
    {name = "Peer Example", isSelf = false, presence = 1},
}
C_ChatInfo = {
    RegisterAddonMessagePrefix = function() return registerResult end,
    AreOutgoingAddonChatMessagesRestricted = function() return restriction end,
    InChatMessagingLockdown = function() return chatLockdown end,
    SendAddonMessage = function(prefix, message, channel, target)
        assert(channel == "GUILD" and target == nil, "all addon traffic must use GUILD without a whisper target")
        sent[#sent + 1] = {prefix, message, channel, target}
        return sendResult
    end,
}
C_Club = {
    GetGuildClubId = function() return club end,
    GetClubMembers = function() return {1, 2} end,
    GetMemberInfo = function(_, id) return members[id] end,
}
local addon = {}
for _, file in ipairs({ "Locales", "GuildStock", "Probe", "ItemNames", "Catalog", "UI" }) do
    assert(loadfile("GuildStock/" .. file .. ".lua"))("GuildStock", addon)
end
local function Event(event, ...)
    local listeners = {}
    for _, f in ipairs(frames) do if f.events[event] then listeners[#listeners + 1] = f end end
    for _, f in ipairs(listeners) do f.scripts.OnEvent(f, event, ...) end
end

-- Restoring and updating one field must preserve every unrelated saved field.
local old = {items = {[99] = {count = 2, bound = 0}}, observedAt = epoch - 10}
GuildStockDB = {version = 1, own = old, favorites = {[10] = true}, minimapAngle = 0.5}
local saved = GuildStockDB
Event("ADDON_LOADED", "AnotherAddon")
assert(not addon.db)
Event("ADDON_LOADED", "GuildStock")
assert(addon.snapshot == old)
sizes = {[0] = 4, [1] = 2, [5] = 1}
bags = {[0] = {Item(10, 4, false), Item(10, 2, true)}, [1] = {Item(10, 3, false)}, [5] = {Item(20, 1, false)}}
Event("PLAYER_LOGIN")
Event("BAG_UPDATE_DELAYED")
assert(#timers == 1 and #sent == 0, "coalesce scans and do not send on login")
Drain()
assert(GuildStockDB == saved and saved.favorites[10])
assert(addon.snapshot.items[10].count == 9 and addon.snapshot.items[10].bound == 2)
assert(addon.snapshot.items[20].count == 1 and reads[5])

-- Privacy is per item across all stacks; it must not destroy the complete local observation.
local privateObservation = addon.snapshot
addon.SetItemHidden(10, true)
local exclusions = saved.hiddenItems
local shareable = addon.ShareableSnapshot()
assert(exclusions[10] and not shareable.items[10] and shareable.items[20].count == 1)
assert(shareable.observedAt == privateObservation.observedAt and shareable.hiddenItems == nil)
assert(addon.snapshot == privateObservation and saved.own.items[10].count == 9 and saved.own.items[10].bound == 2)
shareable.items[20].count = 999
assert(saved.own.items[20].count == 1, "exported copies cannot mutate local quantities")
addon.db, addon.snapshot = nil, nil
Event("PLAYER_LOGIN")
Drain()
assert(saved.hiddenItems == exclusions and addon.IsItemHidden(10) and not addon.ShareableSnapshot().items[10], "login restores exclusions")
addon.SetItemHidden(20, true)
assert(next(addon.ShareableSnapshot().items) == nil, "all hidden is a complete empty sharing snapshot")
addon.SetItemHidden(10, false)
addon.SetItemHidden(20, false)
assert(addon.ShareableSnapshot().items[10].count == 9 and exclusions[10] == nil)
for _, invalid in ipairs({0, -1, 1.5, "10", secret}) do addon.SetItemHidden(invalid, true) end
addon.SetItemHidden(10, "true")
assert(next(exclusions) == nil, "invalid actions cannot create saved exclusions")
for _, unsupported in ipairs({"keep me", {[10] = "unknown"}, {["10"] = true}}) do
    saved.hiddenItems = unsupported
    assert(addon.ShareableSnapshot() == nil and saved.hiddenItems == unsupported, "unsupported privacy data prevents exports and stays intact")
end
saved.hiddenItems = "keep me"
addon.SetItemHidden(10, true)
assert(saved.hiddenItems == "keep me")
saved.hiddenItems = exclusions
local withObservation = addon.snapshot
addon.snapshot = nil
assert(addon.ShareableSnapshot() == nil, "missing observations cannot be advertised as empty")
addon.snapshot = withObservation
assert(addon.ProfessionNames() == "Engineering, Cooking", "secondary professions survive nil holes")
do
    local getProfessions, getInfo = GetProfessions, GetProfessionInfo
    local getBySkillLine = C_TradeSkillUI.GetProfessionInfoBySkillLineID
    assert(table.concat(addon.LearnedProfessions(), ",") == "Engineering,Cooking")
    GetProfessions = function() return 1, 2, 3, 4, 5 end
    GetProfessionInfo = function(index) return "Localized name", nil, nil, nil, nil, nil, index * 100 end
    assert(table.concat(addon.LearnedProfessions(), ",") == "Mining,Engineering,Cooking,Fishing,FirstAid",
        "stable IDs identify localized professions in primary/secondary book order")
    GetProfessions = function() return nil, nil, 3, nil, 5 end
    assert(table.concat(addon.LearnedProfessions(), ",") == "Cooking,FirstAid", "secondary-only characters retain sparse skills")
    GetProfessions = function() return 2, 2 end
    assert(table.concat(addon.LearnedProfessions(), ",") == "Engineering", "duplicate professions appear once")
    GetProfessions = function() end
    assert(#addon.LearnedProfessions() == 0, "no learned professions is a complete empty result")
    for _, query in ipairs({function() error("not ready") end, function() return secret end, function() return "bad index" end}) do
        GetProfessions = query
        assert(addon.LearnedProfessions() == nil, "failed or inaccessible reads stay unknown")
    end
    GetProfessions = getProfessions
    for _, query in ipairs({function() error("not ready") end, function() return nil end,
        function() return nil, nil, nil, nil, nil, nil, secret end}) do
        GetProfessionInfo = query
        assert(addon.LearnedProfessions() == nil, "unavailable skill lines are not used as IDs")
    end
    GetProfessionInfo = getInfo
    for _, query in ipairs({function() error("not ready") end, function() return secret end,
        function() return {profession = secret} end, function() return {} end}) do
        C_TradeSkillUI.GetProfessionInfoBySkillLineID = query
        assert(addon.LearnedProfessions() == nil, "unknown metadata does not erase the learned list")
    end
    C_TradeSkillUI.GetProfessionInfoBySkillLineID = nil
    assert(addon.LearnedProfessions() == nil, "missing APIs are tolerated")
    C_TradeSkillUI.GetProfessionInfoBySkillLineID = getBySkillLine
end

local complete = addon.snapshot
local realInfo = C_Container.GetContainerItemInfo
C_Container.GetContainerItemInfo = function(bag, slot)
    if bag == 1 then return nil end
    return realInfo(bag, slot)
end
addon.Observe()
assert(addon.incomplete and addon.snapshot == complete and saved.own == complete, "missing occupied slot keeps snapshot")
C_Container.GetContainerItemInfo = realInfo
for _, field in ipairs({ "itemID", "stackCount", "isBound", "isLocked" }) do
    local original = bags[0][1][field]
    bags[0][1][field] = secret
    addon.Observe()
    assert(addon.snapshot == complete and addon.incomplete, "secret " .. field)
    bags[0][1][field] = original
end
bags[0][1].isLocked = true
addon.Observe()
assert(addon.snapshot == complete and addon.incomplete)
bags[0][1].isLocked = false
equipped[21] = 500
addon.Observe()
assert(addon.snapshot == complete and addon.incomplete, "zero capacity for an equipped bag is not empty")
equipped = {}
local free = C_Container.GetContainerNumFreeSlots
C_Container.GetContainerNumFreeSlots = function() error("unavailable") end
addon.Observe()
assert(addon.snapshot == complete and addon.incomplete)
C_Container.GetContainerNumFreeSlots = free
combat = true
addon.Observe()
assert(addon.snapshot == complete and addon.incomplete)
combat = false
bags[0] = { Item(10, 1, false) }
bags[1], bags[5] = {}, {}
Event("PLAYER_REGEN_ENABLED")
Drain()
assert(addon.snapshot.items[10].count == 1 and not addon.snapshot.items[20], "absolute counts replace removed items")
bags[0] = {}
addon.Observe()
assert(next(addon.snapshot.items) == nil and not addon.incomplete, "successful empty observation")

-- Unknown schemas are never reset, including after new successful bag observations.
for _, unknown in ipairs({ {version = 2, own = old, favorites = {10}}, {legacy = true}, "damaged" }) do
    GuildStockDB, addon.db, addon.snapshot, addon.temporary = unknown, nil, nil, nil
    addon.Initialize()
    addon.Observe()
    assert(GuildStockDB == unknown and addon.temporary and addon.db ~= unknown)
    assert(addon.ShareableSnapshot() == nil, "unknown saved schemas cannot silently discard privacy choices for sharing")
end
GuildStockDB, addon.db, addon.snapshot, addon.temporary = saved, nil, nil, nil
addon.Initialize()
assert(addon.db == saved and addon.snapshot == saved.own)

-- Native result enums are numeric, including zero for success.
assert(addon.probe.registration == "Success")
registerResult = 1
addon.RegisterProbe()
assert(addon.probe.registration == "DuplicatePrefix")
chatLockdown = true
assert(addon.StartProbe() == addon.L["Probe unavailable: check Settings and /guildstock diagnostics."] and #sent == 0)
chatLockdown = secret
addon.StartProbe()
assert(#sent == 0)
chatLockdown = nil
addon.StartProbe()
assert(#sent == 0)
chatLockdown, combat = false, true
addon.StartProbe()
assert(#sent == 0)
combat, club = false, nil
addon.StartProbe()
assert(#sent == 0)
club, restriction = 123, true
addon.StartProbe()
assert(#sent == 1 and sent[1][3] == "GUILD" and addon.probe.GUILD == "Success")
local token = sent[1][2]:match("^2|P|(.+)$")
local function Receive(message, channel, sender)
    addon.ReceiveProbe("GuildStockP0", message, channel or "GUILD", sender or "Peer Example")
end
Receive("2|P|" .. token, "GUILD", "Self Example")
assert(#sent == 1, "self echo never proves delivery")
Receive("2|P|101-20", "GUILD", "Unknown Example")
assert(#sent == 1 and addon.probe.unmatched == 1)
members[2].presence = 3
Receive("2|P|101-20")
assert(#sent == 1, "offline roster entries cannot trigger a reply")
members[2].presence = secret
Receive("2|P|101-20")
assert(#sent == 1)
members[2].presence = 1
for _, message in ipairs({ "2|P|bad", string.rep("x", 1000), "1|P|101-20", secret }) do Receive(message) end
addon.ReceiveProbe("GuildStockP0", nil, "GUILD", "Peer Example")
Receive("2|P|101-20", "PARTY")
Receive("2|P|101-20", "WHISPER")
assert(#sent == 1, "malformed and wrong-channel messages cannot trigger replies")
Receive("2|P|101-20")
assert(#sent == 2 and sent[2][3] == "GUILD" and sent[2][2] == "2|A|101-20")
Receive("2|P|101-20")
assert(#sent == 2, "duplicate requests are bounded")
Receive("2|A|0-0", "GUILD")
Receive("2|A|" .. token, "WHISPER")
Receive("1|A|" .. token, "GUILD")
assert(addon.probe.confirmed == 0, "unrelated guild tokens, whispers and old protocol acknowledgements are ignored")
Receive("2|A|" .. token, "GUILD")
Receive("2|A|" .. token, "GUILD")
assert(addon.probe.confirmed == 1, "matching acknowledgement counts exactly once")
addon.StartProbe()
assert(#sent == 2, "probe cooldown")
clock = clock + 61
sendResult = 3
addon.StartProbe()
assert(addon.probe.GUILD == "AddonMessageThrottle")
Receive("2|P|102-20")
assert(#sent == 3, "failed send disarms the probe without retrying")
clock, sendResult = clock + 61, 0
addon.StartProbe()
club = 456
Receive("2|P|103-20")
assert(#sent == 4, "guild changes invalidate the old probe")
club = 123
Event("PLAYER_GUILD_UPDATE", "player")
Receive("2|P|103-20")
assert(#sent == 4)

clock, sendResult = clock + 61, 11
assert(addon.StartProbe() == addon.L["Probe unavailable: check Settings and /guildstock diagnostics."])
assert(addon.probe.GUILD == "AddOnMessageLockdown" and #sent == 5)
Receive("2|P|104-20")
assert(#sent == 5, "native rejection disarms the probe and cannot trigger replies")
sendResult = 0

-- Diagnostics distinguish a false flag from an unavailable read and never expose identities.
local originalPrint, diagnosticLines = print, {}
print = function(line) diagnosticLines[#diagnosticLines + 1] = line end
restriction, chatLockdown = true, false
SlashCmdList.GUILDSTOCK("diagnostics")
restriction, chatLockdown = secret, secret
SlashCmdList.GUILDSTOCK("diagnostics")
print = originalPrint
local diagnosticText = table.concat(diagnosticLines, "\n")
assert(diagnosticText:find("AreOutgoingAddonChatMessagesRestricted: true", 1, true))
assert(diagnosticText:find("InChatMessagingLockdown: false", 1, true))
assert(diagnosticText:find("AreOutgoingAddonChatMessagesRestricted: Unavailable", 1, true))
assert(not diagnosticText:find("Peer Example", 1, true) and not diagnosticText:find("Self Example", 1, true))
restriction, chatLockdown = false, false

-- Reused character skill cells keep two slots and clear stale icons when professions disappear.
local playerRow = Frame()
addon.SetPlayerSkills(playerRow, {"Alchemy", "Mining"})
local skillSlots = playerRow.skillSlots
assert(#skillSlots == 2 and skillSlots[1].icon:IsShown() and skillSlots[2].icon:IsShown())
assert(skillSlots[1].icon.texture == "Interface\\Icons\\Trade_Alchemy")
assert(skillSlots[2].icon.texture == "Interface\\Icons\\Trade_Mining")
addon.SetPlayerSkills(playerRow, {"Engineering"})
assert(playerRow.skillSlots == skillSlots and skillSlots[1].icon:IsShown())
assert(skillSlots[1].icon.texture == "Interface\\Icons\\Trade_Engineering")
assert(not skillSlots[2].icon:IsShown() and skillSlots[2].icon.texture == nil and skillSlots[2]:IsShown())
addon.SetPlayerSkills(playerRow, {[2] = "Herbalism"})
assert(not skillSlots[1].icon:IsShown() and skillSlots[2].icon:IsShown(), "a missing first profession does not hide the second")
for _, skills in ipairs({{}, {"Cooking", "FirstAid"}, {"Fishing", "unknown"}, {secret, secret}, secret}) do
    addon.SetPlayerSkills(playerRow, skills)
    for _, slot in ipairs(skillSlots) do
        assert(slot:IsShown() and not slot.icon:IsShown() and slot.icon.texture == nil, "empty placeholders contain no stale or secondary icons")
    end
end
addon.SetPlayerSkills(playerRow, nil)
assert(not skillSlots[1].icon:IsShown() and not skillSlots[2].icon:IsShown())

-- Racial badges replace recycled portraits and tolerate inaccessible/missing native data.
do
    local races = {[1] = {clientFileString = "Human"}, [7] = {clientFileString = "Gnome"},
        [5] = {clientFileString = "Scourge"}, [99] = {clientFileString = secret}}
    C_CreatureInfo = {GetRaceInfo = function(id) return races[id] end}
    GetRaceAtlas = function(token, gender, highResolution)
        assert(gender == "male" and highResolution)
        return "raceicon128-" .. (token == "scourge" and "undead" or token) .. "-male"
    end
    C_Texture = {GetAtlasInfo = function() return {} end}
    addon.SetPlayerRace(playerRow, 1, 10)
    local icon = playerRow.raceIcon
    assert(icon.atlas == "raceicon128-human-male" and icon.mask, "race icons have a circular mask")
    addon.SetPlayerRace(playerRow, 7, 10)
    assert(playerRow.raceIcon == icon and icon.atlas == "raceicon128-gnome-male", "reuse updates the race")
    addon.SetPlayerRace(playerRow, 5, 10)
    assert(icon.atlas == "raceicon128-undead-male", "native race aliases are used")
    for _, race in ipairs({secret, false, 0, -1, 1.5, "7", 99, 999}) do
        addon.SetPlayerRace(playerRow, race, 10)
        assert(icon.atlas == nil and icon.texture == "Interface\\Icons\\INV_Misc_QuestionMark", "unknown race clears stale portraits")
    end
    addon.SetPlayerRace(playerRow, nil, 10)
    assert(icon.atlas == nil)
    C_Texture.GetAtlasInfo = function() return nil end
    addon.SetPlayerRace(playerRow, 1, 10)
    assert(icon.atlas == nil and icon.coords[2] == 1, "missing artwork resets atlas cropping")
    C_Texture.GetAtlasInfo = function() return {} end
end

-- Exercise recipe discovery, real filters and native interface handlers with synthetic items.
bags[0] = {Item(10, 5, false), Item(20, 2, true)}
addon.Observe()
Event("TRADE_SKILL_LIST_UPDATE")
assert(addon.Catalog()[10].Engineering and addon.Catalog()[20].Cooking)
assert(#addon.Materials("all") == 2 and #addon.Materials("all", "Engineering") == 1)
assert(#addon.Materials("favorites") == 1 and #addon.Materials("all", nil, "[literal") == 0)
assert(#addon.Materials("all", nil, "sample") == 1)
local remembered = addon.Catalog()[20]
local snapshot = addon.snapshot
addon.snapshot = {items = {}, observedAt = epoch}
assert(#addon.Materials("all") == 2 and #addon.Materials("all", nil, "", true) == 0, "zero stock stays in the catalog")
assert(addon.Catalog()[20] == remembered)
addon.snapshot = snapshot
saved.settings = {initialView = "mine", showMinimap = true}
SlashCmdList.GUILDSTOCK("")
assert(saved.settings.initialView == "all" and saved.settings.showMinimap, "removed opening view migrates without losing other preferences")
assert(GuildStockFrame:IsShown() and UISpecialFrames[1] == "GuildStockFrame")
assert(GuildStockFrame.width == 1180 and GuildStockFrame.height == 650, "mock window proportions")
assert(addon.itemData[10].name == "Sample item" and addon.itemData[20] == false)
local function Click(label)
    for _, f in ipairs(frames) do
        if f.label and f.label.text == label then f.scripts.OnClick(f); return f end
    end
    error("Missing button: " .. label)
end
local materialInput, detailUses, detailFavorite
for _, frame in ipairs(frames) do
    if frame.list and frame.list.rows[1] and frame.list.rows[1].star then materialInput = frame end
    if frame.slots and frame.unknown then detailUses = frame end
    if frame.icon and frame.icon.atlas == "auctionhouse-icon-favorite-off" and not frame.parent.label then detailFavorite = frame end
end
assert(materialInput and detailUses and detailFavorite)
do
    local buttons, mine, other, all = {}
    for _, frame in ipairs(frames) do
        if frame.label and frame.image then buttons[frame.label:GetText()] = frame end
    end
    for _, frame in ipairs(fontStrings) do
        if frame:GetText() == "My professions" then mine = frame end
        if frame:GetText() == "Other professions" then other = frame end
        if frame:GetText() == "Used by" and frame.separator then all = frame end
    end
    local function ActiveSection(title)
        for _, heading in ipairs({all, mine, other}) do
            local active = heading == title
            assert(heading.separator.width == heading:GetWidth() * (active and 0.8 or 0.6)
                and heading.separator.height == (active and 2 or 1), "only the selected section has an extended, thicker divider")
        end
    end
    local content = buttons["All professions"].parent
    assert(not buttons["All professions"].separator:IsShown())
    for _, entry in ipairs(addon.professions) do
        assert(not buttons[addon.L[entry[1]]].separator:IsShown(), "profession entries have no separators")
    end
    assert(buttons.Favorites.separator:IsShown(), "other navigation separators remain")
    local scroll = content.parent
    assert(mine:IsShown() and other:IsShown() and buttons["All professions"].point[3] == 0)
    assert(buttons.Engineering.point[3] == -76 and buttons.Cooking.point[3] == -116)
    assert(buttons.Alchemy.point[3] < other.point[3] and other.point[3] < buttons.Cooking.point[3])
    ActiveSection(all)
    for _, heading in ipairs({all, mine, other}) do
        assert(not heading.animation:IsPlaying(), "opening shows the correct section without an entrance animation")
        assert(heading.stretch.duration == 0.5 and heading.stretch.smoothing == "OUT")
        assert(heading.stretch.origin[1] == "LEFT" and heading.stretch.scaleTo[1] == 1 and heading.stretch.scaleTo[2] == 1)
    end
    Click("Cooking")
    ActiveSection(mine)
    assert(mine.animation:IsPlaying() and all.animation:IsPlaying(), "entering and leaving sections both animate")
    assert(math.abs(mine.stretch.scaleFrom[1] - 0.75) < 0.0001 and mine.stretch.scaleFrom[2] == 1)
    local plays = mine.animation.playCount
    Click("Engineering")
    addon.Refresh()
    assert(mine.animation.playCount == plays, "refreshing or choosing another profession in the same section does not restart the animation")
    mine.stretch.progress = 0.5
    Click("Mining")
    ActiveSection(other)
    assert(math.abs(mine.stretch.scaleFrom[1] * mine.targetWidth - mine:GetWidth() * 0.7) < 0.0001,
        "a rapid reversal begins at the current animated width")
    other.stretch.progress = secret
    Click("All professions")
    ActiveSection(all)
    assert(other.fromWidth == other:GetWidth() * 0.8, "inaccessible animation progress falls back to the known layout")
    other.stretch.progress = nil
    Click("Engineering")
    ActiveSection(mine)
    local getProfessions, allocated, packetCount = GetProfessions, #frames, #sent
    GetProfessions = function() return 1, nil, 3, 4, 5 end
    Event("SKILL_LINES_CHANGED")
    assert(buttons.Mining.point[3] == -76 and buttons.Cooking.point[3] == -116
        and buttons.Fishing.point[3] == -156 and buttons["First Aid"].point[3] == -196)
    assert(buttons.Engineering.point[3] < other.point[3] and buttons.Engineering.selection:IsShown(),
        "an unlearned profession moves to Other without changing the selected filter")
    ActiveSection(other)
    assert(materialInput.list.rows[1].itemID == 10, "the selected profession still filters materials")
    local positions = {}
    for _, entry in ipairs(addon.professions) do
        local button = buttons[addon.L[entry[1]]]
        assert(button.parent == content and not positions[button.point[3]], "every profession has one distinct row")
        positions[button.point[3]] = true
    end
    GetProfessions = function() return secret end
    Event("SKILL_LINES_CHANGED")
    assert(buttons.Mining.point[3] == -76 and mine:IsShown(), "inaccessible reads retain the previous grouping")
    ActiveSection(other)
    scroll.ScrollBar:SetValue(content:GetHeight() - scroll:GetHeight())
    GetProfessions = function() end
    Event("SKILL_LINES_CHANGED")
    assert(not mine:IsShown() and other:IsShown() and buttons.Alchemy.point[3] == -76)
    assert(scroll:GetVerticalScroll() == content:GetHeight() - scroll:GetHeight(), "shorter lists clamp the scroll offset")
    GuildStockFrame:Hide()
    GetProfessions = getProfessions
    Event("SKILL_LINES_CHANGED")
    SlashCmdList.GUILDSTOCK("")
    assert(mine:IsShown() and buttons.Engineering.point[3] == -76, "reopening discovers changes made while hidden")
    ActiveSection(all)
    assert(#frames == allocated and #sent == packetCount, "regrouping reuses buttons and sends no messages")
end
-- Fishing is a secondary profession filter and shares the material-use renderer.
local fishingButton = Click("Fishing")
assert(fishingButton.image.texture == "Interface\\Icons\\Trade_Fishing")
assert(not materialInput.list.rows[1]:IsShown(), "Fishing without observed associations has no matches")
addon.Catalog()[20].Fishing = true
addon.InvalidateMaterials() -- fixture mutation bypasses recipe discovery
addon.Refresh()
assert(materialInput.list.rows[1].itemID == 20 and materialInput.list.rows[1]:IsShown())
assert(not materialInput.list.rows[2]:IsShown(), "Fishing filters out unrelated materials")
assert(detailUses.slots[2].icon.texture == "Interface\\Icons\\Trade_Fishing")
detailUses.slots[2].scripts.OnEnter(detailUses.slots[2])
assert(GameTooltip:GetText() == "Fishing")
addon.Catalog()[20].Fishing = nil
addon.InvalidateMaterials()
Click("All professions")
assert(detailUses.slots[1].icon.texture == "Interface\\Icons\\INV_Misc_Food_15")
detailUses.slots[1].scripts.OnEnter(detailUses.slots[1])
assert(GameTooltip:GetText() == "Cooking", "material detail uses the same profession tooltip as inventory")
local selectedRow = materialInput.list.rows[1]
selectedRow.star.scripts.OnClick(selectedRow.star)
assert(saved.favorites[selectedRow.itemID] and detailFavorite.icon.atlas == "auctionhouse-icon-favorite")
assert(selectedRow.star.icon.atlas == detailFavorite.icon.atlas, "list and detail favorites refresh together")
detailFavorite.scripts.OnEnter(detailFavorite)
assert(GameTooltip:GetText() == "Remove from favorites")
detailFavorite.scripts.OnClick(detailFavorite)
assert(not saved.favorites[selectedRow.itemID] and selectedRow.star.icon.atlas == "auctionhouse-icon-favorite-off")
materialInput:SetText("sample")
assert(detailUses.slots[1].icon.texture == "Interface\\Icons\\Trade_Engineering")
materialInput:SetText("no matching material")
assert(not detailUses:IsShown() and not detailFavorite:IsShown(), "empty searches hide material actions and uses")
materialInput:SetText("")
Click("My inventory")
local bagInput
for _, frame in ipairs(frames) do
    if frame.list and frame.list.rows[1] and frame.list.rows[1].usedBy then bagInput = frame end
end
assert(bagInput, "inventory rows include profession uses")
assert(not bagInput.list.rows[1]:GetScript("OnEnter"), "inventory item names and quantities have no row tooltip")
local function ItemRow(list, id)
    for _, row in ipairs(list.rows) do if row.itemID == id and row:IsShown() then return row end end
end
local bagRows = bagInput.list
local function HiddenRow(id)
    for _, frame in ipairs(frames) do
        if frame.itemID == id and frame.sharing and not frame.usedBy and frame:IsShown() then return frame end
    end
end
local packetsBeforeHiding = #sent
local rawBeforeHiding = addon.snapshot
local shareCheck = ItemRow(bagRows, 10).sharing
assert(shareCheck.template == "UICheckButtonTemplate" and shareCheck:GetChecked())
shareCheck:SetChecked(false)
shareCheck.scripts.OnClick(shareCheck)
assert(addon.IsItemHidden(10) and ItemRow(bagRows, 10) and HiddenRow(10), "excluded items stay in the bag list and also appear on the right")
assert(ItemRow(bagRows, 10).count:GetText() == 5 and ItemRow(bagRows, 10).privateNote:IsShown())
assert(ItemRow(bagRows, 10).privateNote:GetText() == "Not shared with guild" and not shareCheck:GetChecked())
assert(ItemRow(bagRows, 10).border[4] == 0 and HiddenRow(10).border[4] == 0, "inventory rows have no separator borders")
assert(#addon.Materials("all") == 2 and #addon.Materials("favorites") == 1, "hiding does not remove catalog or favorites")
assert(addon.snapshot == rawBeforeHiding and not addon.ShareableSnapshot().items[10])
local hiddenRow = HiddenRow(10)
assert(hiddenRow.sharing.template == "UIPanelButtonTemplate" and hiddenRow.sharing:GetText() == "Share", "restore uses a native Blizzard button")
assert(math.abs((bagRows.width + 24) / (hiddenRow.parent.width + 24) - 7 / 3) < 0.001, "inventory panes use the requested 70/30 split")
bagInput:SetText("no matching material")
assert(HiddenRow(10), "bag search cannot conceal privacy preferences")
hiddenRow.sharing.scripts.OnClick(hiddenRow.sharing)
assert(not addon.IsItemHidden(10) and not HiddenRow(10) and addon.ShareableSnapshot().items[10].count == 5)
assert(not ItemRow(bagRows, 10), "restoring sharing respects the current bag search")
bagInput:SetText("")
assert(ItemRow(bagRows, 10).sharing:GetChecked() and not ItemRow(bagRows, 10).privateNote:IsShown(), "restoring sharing clears the row indicator")
local otherCheck = ItemRow(bagRows, 20).sharing
otherCheck:SetChecked(false)
otherCheck.scripts.OnClick(otherCheck)
assert(HiddenRow(20).label:GetText() == "Item #20", "unloaded hidden items have an ID placeholder")
bags[0] = {}
bags[5] = {}
addon.Observe()
assert(HiddenRow(20) and saved.hiddenItems[20], "an absent item stays hidden until explicitly restored")
addon.db, addon.snapshot = nil, nil
addon.Initialize()
assert(saved.hiddenItems[20] and #addon.HiddenItems() == 1, "initialization preserves absent hidden items")
bags[0] = {Item(10, 5, false), Item(20, 2, true)}
addon.Observe()
assert(not addon.ShareableSnapshot().items[20] and ItemRow(bagRows, 20).privateNote:IsShown(), "reacquired items stay visible and excluded")
otherCheck = ItemRow(bagRows, 20).sharing
otherCheck:SetChecked(true)
otherCheck.scripts.OnClick(otherCheck)
assert(not HiddenRow(20) and not ItemRow(bagRows, 20).privateNote:IsShown(), "the checkbox can also restore sharing")
assert(ItemRow(bagRows, 20).count:GetText() == 2 and addon.ShareableSnapshot().items[20].bound == 2)
assert(#sent == packetsBeforeHiding, "privacy actions and observations do not activate the probe transport")
local materialUses = addon.Catalog()[10]
materialUses.Cooking, materialUses.FirstAid = true, true
materialUses.Alchemy, materialUses.Unknown = secret, true
addon.Refresh()
local ownUses = ItemRow(bagInput.list, 10).usedBy
assert(#ownUses.slots == 3 and not ownUses.unknown:IsShown(), "all known uses include secondary professions and omit inaccessible/unknown keys")
assert(not ownUses:GetScript("OnEnter"), "Used by has no combined profession tooltip")
ownUses.slots[3].scripts.OnEnter(ownUses.slots[3])
assert(GameTooltip:GetText() == "First Aid", "each icon identifies its profession")
ownUses.slots[3].scripts.OnLeave(ownUses.slots[3])
assert(not GameTooltip:IsShown(), "leaving a profession icon hides its tooltip")
local allUses = {}
for _, profession in ipairs(addon.professions) do allUses[profession[1]] = true end
addon.db.catalog[10] = allUses
addon.Refresh()
assert(#ownUses.slots == #addon.professions, "material uses are not limited to two primary professions")
local lastOwnUse = ownUses.slots[#addon.professions]
assert(lastOwnUse.point[2] + lastOwnUse.width <= ownUses.width, "all profession icons fit beside the sharing checkbox")
for _, slot in ipairs(ownUses.slots) do
    assert(slot.width == 24 and slot.icon.width == 20, "profession icons retain their original size")
    local top = ownUses.point[3] + slot.point[3]
    assert(top <= 0 and top - slot.height >= -55, "wrapped professions fit inside their inventory row")
end
addon.db.catalog[10] = materialUses
addon.Refresh()
assert(not ownUses.slots[4]:IsShown(), "reused rows hide obsolete profession icons")
assert(ownUses.slots[1].point[3] == 0, "short profession lists recenter after a wrapped row is reused")
Click("Materials")
materialInput:SetText("sample")
assert(detailUses:IsShown() and #detailUses.slots == 3 and not detailUses.unknown:IsShown())
assert(not detailUses:GetScript("OnEnter"), "material details have no combined profession tooltip")
detailUses.slots[3].scripts.OnEnter(detailUses.slots[3])
assert(GameTooltip:GetText() == "First Aid")
addon.db.catalog[10] = allUses
addon.Refresh()
local lastDetailUse = detailUses.slots[#addon.professions]
assert(lastDetailUse.point[2] + lastDetailUse.width <= detailUses.width, "all consuming professions fit under the material name")
addon.db.catalog[10] = {}
addon.Refresh()
assert(detailUses.unknown:IsShown() and not detailUses.slots[1]:IsShown(), "unknown mappings remove stale detail icons")
assert(not detailUses:GetScript("OnEnter"), "unknown uses do not add a cell tooltip")
addon.db.catalog[10] = materialUses
materialInput:SetText("")
materialInput.list.rows[1].scripts.OnClick(materialInput.list.rows[1])
assert(not detailUses.slots[2]:IsShown(), "switching materials removes obsolete detail icons")
Click("My inventory")
local queries = 0
C_Item.GetItemInfo = function() queries = queries + 1; return "Loaded item" end
Event("GET_ITEM_INFO_RECEIVED", 20, false)
addon.Refresh()
assert(queries == 0, "failed item loads are not requested in a refresh loop")
Event("GET_ITEM_INFO_RECEIVED", 20, true)
Drain()
assert(queries == 1 and addon.itemData[20].name == "Loaded item", "async names replace item-ID placeholders")
local charactersTab = Click("Characters")
local ownBefore = addon.snapshot
assert(#addon.GuildCharacters() == 0, "no roster-only or mock participants")
local sharedAlpha = {items = {[20] = {count = 7, bound = 0}, [30] = {count = 3, bound = 0}}, observedAt = epoch - 10}
local sharedBeta = {items = {[10] = {count = 99, bound = 1}}, observedAt = epoch - 20}
addon.guildData = {guildID = club, characters = {
    alpha = {name = "Alpha [Example]", snapshot = sharedAlpha},
    beta = {name = "Beta Example", snapshot = sharedBeta},
    empty = {name = "Empty Example", snapshot = {items = {}, observedAt = epoch}},
    incomplete = {name = "Incomplete Example"},
    invalid = {name = "Invalid Example", snapshot = {items = {[10] = {count = -1, bound = 0}}, observedAt = epoch}},
}}
assert(#addon.GuildCharacters() == 3, "only complete observations, including confirmed empty inventories")
assert(addon.GuildCharacters("[")[1].id == "alpha", "literal character search")
assert(#addon.GuildCharacters("missing") == 0)
local known = addon.GuildCharacters()
local sharedItems = addon.CharacterItems(known[1])
assert(#sharedItems == 2 and sharedItems[1].id == 20 and sharedItems[1].count == 7)
assert(sharedItems[2].id == 30 and not addon.Catalog()[30], "peer items need not be discovered locally")
addon.Refresh()
local characterInput, peerItemInput
for _, frame in ipairs(frames) do
    if frame.list and frame.list.rows[1] then
        if frame.list.rows[1].characterID then characterInput = frame end
        if frame.list.rows[2] and frame.list.rows[2].itemID == 30 then peerItemInput = frame end
    end
end
assert(characterInput and peerItemInput, "both searchable character panes are active")
local peerRows = peerItemInput.list.rows
assert(peerRows[1].count:GetText() == 7 and peerRows[2].count:GetText() == 3)
assert(not peerRows[1].sharing, "only My inventory has privacy controls")
assert(peerRows[1].usedBy.slots[1].icon.texture == "Interface\\Icons\\INV_Misc_Food_15")
assert(peerRows[2].usedBy.unknown:IsShown(), "a peer-only item does not invent profession uses")
assert(not peerRows[2].usedBy:GetScript("OnEnter"), "unknown peer uses have no cell tooltip")
assert(not peerRows[1]:GetScript("OnEnter") and not peerRows[2]:GetScript("OnEnter"), "character inventories have no row tooltips")
Click("Beta Example")
assert(peerRows[1].itemID == 10 and peerRows[1].count:GetText() == 99 and not peerRows[2]:IsShown())
assert(peerRows[1].usedBy.slots[3]:IsShown(), "character inventories use the same material-to-profession mapping")
addon.db.catalog[10] = allUses
addon.Refresh()
local lastProfession = peerRows[1].usedBy.slots[#addon.professions]
assert(lastProfession.point[2] + lastProfession.width <= peerRows[1].usedBy.width, "all supported icons fit the narrower character inventory")
addon.db.catalog[10] = materialUses
characterInput:SetText("[")
assert(peerRows[1].count:GetText() == 7, "filtering selects an available character instead of keeping stale details")
assert(not peerRows[1].usedBy.slots[2]:IsShown(), "switching characters clears the previous material's extra uses")
peerRows[1].usedBy.slots[1].scripts.OnEnter(peerRows[1].usedBy.slots[1])
assert(GameTooltip:GetText() == "Cooking", "reused icons refresh their tooltip")
peerItemInput:SetText("[")
assert(not peerRows[1]:IsShown() and peerItemInput.list.empty:IsShown(), "item search is literal too")
peerItemInput:SetText("")
characterInput:SetText("")
assert(peerRows[1].count:GetText() == 7, "selection survives unrelated refreshes")
addon.guildData.characters.alpha = nil
addon.Refresh()
assert(peerRows[1].count:GetText() == 99, "removing the selection clears its old inventory")
Click("Empty Example")
assert(not peerRows[1]:IsShown() and peerItemInput.list.empty:GetText() == "No items recorded for this character.")
club = 456
Event("PLAYER_GUILD_UPDATE", "player")
assert(#addon.GuildCharacters() == 0 and not characterInput.list.rows[1]:IsShown())
assert(not peerRows[1]:IsShown() and peerItemInput.list.empty:GetText() == "Select a character to view their items.")
club = nil
assert(#addon.GuildCharacters() == 0, "no-guild state cannot expose cached peers")
club, addon.guildData = 123, nil
addon.Refresh()
assert(addon.snapshot == ownBefore and addon.db.own == ownBefore and saved.guildData == nil, "character browsing cannot overwrite own inventory or persist a new schema")
local materialsTab = Click("Materials")
local inventoryTab = Click("My inventory")
assert(materialsTab.point[2] < charactersTab.point[2] and charactersTab.point[2] < inventoryTab.point[2], "Characters follows Materials")
assert(inventoryTab.selection:IsShown() and not materialsTab.selection:IsShown()
    and not charactersTab.selection:IsShown(), "only the active tab keeps its selection marker")
Click("Materials")
Click("All materials")
Click("Favorites")
addon.ToggleFavorite(20)
assert(saved.favorites[20] and #addon.Materials("favorites") == 2)
addon.ToggleFavorite(20)
assert(saved.favorites[20] == nil and saved.favorites[10])
Click("Settings")
local checks = {}
for _, f in ipairs(frames) do if f.checked ~= nil and not f.parent.itemID then checks[#checks + 1] = f end end
assert(#checks == 2)
checks[2]:SetChecked(false)
checks[2].scripts.OnClick(checks[2])
assert(saved.settings.showMinimap == false and not GuildStockMinimapButton:IsShown())
checks[2]:SetChecked(true)
checks[2].scripts.OnClick(checks[2])
assert(GuildStockMinimapButton:IsShown())
-- Exercise the dropdown callbacks separately from the identically named navigation buttons.
local choices
for _, f in ipairs(frames) do
    if f.width == 271 and f.height == 73 then choices = f end
end
for _, f in ipairs(frames) do
    if f.width == 267 and f.label and f.label.text == "Favorites" then f.scripts.OnClick(f) end
end
assert(saved.settings.initialView == "favorites" and not choices:IsShown())
local settingsBefore = saved.settings
saved.settings = "preserve unsupported preferences"
checks[2]:SetChecked(false)
checks[2].scripts.OnClick(checks[2])
addon.Refresh()
assert(saved.settings == "preserve unsupported preferences" and addon.temporaryPreferences)
saved.settings = settingsBefore
addon.Refresh()
local slider
for _, f in ipairs(frames) do if f.scripts.OnValueChanged then slider = f end end
slider.scripts.OnValueChanged(slider, 0.9)
assert(saved.settings.scale == 0.9 and GuildStockFrame:GetScale() == 0.9)
-- Language selection is per character and takes effect on the next UI load.
local languageButton = Click("Automatic (game language)")
local languageOptions = {}
for _, frame in ipairs(frames) do if frame.language then languageOptions[frame.language] = frame end end
local languageMenu = languageOptions.enUS.parent
assert(languageMenu:IsShown())
for _, entry in ipairs(addon.languages) do
    local option = languageOptions[entry[1]]
    assert(option, "every language is selectable")
    assert(option.label.fontObject == "ChatFontNormal" and option.label.fontSize == 16 and not option.label.fontPath,
        "language names use the body font family at its intended size")
end
languageOptions.esES.scripts.OnClick()
assert(saved.settings.language == "esES" and languageButton.label:GetText() == "Español" and not languageMenu:IsShown())
assert(addon.L["Settings"] == "Settings" and GetLocale() == "enUS", "selection cannot change the game or partially relabel the UI")
assert(saved.settings.scale == 0.9 and saved.settings.initialView == "favorites", "other preferences are preserved")
languageButton.scripts.OnClick()
Click("Materials")
assert(not languageMenu:IsShown(), "changing tabs closes the language menu")
Click("Settings")
languageButton.scripts.OnClick()
languageOptions.auto.scripts.OnClick()
assert(saved.settings.language == nil and languageButton.label:GetText() == "Automatic (game language)")
saved.settings = "preserve unsupported preferences"
languageOptions.frFR.scripts.OnClick()
assert(saved.settings == "preserve unsupported preferences" and addon.temporaryPreferences)
saved.settings = settingsBefore
addon.Refresh()
assert(#sent == 5, "UI operations never send addon messages")
GuildStockMinimapButton.scripts.OnClick()
assert(not GuildStockFrame:IsShown())
GuildStockMinimapButton.scripts.OnDragStart(GuildStockMinimapButton)
GuildStockMinimapButton.scripts.OnUpdate(GuildStockMinimapButton)
assert(saved.minimapAngle == 0)
GuildStockMinimapButton:Hide()
assert(not GuildStockMinimapButton:GetScript("OnUpdate"))
-- Missing translations must not silently pass through the English fallback.
do
    local previousLocale, locales, keys = GetLocale, {}, {}
    local loadLocales = assert(loadfile("GuildStock/Locales.lua"))
    for _, locale in ipairs({"esES", "esMX", "frFR", "deDE", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW",
        "enUS", "enGB", "unknown"}) do
        GetLocale = function() return locale end
        local localized = {}
        loadLocales("GuildStock", localized)
        locales[locale] = localized.L
        for key in pairs(localized.L) do keys[key] = true end
    end
    GetLocale = previousLocale
    -- Include literal lookups so a new untranslated label fails even if absent from every table.
    for _, file in ipairs({"GuildStock", "Probe", "Catalog", "Sync", "UI"}) do
        local sourceFile = assert(io.open("GuildStock/" .. file .. ".lua", "r"))
        local source = sourceFile:read("*a")
        sourceFile:close()
        for key in source:gmatch('L%["(.-)"%]') do keys[key] = true end
    end
    local function Placeholders(text)
        local tokens = {}
        for token in text:gmatch("%%.") do tokens[#tokens + 1] = token end
        return table.concat(tokens)
    end
    for locale, L in pairs(locales) do
        local english = locale == "enUS" or locale == "enGB" or locale == "unknown"
        for key in pairs(keys) do
            local text = L[key]
            if english then
                assert(text == (key == "FirstAid" and "First Aid" or key), locale .. ": incorrect fallback for " .. key)
            else
                assert(type(rawget(L, key)) == "string" and text:find("%S"), locale .. ": missing " .. key)
            end
            assert(Placeholders(text) == Placeholders(key), locale .. ": format mismatch for " .. key)
            assert(pcall(string.format, text, "2026-10-03 12:34:56"), locale .. ": invalid format for " .. key)
            for command in key:gmatch("(/guildstock %a+)") do
                assert(text:find(command, 1, true), locale .. ": changed command " .. command)
            end
            if locale == "esMX" then assert(text == locales.esES[key], "Spanish variants must match") end
        end
        assert(L["Missing translation"] == "Missing translation", locale .. ": missing English fallback")
    end
    for locale, settingsLabel in pairs({esES = "Ajustes", esMX = "Ajustes", frFR = "Paramètres",
        deDE = "Einstellungen", itIT = "Impostazioni", ptBR = "Configurações", ruRU = "Настройки",
        koKR = "설정", zhCN = "设置", zhTW = "設定"}) do
        assert(locales[locale]["Settings"] == settingsLabel, locale .. ": wrong language selected")
    end
    assert(locales.esES["My inventory"] == "Mi inventario")
    assert(locales.esES["Skills"] == "Profesiones" and locales.esES["Characters"] == "Personajes")
    assert(locales.esES["Used by"] == "Usado por" and locales.esES["Fishing"] == "Pesca")
    assert(locales.esES["Not shared with guild"] == "No se comparte" and locales.esES["Share"] == "Compartir")
    assert(locales.esES["Not shared"] == "No compartidos")
    assert(locales.esES["My professions"] == "Mis profesiones" and locales.esES["Other professions"] == "Otras profesiones")
end

-- Alternate item names search the discovered catalog without replacing native data.
do
    local localeCount = 0
    for _, names in pairs(addon.itemNames) do
        localeCount = localeCount + 1
        local count = 0
        for id, name in pairs(names) do
            count = count + 1
            assert(type(id) == "number" and id > 0 and addon.itemNames.enUS[id])
            assert(type(name) == "string" and name:find("%S") and not name:find("[|\n\r]"))
        end
        assert(count == 579, "each locale must cover the same reagent subset")
    end
    assert(localeCount == 11, "include both Spanish item-name variants")
    local previousDB, previousSnapshot, previousData = addon.db, addon.snapshot, addon.itemData
    addon.db = {version = 1, catalog = {[2770] = {Mining = true}, [2589] = {Tailoring = true}, [300001] = {}},
        favorites = {[2770] = true}}
    addon.snapshot = {items = {[2770] = {count = 7}}}
    addon.itemData = {[2770] = {name = "Mineral de cobre", icon = 123}, [2589] = {name = "Paño de lino"},
        [300001] = {name = "New native material"}}
    addon.InvalidateMaterials()
    assert(#addon.Materials("all") == 3, "aliases must never populate the discovered catalog")
    for _, names in pairs(addon.itemNames) do
        local matches = addon.Materials("all", nil, names[2770])
        assert(#matches == 1 and matches[1].id == 2770 and matches[1].name == "Mineral de cobre")
        local bags = addon.Materials("all", nil, names[2770], true)
        assert(#bags == 1 and bags[1].count == 7)
        local character = addon.CharacterItems({snapshot = addon.snapshot}, names[2770])
        assert(#character == 1 and character[1].id == 2770 and character[1].name == "Mineral de cobre"
            and character[1].icon == 123 and character[1].count == 7)
    end
    for _, query in ipairs({"COPPER ORE", "MINERAL DE COBRE", "MINÉRIO", "МЕДНАЯ"}) do
        assert(addon.Materials("all", nil, query)[1].id == 2770, "case folding across supported alphabets")
    end
    assert(#addon.Materials("favorites", "Mining", "copper") == 1)
    assert(#addon.Materials("all", "Tailoring", "copper") == 0)
    assert(#addon.Materials("all", nil, "linen cloth", true) == 0, "search does not invent bag quantities")
    assert(addon.Materials("all", nil, "new native")[1].id == 300001, "uncatalogued names retain native search")
    assert(#addon.Materials("all", nil, "Copper.*") == 0 and #addon.Materials("all", nil, "[") == 0)
    addon.ApplyLanguage("zhCN")
    assert(addon.Materials("all", nil, "copper")[1].name == "Mineral de cobre", "UI locale does not change item data")
    addon.ApplyLanguage()
    addon.db, addon.snapshot, addon.itemData = previousDB, previousSnapshot, previousData
    addon.InvalidateMaterials()
end

-- Saved language overrides must load only from a supported character database.
do
    local function InitializeLanguage(savedData, clientLocale)
        local env = setmetatable({GuildStockDB = savedData, GetLocale = function() return clientLocale end,
            CreateFrame = Frame}, {__index = function(_, key) if key ~= "GuildStockDB" then return _G[key] end end})
        local localized = {}
        for _, file in ipairs({"Locales", "GuildStock"}) do
            setfenv(assert(loadfile("GuildStock/" .. file .. ".lua")), env)("GuildStock", localized)
        end
        local captured = localized.L
        localized.Initialize()
        assert(localized.L == captured, "initialization preserves the locale table used by every module")
        return localized, env
    end
    local data = {version = 1, own = old, settings = {language = "frFR", scale = 0.9}, favorites = {[10] = true}}
    local localized, env = InitializeLanguage(data, "enUS")
    assert(localized.L["Settings"] == "Paramètres" and localized.db == data and localized.snapshot == old)
    assert(data.settings.language == "frFR" and data.settings.scale == 0.9 and data.favorites[10])
    localized.ApplyLanguage("enUS")
    assert(localized.L["Settings"] == "Settings" and not rawget(localized.L, "Settings"), "returning to English clears old translations")
    localized, env = InitializeLanguage(nil, "esMX")
    assert(localized.L["Settings"] == "Ajustes" and env.GuildStockDB.version == 1)
    for _, value in ipairs({"auto", "unsupported", false, {}}) do
        data = {version = 1, settings = {language = value}}
        localized = InitializeLanguage(data, "deDE")
        assert(localized.L["Settings"] == "Einstellungen" and data.settings.language == value)
    end
    localized = InitializeLanguage({version = 1, settings = {language = "enGB"}}, "esES")
    assert(localized.L["Settings"] == "Settings")
    localized = InitializeLanguage({version = 1, settings = {language = "esMX"}}, "enUS")
    assert(localized.L["Settings"] == "Ajustes")
    data = {version = 1, settings = "preserve unsupported preferences"}
    localized = InitializeLanguage(data, "enUS")
    assert(localized.L["Settings"] == "Settings" and data.settings == "preserve unsupported preferences")
    data = {version = 99, settings = {language = "frFR"}, marker = "preserve"}
    localized, env = InitializeLanguage(data, "enUS")
    assert(localized.temporary and env.GuildStockDB == data and data.marker == "preserve")
    assert(localized.L["Settings"] == "Settings", "unsupported schemas cannot apply an unverified preference")
end

-- Large catalogs exercise bounded UI work, recycled actions and cache invalidation.
do
    local previousCatalog, previousSnapshot, previousFavorites = addon.db.catalog, addon.snapshot, addon.db.favorites
    addon.db.catalog, addon.db.favorites = {}, {}
    local items = {}
    for id = 1001, 6000 do
        addon.db.catalog[id] = {Mining = id % 2 == 0}
        addon.itemData[id] = {name = string.format("Material %06d", id), icon = id}
        items[id] = {count = id, bound = 0}
    end
    addon.snapshot = {items = items, observedAt = epoch}
    GuildStockFrame:Show()
    Click("Materials")
    Click("All materials")
    materialInput:SetText("")
    local list = materialInput.list
    assert(#list.entries == 5000 and #list.rows == 9, "only viewport rows plus one buffer are allocated")
    local allocated = #frames
    local firstRow = list.rows[1]
    local selectionMarker = firstRow.selection
    assert(selectionMarker:IsShown(), "the selected material has a visible marker")
    list.scroll.ScrollBar:SetValue(5500)
    assert(list.rows[1] == firstRow and firstRow.itemID == 1101 and firstRow.point[3] == -5500)
    assert(firstRow.selection == selectionMarker and not selectionMarker:IsShown(), "recycling clears the previous item's marker")
    assert(firstRow.background[4] == 0, "recycling a selected row restores the panel background")
    assert(#frames == allocated and #list.rows == 9, "scrolling reuses frames")
    list.scroll.ScrollBar:SetValue(5527)
    assert(firstRow.itemID == 1101, "partial-row scrolling keeps the correct first entry")
    local refreshes, queries = 0, 0
    local refresh, materials = addon.Refresh, addon.Materials
    addon.Refresh = function(...) refreshes = refreshes + 1; return refresh(...) end
    addon.Materials = function(...) queries = queries + 1; return materials(...) end
    firstRow.scripts.OnClick(firstRow)
    assert(selectionMarker:IsShown() and not list.rows[2].selection:IsShown(), "clicking a recycled row marks its current item")
    assert(firstRow.background[4] == 1 and list.rows[2].background[4] == 0, "only the selected row has its own fill")
    assert(refreshes == 0 and queries == 0, "selection updates detail without rebuilding the list")
    firstRow.star.scripts.OnClick(firstRow.star)
    assert(addon.db.favorites[1101] and not addon.db.favorites[1001], "recycled favorite targets its displayed item")
    local stable = addon.Materials("all")
    assert(stable == addon.Materials("all"), "unchanged views reuse filtered results")
    local mining = addon.Materials("all", "Mining")
    assert(#mining == 2500 and mining == addon.Materials("all", "Mining"))
    refreshes, queries = 0, 0
    Click("All materials")
    assert(refreshes == 0 and queries == 0, "repeating the selected filter does no work")
    Click("Mining")
    assert(list.entries == mining and list.scroll:GetVerticalScroll() == 0)
    Click("All materials")
    assert(list.entries == stable, "returning to All materials reuses its results")
    list.scroll.ScrollBar:SetValue(list.scroll:GetVerticalScrollRange())
    assert(list.rows[8].itemID == 6000 and list.rows[8]:IsShown() and not list.rows[9]:IsShown(), "final row remains reachable")
    assert(list.rows[7].separator:IsShown() and not list.rows[8].separator:IsShown(), "separators stop before the final material")
    materialInput:SetText("Material 001001")
    assert(list.scroll:GetVerticalScroll() == 0 and #list.entries == 1 and not list.rows[2]:IsShown())
    assert(not firstRow.separator:IsShown(), "a single search result has no trailing separator")
    materialInput:SetText("missing")
    assert(list.empty:IsShown() and not list.rows[1]:IsShown() and list.scroll:GetVerticalScrollRange() == 0)
    materialInput:SetText("")
    assert(firstRow.separator:IsShown(), "clearing search restores the recycled row separator")
    Drain()
    refreshes = 0
    for id = 200001, 200100 do Event("GET_ITEM_INFO_RECEIVED", id, true) end
    Drain()
    assert(refreshes == 0, "unrelated item events cause no refresh")
    local itemAPI = C_Item.GetItemInfo
    C_Item.GetItemInfo = function(id) return "AAA loaded " .. id end
    for id = 1001, 1100 do Event("GET_ITEM_INFO_RECEIVED", id, true) end
    assert(refreshes == 0 and #timers == 1, "relevant item-event bursts queue one refresh")
    Drain()
    assert(refreshes == 1 and list.rows[1].label:GetText():match("^AAA loaded"), "resolved names invalidate ordering and filters")
    assert(addon.Materials("all", nil, "AAA loaded")[100], "search sees newly loaded names")
    C_Item.GetItemInfo = itemAPI
    refreshes = 0
    for _, text in ipairs({"Mat", "Material 006", "Material 006000"}) do
        materialInput.text = text
        materialInput.scripts.OnTextChanged(materialInput, true)
    end
    addon.Refresh() -- unrelated events must not apply an unfinished query
    assert(#list.entries == 5000)
    refreshes = 0
    Drain()
    assert(refreshes == 1 and #list.entries == 1 and list.rows[1].itemID == 6000, "only the latest typed search runs")
    materialInput.text = "stale query"
    materialInput.scripts.OnTextChanged(materialInput, true)
    materialInput:SetText("")
    Drain()
    assert(#list.entries == 5000, "clearing search cancels its pending query")
    local beforeDiscovery = addon.Materials("all", "Cooking")
    addon.DiscoverRecipes()
    assert(addon.Materials("all", "Cooking") ~= beforeDiscovery and #addon.Materials("all", "Cooking") > 0, "new recipe associations invalidate filters")
    local beforeBags = addon.Materials("all", nil, "", true)
    addon.snapshot = {items = {[6000] = {count = 42, bound = 0}}, observedAt = epoch}
    local afterBags = addon.Materials("all", nil, "", true)
    assert(afterBags ~= beforeBags and #afterBags == 1 and afterBags[1].count == 42, "new observations replace cached quantities")
    addon.snapshot = {items = {}, observedAt = epoch}
    assert(#addon.Materials("all", nil, "", true) == 0, "confirmed empty bags clear the inventory view")
    addon.snapshot = {items = items, observedAt = epoch}
    Click("My inventory")
    assert(#bagInput.list.rows == 7, "inventory shares the bounded renderer")
    bagInput.list.scroll.ScrollBar:SetValue(5500)
    local recycled = bagInput.list.rows[1]
    local target = recycled.itemID
    recycled.sharing:SetChecked(false)
    recycled.sharing.scripts.OnClick(recycled.sharing)
    assert(addon.IsItemHidden(target) and recycled.privateNote:IsShown(), "recycled sharing control uses the current item")
    recycled.sharing:SetChecked(true)
    recycled.sharing.scripts.OnClick(recycled.sharing)
    addon.Refresh, addon.Materials = refresh, materials
    addon.db.catalog, addon.snapshot, addon.db.favorites = previousCatalog, previousSnapshot, previousFavorites
    addon.InvalidateMaterials()
    GuildStockFrame:Hide()
end

-- The profession window loads on demand; attaching must wait for it and for combat to end.
assert(not GuildStockProfessionsButton, "login must not require or load the profession window")
ProfessionsFrame = Frame()
ProfessionsFrame.ProfessionsOverviewTab = Frame()
local nativeTabs = {Frame(), Frame()}
ProfessionsFrame.rightProfessionTabs = nativeTabs
combat = true
Event("ADDON_LOADED", "Blizzard_Professions")
assert(not GuildStockProfessionsButton, "no native-window attachment during combat")
combat = false
Event("PLAYER_REGEN_ENABLED")
local shortcut = GuildStockProfessionsButton
assert(shortcut and shortcut.parent == ProfessionsFrame and shortcut.template == "LargeSideTabButtonTemplate")
assert(shortcut.point[1] == "BOTTOMLEFT" and shortcut.point[2] == ProfessionsFrame
    and shortcut.point[3] == "BOTTOMRIGHT" and shortcut.point[4] == 0 and shortcut.point[5] == 4,
    "shortcut stays at the foot of the right-hand tabs instead of following the last profession")
assert(shortcut.Icon.texture == "Interface\\Icons\\INV_Crate_01" and shortcut.fillToInterior)
assert(not shortcut:GetChecked() and shortcut.tooltipText == "GuildStock")
assert(ProfessionsFrame.rightProfessionTabs == nativeTabs and #nativeTabs == 2, "native tabs stay untouched")
GuildStockFrame:Hide()
local traffic = #sent
shortcut.customMouseUpHandler(shortcut, "RightButton", true)
shortcut.customMouseUpHandler(shortcut, "LeftButton", false)
assert(not GuildStockFrame:IsShown(), "only a left click released inside activates the shortcut")
shortcut.customMouseUpHandler(shortcut, "LeftButton", true)
assert(GuildStockFrame:IsShown() and ProfessionsFrame:IsShown(), "shortcut opens GuildStock and preserves professions")
shortcut.customMouseUpHandler(shortcut, "LeftButton", true)
assert(not GuildStockFrame:IsShown() and #sent == traffic, "second click closes without sending messages")
GameTooltip:SetOwner(shortcut); GameTooltip:Show()
shortcut:Hide()
assert(not GameTooltip:IsShown(), "hiding the shortcut dismisses its tooltip")
GameTooltip:SetOwner(ProfessionsFrame); GameTooltip:Show()
shortcut:Hide()
assert(GameTooltip:IsShown(), "unrelated tooltips stay untouched")
GameTooltip:Hide()
local frameCount = #frames
Event("ADDON_LOADED", "Blizzard_Professions")
Event("PLAYER_REGEN_ENABLED")
assert(#frames == frameCount and GuildStockProfessionsButton == shortcut, "later events do not duplicate the shortcut")

-- Recipe shortcuts follow pooled native rows and select exact IDs, including zero-stock discoveries.
do
    local form, first, second = Frame(), Frame(), Frame()
    ProfessionsFrame.CraftingPage = {SchematicForm = form}
    first.Button, second.Button = Frame(), Frame()
    first.Name, second.Name = Frame(), Frame()
    first.Name:SetWidth(108); second.Name:SetWidth(108)
    first.schematic = {reagentType = 1, reagents = {{itemID = 10}}}
    second.schematic = {reagentType = 1, reagents = {{itemID = 20}}}
    first.GetReagentSlotSchematic = function(self) return self.schematic end
    second.GetReagentSlotSchematic = first.GetReagentSlotSchematic
    local active = {first, second}
    form.reagentSlotPool = {EnumerateActive = function()
        local index = 0
        return function() index = index + 1; return active[index] end
    end}
    form.Init = function(self, recipe)
        self.currentRecipeInfo = recipe
        self.reagentSlots = {[1] = active}
        self.nativeCalls = (self.nativeCalls or 0) + 1
    end
    form:Init({recipeID = 1})
    local function Badge(slot)
        for _, frame in ipairs(frames) do
            if frame.parent == slot and frame.scripts.OnClick then return frame end
        end
    end
    combat = true; Event("ADDON_LOADED", "Blizzard_Professions")
    assert(not Badge(first), "recipe attachment waits for combat to end")
    combat = false; Event("PLAYER_REGEN_ENABLED")
    local a, b = Badge(first), Badge(second)
    assert(a and b and a:IsShown() and b:IsShown())
    assert(a.point[1] == "LEFT" and a.point[2] == first.Name and a.point[3] == "RIGHT" and a.width == 24,
        "buttons sit to the right of the material text, clear of the item icon")
    assert(first.Name:GetWidth() == 108, "single-column recipes retain the full native name width")
    local allocated = #frames
    Event("ADDON_LOADED", "Blizzard_Professions"); Event("PLAYER_REGEN_ENABLED")
    form:Init({recipeID = 2})
    assert(#frames == allocated and form.nativeCalls == 2, "native initialization survives; badges are reused")
    for i = 3, 5 do
        local slot = Frame()
        slot.Name = Frame(); slot.Name:SetWidth(108)
        slot.schematic = {reagentType = 1, reagents = {{itemID = 10}}}
        slot.GetReagentSlotSchematic = first.GetReagentSlotSchematic
        active[i] = slot
    end
    form:Init({recipeID = 2})
    assert(first.Name:GetWidth() == 78 and active[5].Name:GetWidth() == 78,
        "two columns reserve button space inside both native rows")
    a.scripts.OnEnter(a)
    assert(GameTooltip:GetText() == "Find this material in GuildStock")
    active = {first}; form:Init({recipeID = 3})
    assert(not b:IsShown() and not GameTooltip:IsShown(), "released slots and their tooltips are cleared")
    assert(second.Name:GetWidth() == 108 and first.Name:GetWidth() == 108, "fewer materials restore full native label widths")

    local originalGuild = addon.guildData
    local unknownID = 987650
    addon.itemData[unknownID] = {name = addon.ItemData(10).name}
    first.schematic.reagents[1].itemID = unknownID
    form:Init({recipeID = 4})
    addon.guildData = {guildID = club, characters = {example = {name = "Example Crafter",
        snapshot = {observedAt = epoch, items = {[unknownID] = {count = 12, bound = 0}}}}}}
    Click("Materials"); Click("Favorites"); Click("Cooking")
    materialInput.text = "old pending query"
    materialInput.scripts.OnTextChanged(materialInput, true)
    Click("Settings"); GuildStockFrame:Hide()
    a.scripts.OnClick(a)
    assert(GuildStockFrame:IsShown() and ProfessionsFrame:IsShown())
    assert(materialInput:GetText() == addon.ItemData(unknownID).name)
    assert(#materialInput.list.entries == 1 and materialInput.list.entries[1].id == unknownID,
        "an uncatalogued zero-stock reagent opens by exact ID despite namesakes and previous filters")
    assert(addon.Catalog()[unknownID] == nil and not addon.snapshot.items[unknownID], "opening does not invent catalog or stock")
    local owner
    for _, frame in ipairs(frames) do
        if frame.whisper and frame.whisper.characterID == "example" then owner = frame end
    end
    assert(owner and owner:IsShown() and owner.count:GetText() == 12, "owners use the exact selected ID")
    Drain()
    assert(#materialInput.list.entries == 1 and materialInput.list.entries[1].id == unknownID,
        "pending text callbacks cannot replace the recipe target")
    a.scripts.OnClick(a)
    assert(GuildStockFrame:IsShown(), "repeated clicks open instead of toggling closed")
    addon.itemData[unknownID] = false
    a.scripts.OnClick(a)
    assert(materialInput.list.rows[1].label:GetText() == "Item #" .. unknownID)
    local getInfo = C_Item.GetItemInfo
    C_Item.GetItemInfo = function(id) if id == unknownID then return "Loaded recipe material" else return getInfo(id) end end
    Event("GET_ITEM_INFO_RECEIVED", unknownID, true); Drain()
    assert(#materialInput.list.entries == 1 and materialInput.list.rows[1].label:GetText() == "Loaded recipe material"
        and owner.count:GetText() == 12, "delayed names preserve exact selection and owner counts")
    C_Item.GetItemInfo = getInfo
    second.schematic.reagents[1].itemID = 20
    active = {second}; form:Init({recipeID = 5}); b.scripts.OnClick(b)
    assert(#materialInput.list.entries == 1 and materialInput.list.entries[1].id == 20 and not owner:IsShown(),
        "another reagent replaces the selected item and owner rows")
    materialInput:SetText("")
    assert(#materialInput.list.entries > 1, "clearing restores normal material browsing")
    b.scripts.OnClick(b); Click("All materials")
    assert(materialInput:GetText() == "" and #materialInput.list.entries > 1, "navigation clears the exact target")
    b.scripts.OnClick(b); materialInput:SetText("no matching material")
    assert(#materialInput.list.entries == 0, "editing returns to ordinary name search")
    GuildStockFrame:Hide()
    for _, schematic in ipairs({secret, {reagentType = secret}, {reagentType = 2, reagents = {{itemID = 20}}},
        {reagentType = 1, reagents = secret}, {reagentType = 1, reagents = {secret}},
        {reagentType = 1, reagents = {{itemID = secret}}}, {reagentType = 1, reagents = {{currencyID = 2}}},
        {reagentType = 1, reagents = {{itemID = 10}, {itemID = 20}}}}) do
        second.schematic = schematic; form:Init({recipeID = 6})
        assert(not b:IsShown(), "unsupported, ambiguous or inaccessible reagents have no button")
        b.scripts.OnClick(b)
        assert(not GuildStockFrame:IsShown(), "click rechecks the current reagent")
    end
    second.schematic = {reagentType = 1, reagents = {{itemID = 20}}}
    combat = true; form:Init({recipeID = 7}); b.scripts.OnClick(b)
    assert(not b:IsShown() and not GuildStockFrame:IsShown(), "combat defers attachment and prevents activation")
    combat = false; Event("PLAYER_REGEN_ENABLED")
    assert(b:IsShown(), "combat recovery updates the current recipe")
    form:Init(nil)
    assert(not a:IsShown() and not b:IsShown(), "empty recipe selection hides every badge")
    assert(first.Name:GetWidth() == 108 and second.Name:GetWidth() == 108, "empty selection restores native label widths")
    for _, invalid in ipairs({secret, -1, 0, 1.5, "20"}) do addon.OpenMaterial(invalid) end
    assert(not GuildStockFrame:IsShown(), "invalid targets do not open the browser")
    addon.guildData = originalGuild
    addon.itemData[unknownID] = nil
    materialInput:SetText("")
end

-- Received inventory populates the material owner table with real counts and dated presence.
GuildStockFrame:Show()
Click("Materials"); Click("All materials"); Click("All professions")
materialInput:SetText("")
local materialRow = materialInput.list.rows[1]
local materialID = materialRow.itemID
local peerOnline, peerRace = true, 7
addon.SyncMember = function(id) if id == "Peer Fullname" then return {online = peerOnline, offline = not peerOnline, isSelf = false, race = peerRace} end end
addon.guildData = {guildID = club, characters = {["Peer Fullname"] = {name = "Peer Fullname",
    skills = {"Alchemy", "Mining"}, snapshot = {observedAt = epoch - 30, items = {[materialID] = {count = 17, bound = 2}}}}}}
materialRow.scripts.OnClick(materialRow); addon.Refresh()
local owner
for _, frame in ipairs(frames) do if frame.whisper and frame.whisper.characterID == "Peer Fullname" then owner = frame end end
assert(owner and owner:IsShown() and owner.count:GetText() == 17 and owner.presence:GetText() == "Online")
assert(owner.whisper.enabled and owner.skillSlots[1].icon:IsShown())
assert(owner.raceIcon.atlas == "raceicon128-gnome-male", "material owners use the roster race")
Click("Characters")
local characterRow = characterInput.list.rows[1]
assert(characterRow.raceIcon.atlas == owner.raceIcon.atlas, "both player lists use the same race")
peerRace = nil; addon.Refresh()
assert(characterRow.raceIcon.atlas == nil, "missing roster race clears the previous character badge")
Click("Materials")
assert(owner.raceIcon.atlas == nil, "missing roster race also clears the owner badge")
-- Age reflects the last complete receipt, updates while hovered and follows the cursor.
local seen=owner.nameArea
local record=addon.guildData.characters["Peer Fullname"]
assert(not owner.scripts.OnEnter, "only the player cell owns the observation tooltip")
for _,case in ipairs({{0,"0 seconds"},{1,"1 second"},{59,"59 seconds"},{60,"1 minute"},
    {3599,"59 minutes"},{3600,"1 hour"},{7200,"2 hours"}}) do
    record.receivedAt=epoch-case[1]
    addon.Refresh();seen.scripts.OnEnter(seen)
    assert(GameTooltip.anchor=="ANCHOR_CURSOR" and GameTooltip:IsOwned(seen))
    assert(GameTooltip:GetText()=="Peer Fullname\nSeen "..case[2].." ago")
    seen.scripts.OnLeave(seen)
    assert(not GameTooltip:IsShown() and not seen.scripts.OnUpdate)
end
record.receivedAt=epoch-59;addon.Refresh();seen.scripts.OnEnter(seen)
epoch=epoch+1;seen.scripts.OnUpdate(seen,1)
assert(GameTooltip:GetText()=="Peer Fullname\nSeen 1 minute ago")
seen.scripts.OnHide(seen);assert(not GameTooltip:IsShown() and not seen.scripts.OnUpdate)
addon.ApplyLanguage("esES");seen.scripts.OnEnter(seen)
assert(GameTooltip:GetText()=="Peer Fullname\nVisto hace 1 minuto")
addon.ApplyLanguage("enUS");seen.scripts.OnLeave(seen)

local draft
ChatFrameUtil = {SendTell = function(name) draft = name end}
owner.whisper.scripts.OnClick(owner.whisper); assert(draft == "Peer Fullname")
peerOnline, draft = false, nil
owner.whisper.scripts.OnClick(owner.whisper); assert(draft == nil, "click rechecks current presence")
addon.Refresh(); assert(owner.presence:GetText() == "Unknown" and not owner.whisper.enabled)
saved.settings.showOffline = false; addon.Refresh(); assert(not owner:IsShown())
saved.settings.showOffline = true
addon.guildData.characters["Peer Fullname"].snapshot.items = {}; addon.Refresh()
assert(not owner:IsShown(), "complete empty replacements remove old owner quantities")
addon.SyncMember, addon.guildData, ChatFrameUtil = nil, nil, nil

-- A separate UI load covers Blizzard_Professions already being present at login.
GuildStockProfessionsButton = nil
assert(loadfile("GuildStock/UI.lua"))("GuildStock", addon)
Event("ADDON_LOADED", "UnrelatedAddon")
assert(not GuildStockProfessionsButton)
Event("PLAYER_LOGIN")
assert(GuildStockProfessionsButton and GuildStockProfessionsButton.parent == ProfessionsFrame,
    "already-loaded profession UI also receives the shortcut")

print("GuildStock: bag observations, saved data, probes, catalog and interface checks OK")
