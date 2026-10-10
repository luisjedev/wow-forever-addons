-- Run from the repository root: luajit Waymark/Waymark.test.lua
local ROOT = "Waymark/"

-- Part 1: pure helpers load without WoW.
local addon = assert(loadfile(ROOT .. "Waymark.lua"))("Waymark", {})

assert(addon.SCHEMA == 1 and addon.MAX_PINS == 20 and addon.MAX_NOTE_BYTES == 140)

-- CleanNote trims control characters and whitespace, drops empties.
assert(addon.CleanNote("  fountain\n") == "fountain")
assert(addon.CleanNote(" \n ") == nil)
assert(addon.CleanNote(nil) == nil)
local long = string.rep("a", 200)
assert(#addon.CleanNote(long) == 140, "notes are capped at 140 bytes")
local utf8note = string.rep("\195\169", 100) -- 200 bytes of multibyte text
assert(addon.CleanNote(utf8note) == string.rep("\195\169", 69), "truncation keeps whole characters")

-- Pins require an id, a map and clamped coordinates plus a short note.
local good = { id = 1, mapID = 1414, x = 0.42, y = 0.61, zone = "Durotar", note = "hi", created = 100 }
assert(addon.IsValidPin(good) == true)
assert(addon.IsValidPin({ id = 2, mapID = 10, x = 0.5, y = 0.5, note = "ok" }) == true)
assert(addon.IsValidPin({}) == false)
assert(addon.IsValidPin({ id = 1, mapID = 1414, x = 0.5, y = 0.5 }) == false, "note is required")
assert(addon.IsValidPin({ id = 1, mapID = 1414, x = -0.1, y = 0.5, note = "ok" }) == false)
assert(addon.IsValidPin({ id = 1, mapID = 1414, x = 1.01, y = 0.5, note = "ok" }) == false)
assert(addon.IsValidPin({ id = "1", mapID = 1414, x = 0.5, y = 0.5, note = "ok" }) == false)
assert(addon.IsValidPin({ id = 1, mapID = "1414", x = 0.5, y = 0.5, note = "ok" }) == false)
assert(addon.IsValidPin({ id = 1, mapID = 1414, x = 0.5, y = 0.5, note = "" }) == false)
assert(addon.IsValidPin({ id = 1, mapID = 1414, x = 0.5, y = 0.5, note = string.rep("b", 141) }) == false)

-- EnsureDB preserves valid data and unknown keys, drops invalid entries.
local raw = {
    pins = { good, "junk", { id = 2 },
        { id = 2, mapID = 1414, x = 2, y = 0.5, note = "edge" },
        { id = 3, mapID = 10, x = 0.1, y = 0.2, note = "second" } },
    position = { "CENTER", "CENTER", 0, 0 },
    custom = { keep = true },
}
local db = addon.EnsureDB(raw)
assert(db == raw and db.schema == 1, "same table is normalized in place")
assert(#db.pins == 2 and db.pins[1].id == 1 and db.pins[2].id == 3)
assert(db.nextID == 4, "nextID continues past the highest kept id")
assert(db.custom.keep == true and db.position[1] == "CENTER", "unknown keys are preserved")
assert(addon.EnsureDB(nil).schema == 1 and #addon.EnsureDB(nil).pins == 0)
assert(addon.EnsureDB({ pins = {}, nextID = 41 }).nextID == 41, "nextID never moves backwards")
local many = { pins = {} }
for i = 1, 25 do many.pins[i] = { id = i, mapID = 1, x = 0.5, y = 0.5, note = "n" .. i } end
local pruned = addon.EnsureDB(many)
assert(#pruned.pins == 20 and pruned.pins[1].id == 1 and pruned.pins[20].id == 20)
assert(pruned.nextID == 21, "migration keeps the newest 20")

-- AddPin inserts newest first and blocks a full list without deleting.
local store = addon.EnsureDB(nil)
for i = 1, 20 do
    local pin = addon.AddPin(store, { mapID = 1414, x = 0.05 * i, y = 0.5, zone = "Z", note = "pin " .. i, created = i })
    assert(pin and pin.id == i, "ids are sequential")
end
assert(#store.pins == 20 and store.pins[1].note == "pin 20", "newest first")
local blocked, err = addon.AddPin(store, { mapID = 1, x = 0.5, y = 0.5, note = "extra" })
assert(blocked == false and err == "full" and #store.pins == 20, "the 21st pin is blocked, nothing deleted")
local fresh = addon.EnsureDB(nil)
assert(addon.AddPin(fresh, { mapID = 1, x = 1.5, y = 0.5, note = "edge" }) == false)
assert(addon.AddPin(fresh, { mapID = 1, x = 0.5, y = 0.5, note = "   " }) == false)
assert(#fresh.pins == 0, "invalid pins save nothing")

-- DeletePin removes by id; the freed slot takes a fresh id.
assert(addon.DeletePin(store, 999) == false)
assert(addon.DeletePin(store, store.pins[1].id) == true and #store.pins == 19)
local again = addon.AddPin(store, { mapID = 2, x = 0.1, y = 0.1, note = "again" })
assert(again and again.id == 21 and #store.pins == 20, "ids are never reused")

-- Slash parsing.
assert(addon.ParseSlash("") == "toggle")
assert(addon.ParseSlash("   ") == "toggle")
local action, rest = addon.ParseSlash("add fountain by the road")
assert(action == "add" and rest == "fountain by the road")
assert(addon.ParseSlash("ADD upper") == "add")
assert(addon.ParseSlash("add") == "add-missing")
assert(addon.ParseSlash("place") == "place")
assert(addon.ParseSlash("PLACE") == "place")
assert(addon.ParseSlash("bogus") == "unknown")

-- Coordinate formatting.
assert(addon.FormatCoords({ x = 0.42, y = 0.61 }) == "42.0, 61.0")
assert(addon.FormatCoords({}) == "?")

print("Waymark helpers, migration, cap and slash parsing: OK")

-- Part 2: every locale translates every key used by the addon.
local sourceFile = assert(io.open(ROOT .. "Waymark.lua", "r"))
local source = sourceFile:read("*a")
sourceFile:close()
local keys = {}
for key in source:gmatch('L%["(.-)"%]') do keys[key] = true end
assert(keys["Waymarks: %d"] and keys["No waymarks yet. Use the Waymark button on the world map to add one."]
    and keys["Click the map to place your waymark. Click the button again to cancel."]
    and keys["Unknown command. Use /wm, /wm place or /wm add <text>."])
assert(keys["No waymarks yet. Alt+Click the world map to add one."] == nil, "Alt keys are gone")
assert(keys["Alt+Click map: Add waymark"] == nil, "Alt keys are gone")
local loadLocales = assert(loadfile(ROOT .. "Locales.lua"))
local spanish
for _, locale in ipairs({"esES", "esMX", "frFR", "deDE", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW", "enUS", "enGB", "unknown"}) do
    GetLocale = function() return locale end
    local localized = {}
    loadLocales("Waymark", localized)
    local L = localized.L
    if locale == "esES" then spanish = L end
    for key in pairs(keys) do
        local text = L[key]
        if locale == "enUS" or locale == "enGB" or locale == "unknown" then
            assert(text == key, locale .. ": English fallback missing for " .. key)
        else
            assert(type(rawget(L, key)) == "string" and text ~= "", locale .. ": missing " .. key)
        end
        if locale == "esMX" then assert(text == spanish[key]) end
        local function placeholders(value)
            local found = {}
            for token in value:gmatch("%%.") do found[#found + 1] = token end
            return table.concat(found)
        end
        assert(placeholders(text) == placeholders(key), locale .. ": format mismatch for " .. key)
        assert(pcall(string.format, text, key:find("%%d") and 2 or "Durotar"))
    end
    assert(L["Missing translation"] == "Missing translation")
end
GetLocale = nil

print("Waymark locales: OK")

-- Part 3: frame stubs exercise the provider, map clicks, popups, list and slash.
local methods, frames = {}, {}
local function frame(parent)
    return setmetatable({ parent = parent, scripts = {}, events = {}, shown = true }, { __index = methods })
end
for _, name in ipairs({"SetSize", "SetFrameLevel", "SetFrameStrata", "SetClampedToScreen",
    "EnableMouse", "SetHighlightTexture",
    "SetAllPoints", "SetTexture", "SetJustifyH", "SetTextColor", "SetHeight", "SetWidth",
    "SetScrollChild", "UpdateScrollChildRect", "SetValue", "UnregisterEvent", "StartMoving",
    "StopMovingOrSizing"}) do
    methods[name] = function() end
end
function methods:RegisterForClicks(...) self.clicks = table.concat({...}, ",") end
function methods:RegisterForDrag(button) self.dragButton = button end
function methods:SetScript(name, callback) self.scripts[name] = callback end
function methods:HookScript(name, callback) self.scripts[name] = callback end
function methods:GetScript(name) return self.scripts[name] end
function methods:RegisterEvent(name) self.events[name] = true end
function methods:SetMovable(movable) self.movable = movable end
function methods:ClearAllPoints() self.point = nil end
function methods:SetPoint(...) self.point = { ... } end
function methods:GetPoint() return "CENTER", nil, "CENTER", 0, 0 end
function methods:SetText(text) self.label = text end
function methods:GetWidth() return 160 end
function methods:GetHeight() return 160 end
function methods:GetFrameLevel() return 1 end
function methods:GetCenter() return 100, 200 end
function methods:GetEffectiveScale() return 0.75 end
function methods:GetValue() return 0 end
function methods:GetVerticalScrollRange() return 0 end
function methods:IsShown() return self.shown end
function methods:SetShown(shown)
    if self.shown == shown then return end
    self.shown = shown
    local callback = self.scripts[shown and "OnShow" or "OnHide"]
    if callback then callback(self) end
end
function methods:Hide() self:SetShown(false) end
function methods:Show() self:SetShown(true) end
methods.CreateTexture, methods.CreateFontString = frame, frame
CreateFrame = function(kind, name, parent, template)
    local result = frame(parent)
    result.kind, result.template = kind, template
    result.TitleText, result.ScrollBar = frame(result), frame(result)
    frames[#frames + 1] = result
    if name then _G[name] = result end
    return result
end
CreateFromMixins = function(...)
    local mixed = {}
    for i = 1, select("#", ...) do
        local mixin = select(i, ...)
        if type(mixin) == "table" then
            for key, value in pairs(mixin) do mixed[key] = value end
        end
    end
    return mixed
end
MapCanvasDataProviderMixin, MapCanvasPinMixin = {}, {}
UIParent = frame()
UISpecialFrames, SlashCmdList = {}, {}
GameTooltip = frame()
function GameTooltip:SetOwner(owner) self.owner = owner; self.lines = {} end
function GameTooltip:SetText(text) self.title = text end
function GameTooltip:AddLine(text) table.insert(self.lines, text) end
function GameTooltip:Show() self.visible = true end
function GameTooltip:Hide() self.visible = false end
local chat = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, message) chat[#chat + 1] = message end }
StaticPopupDialogs = {}
local shownPopups = {}
StaticPopup_Show = function(name, arg1, arg2, data)
    shownPopups[#shownPopups + 1] = { name = name, arg1 = arg1, data = data }
end
local mouseOver, cursorX, cursorY = true, 0.42, 0.61
local worldMapID = 1414
WorldMapFrame = frame()
WorldMapFrame.ScrollContainer = frame()
WorldMapFrame.ScrollContainer.hooks = {}
function WorldMapFrame.ScrollContainer:HookScript(name, callback) self.hooks[name] = callback end
function WorldMapFrame.ScrollContainer:IsMouseOver() return mouseOver end
function WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition() return cursorX, cursorY end
function WorldMapFrame:GetMapID() return worldMapID end
function WorldMapFrame:SetMapID(id) self.shownMap = id end
local addedProviders = {}
function WorldMapFrame:AddDataProvider(provider) addedProviders[#addedProviders + 1] = provider end
local hoveredPin = false
function WorldMapFrame:EnumeratePinsByTemplate(template)
    assert(template == "WaymarkPinTemplate")
    local pins = {}
    if hoveredPin then pins[1] = { IsMouseOver = function() return true end } end
    local index = 0
    return function()
        index = index + 1
        return pins[index]
    end
end
GetLocale = function() return "enUS" end
GetZoneText = function() return "Fallback Zone" end
local playerMapID, playerX, playerY = 1414, 0.30, 0.40
C_Map = {
    GetBestMapForUnit = function() return playerMapID end,
    GetPlayerMapPosition = function()
        return { GetXY = function() return playerX, playerY end }
    end,
    GetMapInfo = function(id) return { name = "Zone " .. id } end,
}
time = function() return 2000 end
date = os.date

local function event(name, ...)
    for _, f in ipairs(frames) do
        if f.events[name] then f.scripts.OnEvent(f, name, ...) end
    end
end

WaymarkDB = { pins = { { id = 7, mapID = 1414, x = 0.1, y = 0.2, zone = "Kept Zone", note = "kept", created = 500 } },
    custom = { keep = true } }
local live = {}
assert(loadfile(ROOT .. "Locales.lua"))("Waymark", live)
assert(loadfile(ROOT .. "Waymark.lua"))("Waymark", live)
assert(SLASH_WAYMARK1 == "/wm" and SLASH_WAYMARK2 == "/waymark")
event("ADDON_LOADED", "Waymark")
assert(#WaymarkDB.pins == 1 and WaymarkDB.pins[1].note == "kept"
    and WaymarkDB.custom.keep == true and WaymarkDB.nextID == 8, "login preserves existing data")
event("PLAYER_LOGIN")
assert(#addedProviders == 1, "provider registered on login")
assert(_G.WaymarkMapButton ~= nil, "world map button exists")
event("ADDON_LOADED", "Blizzard_WorldMap")
assert(#addedProviders == 1, "late map load never registers twice")

-- The provider only acquires pins for the currently shown map.
local provider = live._providerInstance
assert(provider ~= nil and type(provider.RefreshAllData) == "function")
local acquired = {}
provider.RemoveAllPinsByTemplate = function(self, template) acquired = {}; self.cleared = template end
provider.GetMap = function(self) return { GetMapID = function() return 1414 end } end
provider.AcquirePin = function(self, template, data)
    local pin = { template = template, data = data }
    function pin:SetPosition(x, y) self.x, self.y = x, y end
    acquired[#acquired + 1] = pin
    return pin
end
provider:RefreshAllData()
assert(provider.cleared == "WaymarkPinTemplate" and #acquired == 1
    and acquired[1].data.note == "kept" and acquired[1].x == 0.1 and acquired[1].y == 0.2)

-- Placing mode needs no keyboard: the map button arms it, the next left
-- click on the canvas plants the pin and disarms.
local mouseDown = WorldMapFrame.ScrollContainer.hooks.OnMouseDown
assert(mouseDown ~= nil, "map click hook installed")
assert(_G.WaymarkListButton ~= nil, "world map list button exists")
local popups, armedChat = #shownPopups, #chat
mouseDown(WorldMapFrame.ScrollContainer, "LeftButton")
assert(#shownPopups == popups, "disarmed clicks are ignored")
_G.WaymarkMapButton.scripts.OnClick()
assert(_G.WaymarkMapButton.label == "Placing…", "button shows the armed state")
assert(#chat == armedChat + 1, "arming explains how to cancel")
-- Right click never plants nor cancels: it stays with map zoom.
mouseDown(WorldMapFrame.ScrollContainer, "RightButton")
assert(#shownPopups == popups and _G.WaymarkMapButton.label == "Placing…")
-- Armed clicks keep the clicked map: navigate-then-place works.
worldMapID = 999
mouseDown(WorldMapFrame.ScrollContainer, "LeftButton")
assert(#shownPopups == popups + 1 and shownPopups[#shownPopups].name == "WAYMARK_ADD")
assert(_G.WaymarkMapButton.label == "Waymark", "planting disarms")
local addData = shownPopups[#shownPopups].data
assert(addData.mapID == 999 and addData.x == 0.42 and addData.y == 0.61 and addData.zone == "Zone 999")
worldMapID = 1414

-- Accepting the popup creates the pin; cancelling would create nothing.
StaticPopupDialogs.WAYMARK_ADD.OnAccept({ editBox = { GetText = function() return "  fountain  " end } }, addData)
assert(#WaymarkDB.pins == 2 and WaymarkDB.pins[1].note == "fountain"
    and WaymarkDB.pins[1].id == 8 and WaymarkDB.pins[1].mapID == 999)
provider:RefreshAllData()
assert(#acquired == 1, "other-map pins stay hidden on refresh")
WaymarkDB.pins[1].mapID = 1414
provider:RefreshAllData()
assert(#acquired == 2, "refresh picks up the new pin on its map")

-- Overlap guard: a click on an existing pin opens its popup, plants nothing.
_G.WaymarkMapButton.scripts.OnClick()
assert(_G.WaymarkMapButton.label == "Placing…")
hoveredPin = true
popups = #shownPopups
mouseDown(WorldMapFrame.ScrollContainer, "LeftButton")
assert(#shownPopups == popups, "clicks on pins plant nothing")
assert(_G.WaymarkMapButton.label == "Placing…", "overlap keeps us armed")
hoveredPin = false
mouseDown(WorldMapFrame.ScrollContainer, "LeftButton")
assert(#shownPopups == popups + 1, "the next free click plants")
local freeData = shownPopups[#shownPopups].data
StaticPopupDialogs.WAYMARK_ADD.OnAccept({ editBox = { GetText = function() return "   " end } }, freeData)
assert(#WaymarkDB.pins == 2, "blank popup notes save nothing")

-- The button cancels while armed; closing the map cancels silently.
_G.WaymarkMapButton.scripts.OnClick()
armedChat = #chat
_G.WaymarkMapButton.scripts.OnClick()
assert(_G.WaymarkMapButton.label == "Waymark" and #chat == armedChat + 1, "button cancels placing")
_G.WaymarkMapButton.scripts.OnClick()
armedChat = #chat
WorldMapFrame.scripts.OnHide()
assert(_G.WaymarkMapButton.label == "Waymark" and #chat == armedChat, "map close cancels silently")

-- Slash: toggle, add at the player, errors.
local slash = SlashCmdList.WAYMARK
slash("")
assert(_G.WaymarkFrame:IsShown(), "/wm opens the list")
assert(live._rows[1].note.label == "fountain", "list shows the newest pin first")
slash("")
assert(not _G.WaymarkFrame:IsShown(), "/wm closes the list")
_G.WaymarkListButton.scripts.OnClick()
assert(_G.WaymarkFrame:IsShown(), "List button opens the window")
_G.WaymarkListButton.scripts.OnClick()
assert(not _G.WaymarkFrame:IsShown(), "List button closes the window")
slash("add at the player")
assert(WaymarkDB.pins[1].note == "at the player" and WaymarkDB.pins[1].x == 0.30
    and WaymarkDB.pins[1].zone == "Zone 1414", "/wm add uses the player position")
playerMapID = nil
local count, messages = #WaymarkDB.pins, #chat
slash("add nowhere")
assert(#WaymarkDB.pins == count and #chat == messages + 1, "unknown position saves nothing")
playerMapID = 1414
slash("add")
assert(#chat == messages + 2, "bare /wm add explains itself")
slash("bogus")
assert(#chat == messages + 3, "unknown commands explain themselves")

-- /wm place opens the map and arms placing.
WorldMapFrame:Hide()
slash("place")
assert(WorldMapFrame:IsShown(), "/wm place opens the map")
assert(_G.WaymarkMapButton.label == "Placing…", "/wm place arms placing")
_G.WaymarkMapButton.scripts.OnClick()

-- The cap blocks slash adds and refuses to arm, with a chat message.
while #WaymarkDB.pins < 20 do slash("add filler " .. #WaymarkDB.pins) end
assert(#WaymarkDB.pins == 20)
messages = #chat
slash("add one too many")
assert(#WaymarkDB.pins == 20 and #chat == messages + 1, "the 21st pin is blocked")
_G.WaymarkMapButton.scripts.OnClick()
assert(_G.WaymarkMapButton.label == "Waymark" and #chat == messages + 2, "arming is blocked when full")

-- List buttons: go recenters the world map, delete removes with a message.
live._rows[1].go.scripts.OnClick()
assert(WorldMapFrame.shownMap == WaymarkDB.pins[1].mapID, "go recenters the world map")
messages = #chat
live._rows[1].remove.scripts.OnClick()
assert(#WaymarkDB.pins == 19 and #chat == messages + 1, "list delete removes and reports")

-- Pin tooltip, left-click popup, right-click passthrough, pool release.
local pinFrame = frame()
for key, value in pairs(WaymarkPinMixin) do pinFrame[key] = value end
pinFrame:OnAcquired(WaymarkDB.pins[1])
pinFrame:OnMouseEnter()
assert(GameTooltip.title == WaymarkDB.pins[1].note and GameTooltip.visible == true)
assert(GameTooltip.lines[2] == "Click: View / delete")
pinFrame:OnMouseLeave()
assert(GameTooltip.visible == false)
popups = #shownPopups
pinFrame:OnClick("LeftButton")
assert(#shownPopups == popups + 1 and shownPopups[#shownPopups].name == "WAYMARK_VIEW")
pinFrame:OnClick("RightButton")
assert(#shownPopups == popups + 1, "right click on pins stays with the map zoom")
pinFrame:OnReleased()
assert(pinFrame.pinData == nil, "released pins reset their state")

-- Deleting from the view popup removes the pin with a message.
messages = #chat
local target = WaymarkDB.pins[1]
StaticPopupDialogs.WAYMARK_VIEW.OnAccept(nil, target)
assert(#WaymarkDB.pins == 18 and #chat == messages + 1, "view popup delete removes and reports")

print("Waymark provider, map clicks, popups, list and slash: OK")
