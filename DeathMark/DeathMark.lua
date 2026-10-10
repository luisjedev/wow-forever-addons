local addonName, addon = ...
addon = addon or {}
local L = addon.L

local SCHEMA = 1
local MAX_DEATHS = 10
local MAX_NOTE_BYTES = 140

addon.SCHEMA = SCHEMA
addon.MAX_DEATHS = MAX_DEATHS
addon.MAX_NOTE_BYTES = MAX_NOTE_BYTES

local function TruncateBytes(text, maxBytes)
    if #text <= maxBytes then return text end
    text = text:sub(1, maxBytes)
    local byte = text:sub(-1):byte()
    while byte and byte >= 0x80 and byte < 0xC0 do
        text = text:sub(1, -2)
        byte = text:sub(-1):byte()
    end
    if byte and byte >= 0xC0 then
        text = text:sub(1, -2)
    end
    return text
end

local function CleanNote(text)
    if text == nil then return nil end
    text = tostring(text):gsub("%c", " "):match("^%s*(.-)%s*$")
    if text == "" then return nil end
    return TruncateBytes(text, MAX_NOTE_BYTES)
end

local function CleanPlace(text)
    if text == nil then return nil end
    text = tostring(text):gsub("%c", " "):match("^%s*(.-)%s*$")
    if text == "" then return nil end
    return text
end

local function IsValidEntry(entry)
    if type(entry) ~= "table" then return false end
    if type(entry.timestamp) ~= "number" then return false end
    if entry.level ~= nil and type(entry.level) ~= "number" then return false end
    if entry.zone ~= nil and type(entry.zone) ~= "string" then return false end
    if entry.subzone ~= nil and type(entry.subzone) ~= "string" then return false end
    if entry.mapID ~= nil and type(entry.mapID) ~= "number" then return false end
    if entry.x ~= nil and type(entry.x) ~= "number" then return false end
    if entry.y ~= nil and type(entry.y) ~= "number" then return false end
    if entry.note ~= nil then
        if type(entry.note) ~= "string" or entry.note == "" or #entry.note > MAX_NOTE_BYTES then
            return false
        end
    end
    return true
end

