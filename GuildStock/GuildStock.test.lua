-- Run from the repository root with Lua 5.1 or LuaJIT. No client or saved files are accessed.
local clock, epoch, combat = 100, 1800000000, false
GetTime = function() return clock end
time = function() return epoch end
date = function(_, value) return tostring(value) end
InCombatLockdown = function() return combat end
GetLocale = function() return "enUS" end
local secret = setmetatable({}, { __tostring = function() error("secret used") end })
canaccessvalue = function(value) return value ~= secret end
local timers, frames = {}, {}
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
    "SetFont", "SetFontObject", "SetTextColor", "SetTexCoord", "SetVertexColor", "SetWordWrap", "SetAutoFocus",
    "SetMaxLetters", "ClearFocus", "SetOrientation", "SetMinMaxValues", "SetValueStep", "SetObeyStepOnDrag",
    "SetThumbTexture", "SetDesaturated", "SetAlpha" }) do
    methods[method] = function() end
end
function methods:SetScript(event, fn) self.scripts[event] = fn end
function methods:GetScript(event) return self.scripts[event] end
function methods:RegisterEvent(event) self.events[event] = true end
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
function methods:SetChecked(value) self.checked = value end
function methods:GetChecked() return self.checked end
function methods:SetHeight(value) self.height = value end
function methods:GetStringHeight() return #(self.text or "") end
function methods:GetFrameLevel() return 1 end
function methods:GetWidth() return self.width or 160 end
function methods:GetHeight() return self.height or 160 end
function methods:GetEffectiveScale() return 1 end
function methods:GetCenter() return 100, 100 end
function methods:GetValue() return self.value or 0 end
function methods:SetValue(value) self.value = value end
function methods:GetVerticalScrollRange() return 10000 end
function methods:IsShown() return self.shown end
function methods:SetShown(value)
    self.shown = value
    local fn = self.scripts[value and "OnShow" or "OnHide"]
    if fn then fn(self) end
