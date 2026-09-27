-- Run from the repository root. Small frame stubs exercise the real addon handlers.
local methods = {}
local function frame()
    return setmetatable({ scripts = {}, events = {}, shown = true }, { __index = methods })
end
for _, name in ipairs({"SetSize", "SetFrameLevel", "SetFrameStrata", "SetClampedToScreen", "SetMovable",
    "EnableMouse", "SetHighlightTexture", "SetNormalTexture", "SetAllPoints", "SetTexture",
    "UnregisterEvent", "SetText", "SetAutoFocus", "SetMaxBytes", "SetJustifyH", "SetWordWrap",
    "SetColorTexture", "SetTexCoord", "SetVertexColor", "SetHeight", "SetWidth", "SetEnabled",
    "SetChecked", "EnableMouseWheel", "ClearFocus", "SetTextColor", "SetPushedTexture", "SetDisabledTexture",
    "SetJustifyV", "SetNonSpaceWrap", "SetScrollChild", "UpdateScrollChildRect", "SetValue"}) do
    methods[name] = function() end
end
function methods:SetScript(name, callback) self.scripts[name] = callback end
function methods:GetScript(name) return self.scripts[name] end
function methods:RegisterEvent(name) self.events[name] = true end
function methods:RegisterForClicks(...) self.clicks = table.concat({...}, ",") end
function methods:SetMovable(movable) self.movable = movable end
function methods:RegisterForDrag(button) self.dragButton = button end
function methods:ClearAllPoints() self.point = nil end
function methods:SetPoint(...) self.point = {...} end
function methods:GetFrameLevel() return 1 end
function methods:GetCenter() return 100, 200 end
function methods:GetEffectiveScale() return 0.75 end
function methods:GetWidth() return 160 end
function methods:GetHeight() return 160 end
function methods:GetLineHeight() return 14 end
function methods:GetUnboundedStringWidth() return 60 end
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
methods.CreateTexture, methods.CreateFontString, methods.GetNormalTexture = frame, frame, frame
local cursorX, cursorY = 150, 150
GetCursorPosition = function() return cursorX, cursorY end
GetLocale = function() return "enUS" end
UnitGUID = function() return "test-character" end
hooksecurefunc = function() end
StaticPopup_Hide = function() end
RAID_CLASS_COLORS = {}
GameTooltip = frame()
function GameTooltip:SetOwner(owner) self.owner = owner; self.lines = {} end
function GameTooltip:AddLine(text) table.insert(self.lines, text) end

for _, name in ipairs({"TDL", "Revenge"}) do
    for _, locale in ipairs({"esES", "esMX", "frFR", "deDE", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW"}) do
        GetLocale = function() return locale end
        local addon = {}
        assert(loadfile(name .. "/Locales.lua"))(name, addon)
        for _, key in ipairs({"Left-click: Open / close", "Drag: Move"}) do
            assert(type(rawget(addon.L, key)) == "string", name .. ": missing " .. locale .. " " .. key)
        end
    end
    GetLocale = function() return "enUS" end
    local databaseName = name .. "DB"
    _G[databaseName] = { tasks = {{text = "Keep task"}}, enemies = {example = {firstName = "Test", surname = "Example"}}, revision = 3 }
    RevengeBackupDB = nil
    local saved = _G[databaseName]
    local function loadAddon()
        local frames = {}
        UIParent, Minimap = frame(), frame()
        StaticPopupDialogs, UISpecialFrames, SlashCmdList = {}, {}, {}
        CreateFrame = function(_, globalName)
            local result = frame()
            result.TitleText = frame()
            result.ScrollBar = frame()
            frames[#frames + 1] = result
            if globalName then _G[globalName] = result end
            return result
        end
        local addon = {}
        assert(loadfile(name .. "/Locales.lua"))(name, addon)
        assert(loadfile(name .. "/" .. name .. ".lua"))(name, addon)
        local icon = _G[name .. "MinimapButton"]
        icon.scripts.OnDragStart(icon)
        assert(not icon:GetScript("OnUpdate"), "drag must wait for DB initialization")
        for _, event in ipairs({"ADDON_LOADED", "PLAYER_LOGIN"}) do
            for _, f in ipairs(frames) do
                if f.events[event] then f.scripts.OnEvent(f, event, name) end
            end
        end
        return icon, SlashCmdList[name == "TDL" and "TDL" or "REVENGE"]
    end
    local icon, slash = loadAddon()
    assert(_G[databaseName] == saved and saved.tasks[1].text == "Keep task" and saved.enemies.example)
    assert(icon.clicks == "LeftButtonUp" and icon.dragButton == "LeftButton" and icon.movable)
    icon.scripts.OnClick(icon, "LeftButton")
    assert(_G[name .. "Frame"]:IsShown())
    icon.scripts.OnClick(icon, "LeftButton")
    assert(not _G[name .. "Frame"]:IsShown())
    icon.scripts.OnEnter(icon)
    assert(GameTooltip.lines[1] == "Left-click: Open / close" and #GameTooltip.lines == 2)
    icon.scripts.OnDragStart(icon)
    icon.scripts.OnUpdate(icon)
    assert(math.abs(icon.point[4] - 88) < 0.001 and math.abs(icon.point[5]) < 0.001, "scaled cursor moves icon east")
    cursorX, cursorY = 75, 225
    icon.scripts.OnUpdate(icon)
    assert(math.abs(icon.point[4]) < 0.001 and math.abs(icon.point[5] - 88) < 0.001, "cursor moves icon north")
    local angle = saved.minimapAngle
    cursorX, cursorY = 75, 150
    icon.scripts.OnUpdate(icon)
    assert(saved.minimapAngle == angle, "center cursor keeps previous position")
    canaccessvalue = function() return false end
    icon.scripts.OnUpdate(icon)
    assert(saved.minimapAngle == angle, "restricted coordinates are ignored")
    canaccessvalue = nil
    icon.scripts.OnDragStop(icon)
    assert(not icon:GetScript("OnUpdate") and not _G[name .. "Frame"]:IsShown())
    if name == "Revenge" then
        assert(saved.revision == 4 and RevengeBackupDB.characters["test-character"] == saved)
    end
    icon, slash = loadAddon()
    assert(icon:IsShown() and math.abs(icon.point[5] - 88) < 0.001, "restore saved position")
    slash("")
    assert(_G[name .. "Frame"]:IsShown(), "plain slash still opens window")
    icon.scripts.OnDragStart(icon)
    icon:Hide()
    assert(not icon:GetScript("OnUpdate"), "hiding stops drag")
    saved.minimapAngle = "invalid"
    icon = loadAddon()
    assert(icon.point[1] ~= "CENTER", "invalid saved angle keeps default anchor")
    cursorX, cursorY = 150, 150
    print(name .. " minimap controls and saved settings: OK")
end
