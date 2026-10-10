-- Run from the repository root: luajit DeathMark/DeathMark.test.lua
local ROOT = "DeathMark/"

-- Part 1: pure helpers load without WoW.
local addon = assert(loadfile(ROOT .. "DeathMark.lua"))("DeathMark", {})

assert(addon.SCHEMA == 1 and addon.MAX_DEATHS == 10 and addon.MAX_NOTE_BYTES == 140)

-- CleanNote trims control characters and whitespace, drops empties.
assert(addon.CleanNote("  cave pull\n") == "cave pull")
assert(addon.CleanNote(" \n ") == nil)
assert(addon.CleanNote(nil) == nil)
local long = string.rep("a", 200)
local cleaned = addon.CleanNote(long)
assert(#cleaned == 140, "notes are capped at 140 bytes")
local utf8note = string.rep("\195\169", 100) -- 200 bytes of multibyte text
local cut = addon.CleanNote(utf8note)
assert(cut == string.rep("\195\169", 69), "truncation keeps whole characters")

-- Entries require a timestamp; map and coordinates may be nil (indoors, instances).
assert(addon.IsValidEntry({ timestamp = 1 }) == true)
assert(addon.IsValidEntry({ timestamp = 1, mapID = 1415, x = 0.5, y = 0.5 }) == true)
assert(addon.IsValidEntry({ timestamp = 1, note = "ok" }) == true)
assert(addon.IsValidEntry({}) == false)
assert(addon.IsValidEntry({ timestamp = "now" }) == false)
assert(addon.IsValidEntry({ timestamp = 1, note = "" }) == false)
assert(addon.IsValidEntry({ timestamp = 1, note = string.rep("b", 141) }) == false)
assert(addon.IsValidEntry({ timestamp = 1, x = "left" }) == false)

-- EnsureDB preserves valid data and unknown keys, drops invalid entries, prunes.
local raw = {
    deaths = { { timestamp = 3 }, "junk", { no = "stamp" }, { timestamp = 1 } },
    minimapAngle = 0.5,
    custom = { keep = true },
}
local db = addon.EnsureDB(raw)
assert(db == raw and db.schema == 1, "same table is normalized in place")
assert(#db.deaths == 2 and db.deaths[1].timestamp == 3 and db.deaths[2].timestamp == 1)
assert(db.minimapAngle == 0.5 and db.custom.keep == true, "unknown keys are preserved")
assert(addon.EnsureDB(nil).schema == 1 and #addon.EnsureDB(nil).deaths == 0)
local many = { deaths = {} }
for i = 1, 25 do many.deaths[i] = { timestamp = i } end
assert(#addon.EnsureDB(many).deaths == 10, "migration prunes to the newest 10")

-- RecordDeath inserts newest first and prunes by age.
local store = addon.EnsureDB(nil)
for i = 1, 12 do addon.RecordDeath(store, addon.BuildEntry(i, 60, "Zone", nil, nil, nil, nil)) end
assert(#store.deaths == 10 and store.deaths[1].timestamp == 12 and store.deaths[10].timestamp == 3)
assert(addon.RecordDeath(store, { nope = true }) == nil and #store.deaths == 10)
local built = addon.BuildEntry(7, 60, "Elwynn Forest", "Goldshire", 1415, 0.42, 0.65)
assert(built.zone == "Elwynn Forest" and built.subzone == "Goldshire"
    and built.mapID == 1415 and built.x == 0.42 and built.y == 0.65)
local indoor = addon.BuildEntry(8, 60, "Deadmines", nil, nil, nil, nil)
assert(indoor.mapID == nil and indoor.x == nil, "nil maps stay nil")

-- Notes attach to the newest entry.
local noted = addon.EnsureDB(nil)
assert(addon.SetNote(noted, "text") == false, "no entry means no note target")
addon.RecordDeath(noted, addon.BuildEntry(1, 1, "Zone", nil, nil, nil, nil))
local ok, result = addon.SetNote(noted, "  pulled two packs  ")
assert(ok and result == "saved" and noted.deaths[1].note == "pulled two packs")
ok, result = addon.SetNote(noted, string.rep("c", 200))
assert(ok and result == "shortened" and #noted.deaths[1].note == 140)
assert(addon.SetNote(noted, "   ") == false, "blank notes are rejected")

-- Double PLAYER_DEAD without release records once; ALIVE/UNGHOST only reset.
local state = { pending = false }
assert(addon.ApplyEvent(state, "PLAYER_DEAD") == true)
assert(addon.ApplyEvent(state, "PLAYER_DEAD") == false, "double death is a duplicate")
assert(addon.ApplyEvent(state, "PLAYER_ALIVE") == false and state.pending == false)
assert(addon.ApplyEvent(state, "PLAYER_DEAD") == true)
assert(addon.ApplyEvent(state, "PLAYER_UNGHOST") == false and state.pending == false)

-- Slash parsing.
assert(addon.ParseSlash("") == "toggle")
assert(addon.ParseSlash("   ") == "toggle")
local action, rest = addon.ParseSlash("nota pulled extra pack")
assert(action == "note" and rest == "pulled extra pack")
assert(addon.ParseSlash("nota") == "note-missing")
assert(addon.ParseSlash("NOTA late note") == "note")
assert(addon.ParseSlash("bogus") == "unknown")

print("DeathMark helpers, migration, notes and slash parsing: OK")

-- Part 2: every locale translates every key used by the addon.
local sourceFile = assert(io.open(ROOT .. "DeathMark.lua", "r"))
local source = sourceFile:read("*a")
sourceFile:close()
local keys = {}
for key in source:gmatch('L%["(.-)"%]') do keys[key] = true end
assert(keys["Deaths: %d"] and keys["No deaths recorded."] and keys["Hint: /dm nota <text>"])
local loadLocales = assert(loadfile(ROOT .. "Locales.lua"))
local spanish
for _, locale in ipairs({"esES", "esMX", "frFR", "deDE", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW", "enUS", "enGB", "unknown"}) do
    GetLocale = function() return locale end
    local localized = {}
    loadLocales("DeathMark", localized)
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
        assert(pcall(string.format, text, key:find("%%d") and 2 or "Elwynn Forest"))
    end
    assert(L["Missing translation"] == "Missing translation")
end
GetLocale = nil

print("DeathMark locales: OK")

-- Part 3: frame stubs exercise the real event, slash and minimap wiring.
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
UIParent, Minimap = frame(), frame()
UISpecialFrames, SlashCmdList = {}, {}
GameTooltip = frame()
function GameTooltip:SetOwner(owner) self.owner = owner; self.lines = {} end
function GameTooltip:AddLine(text) table.insert(self.lines, text) end
local chat = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, message) chat[#chat + 1] = message end }
local cursorX, cursorY = 150, 150
GetCursorPosition = function() return cursorX, cursorY end
GetLocale = function() return "enUS" end
UnitLevel = function() return 60 end
GetZoneText = function() return "Elwynn Forest" end
GetSubZoneText = function() return "Goldshire" end
local mapID, mapX, mapY = 1415, 0.42, 0.65
C_Map = {
    GetBestMapForUnit = function() return mapID end,
    GetPlayerMapPosition = function()
        return { GetXY = function() return mapX, mapY end }
    end,
}
time = function() return 1000 end
date = os.date

local function event(name, ...)
    for _, f in ipairs(frames) do
        if f.events[name] then f.scripts.OnEvent(f, name, ...) end
    end
end

DeathMarkDB = { deaths = { { timestamp = 500, zone = "Kept Zone" } }, custom = { keep = true } }
local live = {}
assert(loadfile(ROOT .. "Locales.lua"))("DeathMark", live)
assert(loadfile(ROOT .. "DeathMark.lua"))("DeathMark", live)
assert(SLASH_DEATHMARK1 == "/deathmark" and SLASH_DEATHMARK2 == "/dm")
event("ADDON_LOADED", "DeathMark")
event("PLAYER_LOGIN")
assert(#DeathMarkDB.deaths == 1 and DeathMarkDB.deaths[1].zone == "Kept Zone"
    and DeathMarkDB.custom.keep == true, "login preserves existing data")

-- Reload while a ghost: login alone records nothing.
local before = #DeathMarkDB.deaths
event("PLAYER_LOGIN")
assert(#DeathMarkDB.deaths == before, "reload without PLAYER_DEAD records nothing")

-- A death records zone, level and coordinates; a repeated PLAYER_DEAD is ignored.
event("PLAYER_DEAD")
assert(#DeathMarkDB.deaths == 2, "PLAYER_DEAD records one entry")
local entry = DeathMarkDB.deaths[1]
assert(entry.timestamp == 1000 and entry.level == 60 and entry.zone == "Elwynn Forest"
    and entry.subzone == "Goldshire" and entry.mapID == 1415
    and entry.x == 0.42 and entry.y == 0.65)
event("PLAYER_DEAD")
assert(#DeathMarkDB.deaths == 2, "double PLAYER_DEAD without release is a duplicate")
event("PLAYER_ALIVE")
event("PLAYER_DEAD")
assert(#DeathMarkDB.deaths == 3, "release re-arms death recording")
event("PLAYER_UNGHOST")

-- Deaths inside instances tolerate a nil map and nil coordinates.
mapID, mapX, mapY = nil, nil, nil
event("PLAYER_DEAD")
assert(#DeathMarkDB.deaths == 4 and DeathMarkDB.deaths[1].mapID == nil
    and DeathMarkDB.deaths[1].x == nil, "nil map stays nil instead of failing")
mapID, mapX, mapY = 1415, 0.42, 0.65

-- Cap at 10 entries, newest first.
for _ = 1, 12 do event("PLAYER_ALIVE") event("PLAYER_DEAD") end
assert(#DeathMarkDB.deaths == 10, "history is pruned to 10")
assert(DeathMarkDB.deaths[1].timestamp == 1000)

-- Slash commands: toggle, notes, errors.
local slash = SlashCmdList.DEATHMARK
slash("")
assert(_G.DeathMarkFrame:IsShown(), "/dm opens the window")
assert(_G.DeathMarkFrame.TitleText.label == "DeathMark")
slash("")
assert(not _G.DeathMarkFrame:IsShown(), "/dm closes the window")
slash("nota pulled two packs")
assert(DeathMarkDB.deaths[1].note == "pulled two packs", "/dm nota annotates the newest death")
slash("nota " .. string.rep("n", 200))
assert(#DeathMarkDB.deaths[1].note == 140, "long notes shorten instead of failing")
local messages = #chat
slash("nota")
assert(#chat == messages + 1, "bare /dm nota explains itself")
slash("bogus")
assert(#chat == messages + 2, "unknown commands explain themselves")
DeathMarkDB.deaths = {}
slash("nota nowhere to attach")
assert(#chat == messages + 3, "notes without deaths explain themselves")

-- Minimap button: drag waits for the database, moves with the cursor, survives bad data.
local icon = _G.DeathMarkMinimapButton
assert(icon.clicks == "LeftButtonUp" and icon.dragButton == "LeftButton" and icon.movable)
icon.scripts.OnEnter(icon)
assert(GameTooltip.lines[1] == "Left-click: Open / close" and #GameTooltip.lines == 2)
icon.scripts.OnDragStart(icon)
icon.scripts.OnUpdate(icon)
assert(math.abs(icon.point[4] - 88) < 0.001 and math.abs(icon.point[5]) < 0.001, "scaled cursor moves icon east")
cursorX, cursorY = 75, 225
icon.scripts.OnUpdate(icon)
assert(math.abs(icon.point[4]) < 0.001 and math.abs(icon.point[5] - 88) < 0.001, "cursor moves icon north")
local angle = DeathMarkDB.minimapAngle
cursorX, cursorY = 75, 150
icon.scripts.OnUpdate(icon)
assert(DeathMarkDB.minimapAngle == angle, "center cursor keeps previous position")
canaccessvalue = function() return false end
icon.scripts.OnUpdate(icon)
assert(DeathMarkDB.minimapAngle == angle, "restricted coordinates are ignored")
canaccessvalue = nil
icon.scripts.OnDragStop(icon)
assert(not icon:GetScript("OnUpdate"))
DeathMarkDB.minimapAngle = "invalid"
icon.point = nil
event("PLAYER_LOGIN")
assert(icon.point == nil, "invalid saved angle keeps default anchor")
cursorX, cursorY = 150, 150

print("DeathMark events, slash commands, window and minimap: OK")