end
function methods:Hide() self:SetShown(false) end
function methods:Show() self:SetShown(true) end
local function Frame() return setmetatable({scripts = {}, events = {}, shown = true}, {__index = methods}) end
methods.CreateTexture, methods.CreateFontString, methods.GetHighlightTexture, methods.GetThumbTexture = Frame, Frame, Frame, Frame
CreateFrame = function(_, name)
    local f = Frame()
    f.TitleText, f.ScrollBar = Frame(), Frame()
    frames[#frames + 1] = f
    if name then _G[name] = f end
    return f
end
UIParent, Minimap, GameTooltip = Frame(), Frame(), Frame()
UIParent:SetSize(1920, 1080)
STANDARD_TEXT_FONT = "Fonts/example.ttf"
methods.SetOwner, methods.AddLine = function() end, function() end
GetCursorPosition = function() return 150, 100 end
GetBuildInfo = function() return "1.60.1", "70205", "", 16001 end
UISpecialFrames, SlashCmdList = {}, {}
Constants = { InventoryConstants = { NumBagSlots = 4, NumReagentBagSlots = 1 } }
Enum = {
    Profession = {Engineering = 2, Cooking = 4},
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
    GetProfessionInfoByRecipeID = function(id) return {profession = id == 1 and 2 or 4} end,
    GetRecipeSchematic = function(id)
        return {reagentSlotSchematics = {{reagents = {{itemID = id == 1 and 10 or 20}}}}}
    end,
}
local sent, restriction, sendResult, registerResult, club = {}, false, 0, 0, 123
local members = {
    {name = "Self Example", isSelf = true, presence = 1},
    {name = "Peer Example", isSelf = false, presence = 1},
}
C_ChatInfo = {
    RegisterAddonMessagePrefix = function() return registerResult end,
    AreOutgoingAddonChatMessagesRestricted = function() return restriction end,
    SendAddonMessage = function(prefix, message, channel, target)
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
for _, file in ipairs({ "Locales", "GuildStock", "Probe", "Catalog", "UI" }) do
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
assert(addon.ProfessionNames() == "Engineering, Cooking", "secondary professions survive nil holes")

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
end
GuildStockDB, addon.db, addon.snapshot, addon.temporary = saved, nil, nil, nil
addon.Initialize()
assert(addon.db == saved and addon.snapshot == saved.own)

-- Native result enums are numeric, including zero for success.
assert(addon.probe.registration == "Success")
registerResult = 1
addon.RegisterProbe()
assert(addon.probe.registration == "DuplicatePrefix")
restriction = true
assert(addon.StartProbe() == addon.L["Probe unavailable: check Settings and /guildstock diagnostics."] and #sent == 0)
restriction = secret
addon.StartProbe()
assert(#sent == 0)
restriction, club = false, nil
addon.StartProbe()
assert(#sent == 0)
club = 123
addon.StartProbe()
assert(#sent == 1 and sent[1][3] == "GUILD" and addon.probe.GUILD == "Success")
local token = sent[1][2]:match("^1|P|(.+)$")
local function Receive(message, channel, sender)
    addon.ReceiveProbe("GuildStockP0", message, channel or "GUILD", sender or "Peer Example")
end
Receive("1|P|" .. token, "GUILD", "Self Example")
assert(#sent == 1, "self echo never proves delivery")
Receive("1|P|101-20", "GUILD", "Unknown Example")
assert(#sent == 1 and addon.probe.unmatched == 1)
members[2].presence = 3
Receive("1|P|101-20")
assert(#sent == 1, "offline roster entries cannot trigger a reply")
members[2].presence = secret
Receive("1|P|101-20")
assert(#sent == 1)
members[2].presence = 1
for _, message in ipairs({ "1|P|bad", string.rep("x", 1000), "2|P|101-20", secret }) do Receive(message) end
addon.ReceiveProbe("GuildStockP0", nil, "GUILD", "Peer Example")
Receive("1|P|101-20", "PARTY")
Receive("1|P|101-20", "WHISPER")
assert(#sent == 1, "malformed and wrong-channel messages cannot trigger replies")
Receive("1|P|101-20")
assert(#sent == 2 and sent[2][3] == "WHISPER" and sent[2][4] == "Peer Example")
Receive("1|P|101-20")
assert(#sent == 2, "duplicate requests are bounded")
Receive("1|A|0-0", "WHISPER")
Receive("1|A|" .. token, "GUILD")
assert(addon.probe.confirmed == 0)
Receive("1|A|" .. token, "WHISPER")
Receive("1|A|" .. token, "WHISPER")
assert(addon.probe.confirmed == 1, "matching acknowledgement counts exactly once")
addon.StartProbe()
assert(#sent == 2, "probe cooldown")
clock = clock + 61
sendResult = 3
addon.StartProbe()
assert(addon.probe.GUILD == "AddonMessageThrottle")
Receive("1|P|102-20")
assert(#sent == 3, "failed send disarms the probe without retrying")
clock, sendResult = clock + 61, 0
addon.StartProbe()
club = 456
Receive("1|P|103-20")
assert(#sent == 4, "guild changes invalidate the old probe")
club = 123
Event("PLAYER_GUILD_UPDATE", "player")
Receive("1|P|103-20")
assert(#sent == 4)

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
Click("My inventory")
local queries = 0
C_Item.GetItemInfo = function() queries = queries + 1; return "Loaded item" end
Event("GET_ITEM_INFO_RECEIVED", 20, false)
addon.Refresh()
assert(queries == 0, "failed item loads are not requested in a refresh loop")
Event("GET_ITEM_INFO_RECEIVED", 20, true)
assert(queries == 1 and addon.itemData[20].name == "Loaded item", "async names replace item-ID placeholders")
Click("Materials")
Click("All materials")
Click("Favorites")
addon.ToggleFavorite(20)
assert(saved.favorites[20] and #addon.Materials("favorites") == 2)
addon.ToggleFavorite(20)
assert(saved.favorites[20] == nil and saved.favorites[10])
Click("Settings")
local checks = {}
for _, f in ipairs(frames) do if f.checked ~= nil then checks[#checks + 1] = f end end
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
assert(#sent == 4, "UI operations never send addon messages")
GuildStockMinimapButton.scripts.OnClick()
assert(not GuildStockFrame:IsShown())
GuildStockMinimapButton.scripts.OnDragStart(GuildStockMinimapButton)
GuildStockMinimapButton.scripts.OnUpdate(GuildStockMinimapButton)
assert(saved.minimapAngle == 0)
GuildStockMinimapButton:Hide()
assert(not GuildStockMinimapButton:GetScript("OnUpdate"))
for _, locale in ipairs({ "esES", "esMX" }) do
    GetLocale = function() return locale end
    local localized = {}
    assert(loadfile("GuildStock/Locales.lua"))("GuildStock", localized)
    assert(localized.L["My inventory"] == "Mi inventario" and localized.L["unknown"] == "unknown")
end
print("GuildStock: bag observations, saved data, probes, catalog and interface checks OK")