-- Normalizes the per-character database without overwriting valid data.
-- Unknown keys are preserved; invalid entries are dropped; the list is
-- pruned to the newest MAX_DEATHS entries.
local function EnsureDB(raw)
    local db = type(raw) == "table" and raw or {}
    local deaths = {}
    if type(db.deaths) == "table" then
        for _, entry in ipairs(db.deaths) do
            if IsValidEntry(entry) then
                deaths[#deaths + 1] = entry
                if #deaths == MAX_DEATHS then break end
            end
        end
    end
    db.deaths = deaths
    db.schema = SCHEMA
    return db
end

local function BuildEntry(timestamp, level, zone, subzone, mapID, x, y)
    return {
        timestamp = timestamp,
        level = type(level) == "number" and level or nil,
        zone = CleanPlace(zone),
        subzone = CleanPlace(subzone),
        mapID = type(mapID) == "number" and mapID or nil,
        x = type(x) == "number" and x or nil,
        y = type(y) == "number" and y or nil,
    }
end

-- Inserts newest first and prunes entries older than MAX_DEATHS.
local function RecordDeath(db, entry)
    if not IsValidEntry(entry) then return nil end
    table.insert(db.deaths, 1, entry)
    while #db.deaths > MAX_DEATHS do
        table.remove(db.deaths)
    end
    return entry
end

-- Attaches a short note to the newest entry.
local function SetNote(db, text)
    local latest = db.deaths[1]
    if latest == nil then return false, "empty" end
    local cleaned = tostring(text or ""):gsub("%c", " "):match("^%s*(.-)%s*$")
    if cleaned == "" then return false, "missing" end
    local shortened = #cleaned > MAX_NOTE_BYTES
    latest.note = TruncateBytes(cleaned, MAX_NOTE_BYTES)
    return true, shortened and "shortened" or "saved"
end

-- PLAYER_DEAD can fire twice without a release; PLAYER_ALIVE and
-- PLAYER_UNGHOST only clear the pending flag, never record.
local function ApplyEvent(state, event)
    if event == "PLAYER_DEAD" then
        if state.pending then return false end
        state.pending = true
        return true
    elseif event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        state.pending = false
    end
    return false
end

local function ParseSlash(message)
    local text = tostring(message or ""):match("^%s*(.-)%s*$")
    if text == "" then return "toggle" end
    local command, rest = text:match("^(%S+)%s*(.-)%s*$")
    if command and command:lower() == "nota" then
        if rest == "" then return "note-missing" end
        return "note", rest
    end
    return "unknown"
end

addon.CleanNote = CleanNote
addon.IsValidEntry = IsValidEntry
addon.EnsureDB = EnsureDB
addon.BuildEntry = BuildEntry
addon.RecordDeath = RecordDeath
addon.SetNote = SetNote
addon.ApplyEvent = ApplyEvent
addon.ParseSlash = ParseSlash

-- Allows the small standalone test to load the pure helpers without mocking WoW.
if not CreateFrame then return addon end

local SKULL_TEXTURE = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01"

local db, window, countText, emptyText, hintText
local rows = {}
local state = { pending = false }

local function Readable(value)
    if value == nil then return nil end
    if canaccessvalue and not canaccessvalue(value) then return nil end
    return value
end

local function ReadPosition()
    local mapID, x, y
    if C_Map and C_Map.GetBestMapForUnit then
        local ok, id = pcall(C_Map.GetBestMapForUnit, "player")
        if ok and type(Readable(id)) == "number" then mapID = id end
    end
    if mapID and C_Map and C_Map.GetPlayerMapPosition then
        local ok, position = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
        position = ok and Readable(position) or nil
        if position and type(position.GetXY) == "function" then
            local okX, px, py = pcall(position.GetXY, position)
            if okX and type(Readable(px)) == "number" and type(Readable(py)) == "number" then
                x, y = px, py
            end
        end
    end
    return mapID, x, y
end

local function FormatPlace(entry)
    if entry.zone and entry.subzone and entry.subzone ~= entry.zone then
        return entry.zone .. " - " .. entry.subzone
    end
    return entry.zone or entry.subzone or L["Unknown place"]
end

local function FormatCoords(entry)
    if entry.x and entry.y then
        return ("%.1f, %.1f"):format(entry.x * 100, entry.y * 100)
    end
    return "?"
end

local function FormatLine(entry)
    local stamp = date("%Y-%m-%d %H:%M", entry.timestamp)
    local level = entry.level and (L["Level %d"]:format(entry.level) .. " · ") or ""
    return stamp .. " · " .. level .. FormatPlace(entry) .. " [" .. FormatCoords(entry) .. "]"
end

local function PlainText(text)
    return tostring(text or ""):gsub("|", "||")
end

local function Notify(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffb81fe6DeathMark:|r " .. message)
    end
end

local function RefreshWindow()
    if not window then return end
    countText:SetText(L["Deaths: %d"]:format(#db.deaths))
    emptyText:SetShown(#db.deaths == 0)
    for index, row in ipairs(rows) do
        local entry = db.deaths[index]
        row:SetShown(entry ~= nil)
        if entry then
            row.line:SetText(PlainText(FormatLine(entry)))
            row.note:SetText(entry.note and PlainText(entry.note) or "")
            row.note:SetShown(entry.note ~= nil)
        end
    end
end

local function CreateWindow()
    window = CreateFrame("Frame", "DeathMarkFrame", UIParent, "BasicFrameTemplateWithInset")
    window:Hide()
    window:SetSize(470, 430)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        db.position = { point, relativePoint, x, y }
        DeathMarkDB = db
    end)
    if type(db.position) == "table" then
        local point, relativePoint, x, y = unpack(db.position)
        local anchors = { TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true, CENTER = true,
            RIGHT = true, BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true }
        if anchors[point] and anchors[relativePoint] and type(x) == "number" and type(y) == "number" then
            window:ClearAllPoints()
            window:SetPoint(point, UIParent, relativePoint, x, y)
        end
    end
    window.TitleText:SetText("DeathMark")
    table.insert(UISpecialFrames, "DeathMarkFrame")

    countText = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    countText:SetPoint("TOPLEFT", 20, -38)

    local scroll = CreateFrame("ScrollFrame", "DeathMarkScrollFrame", window, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 20, -62)
    scroll:SetPoint("BOTTOMRIGHT", -44, 44)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(scroll:GetWidth(), MAX_DEATHS * 52)
    scroll:SetScrollChild(content)

    for index = 1, MAX_DEATHS do
        local row = CreateFrame("Frame", nil, content)
        row:SetHeight(46)
        row:SetPoint("TOPLEFT", 0, -(index - 1) * 52)
        row:SetPoint("TOPRIGHT", 0, -(index - 1) * 52)
        row.line = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.line:SetPoint("TOPLEFT", 4, -4)
        row.line:SetPoint("TOPRIGHT", -4, -4)
        row.line:SetJustifyH("LEFT")
        row.note = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.note:SetPoint("TOPLEFT", 4, -22)
        row.note:SetPoint("TOPRIGHT", -4, -22)
        row.note:SetJustifyH("LEFT")
        row.note:SetTextColor(1, 0.82, 0)
        rows[index] = row
    end

    emptyText = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    emptyText:SetPoint("TOP", 0, -120)
    emptyText:SetWidth(400)
    emptyText:SetText(L["No deaths recorded."])

    hintText = window:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hintText:SetPoint("BOTTOM", 0, 16)
    hintText:SetWidth(430)
    hintText:SetText(L["Hint: /dm nota <text>"])

    window:SetScript("OnShow", RefreshWindow)
end

local function ToggleWindow()
    if not db then return end
    if not window then CreateWindow() end
    window:SetShown(not window:IsShown())
end

function DeathMark_Toggle()
    ToggleWindow()
end

local function OnPlayerDead()
    if not ApplyEvent(state, "PLAYER_DEAD") then return end
    local mapID, x, y = ReadPosition()
    local entry = BuildEntry(time(), Readable(UnitLevel("player")),
        Readable(GetZoneText()), Readable(GetSubZoneText()), mapID, x, y)
    if RecordDeath(db, entry) then
        DeathMarkDB = db
        local place = entry.zone or entry.subzone
        Notify(place and L["Recorded death in %s."]:format(place) or L["Recorded death."])
        if window and window:IsShown() then RefreshWindow() end
    else
        state.pending = false
    end
end

local function HandleSlash(message)
    local action, rest = ParseSlash(message)
    if action == "toggle" then
        ToggleWindow()
    elseif action == "note" then
        local ok, result = SetNote(db, rest)
        if ok then
            DeathMarkDB = db
            Notify(result == "shortened" and L["Note too long, shortened."] or L["Note saved."])
            if window and window:IsShown() then RefreshWindow() end
        else
            Notify(L["No death to annotate yet."])
        end
    elseif action == "note-missing" then
        Notify(L["Write a note after /dm nota."])
    else
        Notify(L["Unknown command. Use /dm or /dm nota <text>."])
    end
end

local minimapButton = CreateFrame("Button", "DeathMarkMinimapButton", Minimap)
minimapButton:SetSize(32, 32)
minimapButton:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 0, 0)
minimapButton:SetFrameLevel(Minimap:GetFrameLevel() + 8)
minimapButton:RegisterForClicks("LeftButtonUp")
minimapButton:SetMovable(true)
minimapButton:RegisterForDrag("LeftButton")
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
local minimapIcon = minimapButton:CreateTexture(nil, "BACKGROUND")
minimapIcon:SetSize(20, 20)
minimapIcon:SetPoint("CENTER", 0, 1)
minimapIcon:SetTexture(SKULL_TEXTURE)
local minimapBorder = minimapButton:CreateTexture(nil, "OVERLAY")
minimapBorder:SetSize(54, 54)
minimapBorder:SetPoint("TOPLEFT")
minimapBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
local function UpdateMinimapPosition()
    local angle = db and db.minimapAngle
    if type(angle) ~= "number" or angle ~= angle or math.abs(angle) == math.huge then return end
    local width, height = Minimap:GetWidth(), Minimap:GetHeight()
    if canaccessvalue and (not canaccessvalue(width) or not canaccessvalue(height)) then return end
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(angle) * (width / 2 + 8), math.sin(angle) * (height / 2 + 8))
end

local function DragMinimapButton()
    local x, y = GetCursorPosition()
    local centerX, centerY = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    if canaccessvalue and (not canaccessvalue(x) or not canaccessvalue(y)
        or not canaccessvalue(centerX) or not canaccessvalue(centerY) or not canaccessvalue(scale)) then return end
    if not centerX or not centerY then return end
    x, y = x / scale - centerX, y / scale - centerY
    if x == 0 and y == 0 then return end
    db.minimapAngle = math.atan2(y, x)
    UpdateMinimapPosition()
end

local function StopMinimapDrag(self)
    if self:GetScript("OnUpdate") then
        self:SetScript("OnUpdate", nil)
        DeathMarkDB = db
    end
    GameTooltip:Hide()
end

minimapButton:SetScript("OnDragStart", function(self)
    if not db then return end
    GameTooltip:Hide()
    self:SetScript("OnUpdate", DragMinimapButton)
end)
minimapButton:SetScript("OnDragStop", StopMinimapDrag)
minimapButton:SetScript("OnHide", StopMinimapDrag)
minimapButton:SetScript("OnClick", ToggleWindow)
minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("DeathMark", 1, 0.82, 0)
    GameTooltip:AddLine(L["Left-click: Open / close"], 1, 1, 1)
    GameTooltip:AddLine(L["Drag: Move"], 1, 1, 1)
    GameTooltip:Show()
end)
minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

local function InitializeDB()
    db = EnsureDB(DeathMarkDB)
    DeathMarkDB = db
    UpdateMinimapPosition()
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_DEAD")
events:RegisterEvent("PLAYER_ALIVE")
events:RegisterEvent("PLAYER_UNGHOST")
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == addonName then InitializeDB() end
    elseif event == "PLAYER_LOGIN" then
        InitializeDB()
    elseif event == "PLAYER_DEAD" then
        if db then OnPlayerDead() end
    elseif event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        ApplyEvent(state, event)
    end
end)

SLASH_DEATHMARK1 = "/deathmark"
SLASH_DEATHMARK2 = "/dm"
SlashCmdList["DEATHMARK"] = HandleSlash
