local addonName, addon = ...
addon = addon or {}
local L = addon.L

local SCHEMA = 1
local MAX_PINS = 20
local MAX_NOTE_BYTES = 140

addon.SCHEMA = SCHEMA
addon.MAX_PINS = MAX_PINS
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

local function CleanZone(text)
    if text == nil then return nil end
    text = tostring(text):gsub("%c", " "):match("^%s*(.-)%s*$")
    if text == "" then return nil end
    return text
end

local function IsValidPin(entry)
    if type(entry) ~= "table" then return false end
    if type(entry.id) ~= "number" then return false end
    if type(entry.mapID) ~= "number" then return false end
    if type(entry.x) ~= "number" or entry.x < 0 or entry.x > 1 then return false end
    if type(entry.y) ~= "number" or entry.y < 0 or entry.y > 1 then return false end
    if type(entry.note) ~= "string" or entry.note == "" or #entry.note > MAX_NOTE_BYTES then
        return false
    end
    if entry.zone ~= nil and type(entry.zone) ~= "string" then return false end
    if entry.created ~= nil and type(entry.created) ~= "number" then return false end
    return true
end

-- Normalizes the per-character database without overwriting valid data.
-- Unknown keys are preserved; invalid entries are dropped; the list is
-- pruned to the newest MAX_PINS entries; nextID never moves backwards.
local function EnsureDB(raw)
    local db = type(raw) == "table" and raw or {}
    local pins = {}
    if type(db.pins) == "table" then
        for _, entry in ipairs(db.pins) do
            if IsValidPin(entry) then
                pins[#pins + 1] = entry
                if #pins == MAX_PINS then break end
            end
        end
    end
    db.pins = pins
    local maxID = 0
    for _, entry in ipairs(pins) do
        if entry.id > maxID then maxID = entry.id end
    end
    local nextID = maxID + 1
    if type(db.nextID) == "number" and db.nextID > nextID then
        nextID = db.nextID
    end
    if nextID < 1 then nextID = 1 end
    db.nextID = nextID
    db.schema = SCHEMA
    return db
end

-- Inserts newest first. A full list blocks the insert: it never deletes
-- silently, the caller reports "full" to the player instead.
local function AddPin(db, fields)
    if type(db) ~= "table" or type(fields) ~= "table" then return false, "invalid" end
    if type(db.pins) ~= "table" then db.pins = {} end
    if #db.pins >= MAX_PINS then return false, "full" end
    if type(fields.mapID) ~= "number" then return false, "invalid" end
    if type(fields.x) ~= "number" or fields.x < 0 or fields.x > 1 then
        return false, "invalid"
    end
    if type(fields.y) ~= "number" or fields.y < 0 or fields.y > 1 then
        return false, "invalid"
    end
    local note = CleanNote(fields.note)
    if note == nil then return false, "invalid" end
    local id = db.nextID
    if type(id) ~= "number" or id < 1 then
        local maxID = 0
        for _, entry in ipairs(db.pins) do
            if type(entry.id) == "number" and entry.id > maxID then maxID = entry.id end
        end
        id = maxID + 1
    end
    local pin = {
        id = id,
        mapID = fields.mapID,
        x = fields.x,
        y = fields.y,
        zone = CleanZone(fields.zone),
        note = note,
        created = type(fields.created) == "number" and fields.created or nil,
    }
    table.insert(db.pins, 1, pin)
    db.nextID = id + 1
    return pin
end

local function DeletePin(db, id)
    if type(db) ~= "table" or type(db.pins) ~= "table" then return false end
    for index, entry in ipairs(db.pins) do
        if entry.id == id then
            table.remove(db.pins, index)
            return true
        end
    end
    return false
end

local function ParseSlash(message)
    local text = tostring(message or ""):match("^%s*(.-)%s*$")
    if text == "" then return "toggle" end
    local command, rest = text:match("^(%S+)%s*(.-)%s*$")
    if command and command:lower() == "add" then
        if (rest or "") == "" then return "add-missing" end
        return "add", rest
    end
    if command and command:lower() == "place" then
        return "place"
    end
    return "unknown"
end

local function FormatCoords(pin)
    if pin.x and pin.y then
        return ("%.1f, %.1f"):format(pin.x * 100, pin.y * 100)
    end
    return "?"
end

addon.CleanNote = CleanNote
addon.CleanZone = CleanZone
addon.IsValidPin = IsValidPin
addon.EnsureDB = EnsureDB
addon.AddPin = AddPin
addon.DeletePin = DeletePin
addon.ParseSlash = ParseSlash
addon.FormatCoords = FormatCoords

-- Allows the small standalone test to load the pure helpers without mocking WoW.
if not CreateFrame then return addon end

local db, window, countText, emptyText, hintText, mapButton
local rows = {}
local providerInstance, providerRegistered, mapHooked, mapButtonAdded = nil, false, false, false
local placing = false

local function Readable(value)
    if value == nil then return nil end
    if canaccessvalue and not canaccessvalue(value) then return nil end
    return value
end

-- Player position following the DeathMark pattern: pcall plus secret-value
-- guards. A nil map or nil coordinates (indoors, instances) stays nil.
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

local function ReadZoneForMap(mapID)
    if C_Map and C_Map.GetMapInfo then
        local ok, info = pcall(C_Map.GetMapInfo, mapID)
        if ok and type(info) == "table" then
            return CleanZone(Readable(info.name))
        end
    end
    return nil
end

local function Notify(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffb81fe6Waymark:|r " .. message)
    end
end

local function PlainText(text)
    return tostring(text or ""):gsub("|", "||")
end

local function FormatDetail(pin)
    local place = pin.zone or L["Unknown place"]
    local stamp = pin.created and date("%Y-%m-%d %H:%M", pin.created) or "?"
    return place .. " [" .. FormatCoords(pin) .. "] · " .. stamp
end

local function RefreshPins()
    if providerInstance and providerInstance.RefreshAllData then
        providerInstance:RefreshAllData()
    end
end

local function RefreshWindow()
    if not window then return end
    countText:SetText(L["Waymarks: %d"]:format(#db.pins))
    emptyText:SetShown(#db.pins == 0)
    for index, row in ipairs(rows) do
        local pin = db.pins[index]
        row:SetShown(pin ~= nil)
        if pin then
            row.note:SetText(PlainText(pin.note))
            row.line:SetText(PlainText(FormatDetail(pin)))
        end
    end
end

-- Removes one pin from the UI side: database, map refresh, list refresh,
-- chat message. The pure DeletePin above only edits the table.
local function RemovePin(id)
    if DeletePin(db, id) then
        WaymarkDB = db
        RefreshPins()
        RefreshWindow()
        Notify(L["Waymark deleted."])
    end
end

local function GotoPin(pin)
    if type(WorldMapFrame) ~= "table" then return end
    if type(WorldMapFrame.Show) == "function" then WorldMapFrame:Show() end
    if type(WorldMapFrame.SetMapID) == "function" then
        WorldMapFrame:SetMapID(pin.mapID)
    end
end

local function EnsurePopups()
    if type(StaticPopupDialogs) ~= "table" then return end
    if not StaticPopupDialogs["WAYMARK_ADD"] then
        StaticPopupDialogs["WAYMARK_ADD"] = {
            text = L["Add waymark"] .. " — %s",
            button1 = L["Save"],
            button2 = L["Cancel"],
            hasEditBox = true,
            maxLetters = MAX_NOTE_BYTES,
            timeout = 0,
            exclusive = true,
            hideOnEscape = true,
            whileDead = true,
            OnShow = function(self)
                local box = self.editBox or (self.GetEditBox and self:GetEditBox())
                if box and box.SetText then box:SetText("") end
            end,
            -- The pin is created here on accept, never on popup open, so
            -- cancelling leaves no orphan pin without a note behind.
            OnAccept = function(self, data)
                data = data or (self and self.data)
                if type(data) ~= "table" then return end
                local box = self and (self.editBox or (self.GetEditBox and self:GetEditBox()))
                local note = box and box.GetText and box:GetText()
                local pin, err = AddPin(db, {
                    mapID = data.mapID,
                    x = data.x,
                    y = data.y,
                    zone = data.zone,
                    note = note,
                    created = (time and time()) or nil,
                })
                if not pin then
                    if err == "full" then Notify(L["Waymark list is full (20)."]) end
                    return
                end
                WaymarkDB = db
                RefreshPins()
                RefreshWindow()
                Notify(pin.zone and L["Waymark saved in %s."]:format(pin.zone)
                    or L["Waymark saved."])
            end,
        }
    end
    if not StaticPopupDialogs["WAYMARK_VIEW"] then
        StaticPopupDialogs["WAYMARK_VIEW"] = {
            text = "%s",
            button1 = L["Delete"],
            button2 = L["Close"],
            timeout = 0,
            exclusive = true,
            hideOnEscape = true,
            whileDead = true,
            OnAccept = function(self, data)
                data = data or (self and self.data)
                if type(data) ~= "table" then return end
                RemovePin(data.id)
            end,
        }
    end
end

local function ShowAddPopup(mapID, x, y, zone)
    if type(StaticPopup_Show) ~= "function" then return end
    EnsurePopups()
    StaticPopup_Show("WAYMARK_ADD", zone or L["Unknown place"], nil,
        { mapID = mapID, x = x, y = y, zone = zone })
end

local function ShowViewPopup(pin)
    if type(StaticPopup_Show) ~= "function" then return end
    EnsurePopups()
    StaticPopup_Show("WAYMARK_VIEW",
        PlainText(pin.note) .. "\n" .. PlainText(FormatDetail(pin)), nil, pin)
end

-- World-map pins. The canvas owns the wiring: it calls OnAcquired when a pin
-- leaves the pool and OnMouseEnter/OnMouseLeave/OnClick on interaction, so no
-- OnEnter/OnLeave/OnClick scripts are set here. OnAcquired resets the full
-- state because pins are reused from the pool.
if type(CreateFromMixins) == "function" and MapCanvasDataProviderMixin then
    WaymarkDataProviderMixin = CreateFromMixins(MapCanvasDataProviderMixin)
else
    WaymarkDataProviderMixin = {}
end
if type(CreateFromMixins) == "function" and MapCanvasPinMixin then
    WaymarkPinMixin = CreateFromMixins(MapCanvasPinMixin)
else
    WaymarkPinMixin = {}
end

function WaymarkDataProviderMixin:RefreshAllData()
    if type(self.RemoveAllPinsByTemplate) ~= "function" then return end
    self:RemoveAllPinsByTemplate("WaymarkPinTemplate")
    if type(self.GetMap) ~= "function" or type(self.AcquirePin) ~= "function" then
        return
    end
    local map = self:GetMap()
    if type(map) ~= "table" or type(map.GetMapID) ~= "function" then return end
    local currentMapID = map:GetMapID()
    if type(currentMapID) ~= "number" then return end
    if type(db) ~= "table" or type(db.pins) ~= "table" then return end
    for _, pinData in ipairs(db.pins) do
        if pinData.mapID == currentMapID then
            local pin = self:AcquirePin("WaymarkPinTemplate", pinData)
            if pin and type(pin.SetPosition) == "function" then
                pin:SetPosition(pinData.x, pinData.y)
            end
        end
    end
end

function WaymarkPinMixin:OnAcquired(pinData)
    self.pinData = pinData
end

function WaymarkPinMixin:OnReleased()
    self.pinData = nil
end

function WaymarkPinMixin:OnMouseEnter()
    local pinData = self.pinData
    if not pinData then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(PlainText(pinData.note) or L["Waymark"], 1, 0.82, 0)
    GameTooltip:AddLine(PlainText(FormatDetail(pinData)), 1, 1, 1)
    GameTooltip:AddLine(L["Click: View / delete"], 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

function WaymarkPinMixin:OnMouseLeave()
    GameTooltip:Hide()
end

function WaymarkPinMixin:OnClick(button)
    if button == "LeftButton" and self.pinData then
        ShowViewPopup(self.pinData)
    end
end

-- Placing mode needs no keyboard: arming happens on the map button (or
-- /wm place) and the next left click on the canvas plants the pin.
local function UpdateMapButton()
    if not mapButton then return end
    mapButton:SetText(placing and L["Placing…"] or L["Waymark"])
end

local function ArmPlacing()
    if not db then return end
    if type(db.pins) == "table" and #db.pins >= MAX_PINS then
        Notify(L["Waymark list is full (20)."])
        return
    end
    placing = true
    UpdateMapButton()
    Notify(L["Click the map to place your waymark. Click the button again to cancel."])
end

local function CancelPlacing(silent)
    if not placing then return end
    placing = false
    UpdateMapButton()
    if not silent then Notify(L["Placing cancelled."]) end
end

local function TogglePlacing()
    if placing then CancelPlacing() else ArmPlacing() end
end

local function HookPlacementClick()
    if mapHooked then return end
    if type(WorldMapFrame) ~= "table" then return end
    local scroll = WorldMapFrame.ScrollContainer
    if type(scroll) ~= "table" or type(scroll.HookScript) ~= "function" then return end
    -- GetNormalizedCursorPosition always returns clamped 0..1 values, hence
    -- the IsMouseOver guard: without it clicks on map chrome would plant a
    -- pin on the nearest edge.
    scroll:HookScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" then return end
        if not placing then return end
        if type(scroll.IsMouseOver) == "function" and not scroll:IsMouseOver() then
            return
        end
        -- Overlap guard: a click landing on an existing pin lets that pin
        -- open its popup instead of planting a second pin underneath.
        if type(WorldMapFrame.EnumeratePinsByTemplate) == "function" then
            local ok, iterator = pcall(WorldMapFrame.EnumeratePinsByTemplate,
                WorldMapFrame, "WaymarkPinTemplate")
            if ok and type(iterator) == "function" then
                for pin in iterator do
                    if pin and type(pin.IsMouseOver) == "function" then
                        local hoveredOk, hovered = pcall(pin.IsMouseOver, pin)
                        if hoveredOk and hovered then return end
                    end
                end
            end
        end
        if type(scroll.GetNormalizedCursorPosition) ~= "function" then return end
        local x, y = scroll:GetNormalizedCursorPosition()
        if type(x) ~= "number" or type(y) ~= "number" then return end
        if x < 0 or x > 1 or y < 0 or y > 1 then return end
        local mapID
        if type(WorldMapFrame.GetMapID) == "function" then
            local ok, id = pcall(WorldMapFrame.GetMapID, WorldMapFrame)
            if ok and type(id) == "number" then mapID = id end
        end
        if type(mapID) ~= "number" then return end
        if db and type(db.pins) == "table" and #db.pins >= MAX_PINS then
            Notify(L["Waymark list is full (20)."])
            return
        end
        -- Disarm before the popup so the note dialog never leaves us armed.
        CancelPlacing(true)
        ShowAddPopup(mapID, x, y, ReadZoneForMap(mapID))
    end)
    mapHooked = true
end

local function CreateWindow()
    window = CreateFrame("Frame", "WaymarkFrame", UIParent, "BasicFrameTemplateWithInset")
    window:Hide()
    window:SetSize(470, 460)
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
        WaymarkDB = db
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
    window.TitleText:SetText("Waymark")
    table.insert(UISpecialFrames, "WaymarkFrame")

    countText = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    countText:SetPoint("TOPLEFT", 20, -38)

    local scroll = CreateFrame("ScrollFrame", "WaymarkScrollFrame", window, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 20, -62)
    scroll:SetPoint("BOTTOMRIGHT", -44, 44)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(scroll:GetWidth(), MAX_PINS * 60)
    scroll:SetScrollChild(content)

    for index = 1, MAX_PINS do
        local row = CreateFrame("Frame", nil, content)
        row:SetHeight(54)
        row:SetPoint("TOPLEFT", 0, -(index - 1) * 60)
        row:SetPoint("TOPRIGHT", 0, -(index - 1) * 60)
        row.note = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.note:SetPoint("TOPLEFT", 4, -4)
        row.note:SetPoint("TOPRIGHT", -116, -4)
        row.note:SetJustifyH("LEFT")
        row.line = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.line:SetPoint("TOPLEFT", 4, -22)
        row.line:SetPoint("TOPRIGHT", -116, -22)
        row.line:SetJustifyH("LEFT")
        row.go = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.go:SetSize(52, 20)
        row.go:SetPoint("TOPRIGHT", -56, -4)
        row.go:SetText(L["Go to"])
        row.go:SetScript("OnClick", function()
            local pin = db.pins[index]
            if pin then GotoPin(pin) end
        end)
        row.remove = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.remove:SetSize(52, 20)
        row.remove:SetPoint("TOPRIGHT", 0, -4)
        row.remove:SetText(L["Delete"])
        row.remove:SetScript("OnClick", function()
            local pin = db.pins[index]
            if pin then RemovePin(pin.id) end
        end)
        rows[index] = row
    end

    emptyText = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    emptyText:SetPoint("TOP", 0, -140)
    emptyText:SetWidth(400)
    emptyText:SetText(L["No waymarks yet. Use the Waymark button on the world map to add one."])

    hintText = window:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hintText:SetPoint("BOTTOM", 0, 16)
    hintText:SetWidth(430)
    hintText:SetText(L["Click the map to place your waymark. Click the button again to cancel."])

    window:SetScript("OnShow", RefreshWindow)
    addon._rows = rows
end

local function ToggleWindow()
    if not db then return end
    if not window then CreateWindow() end
    window:SetShown(not window:IsShown())
end

function Waymark_Toggle()
    ToggleWindow()
end

-- World-map buttons: Waymark toggles placing mode, List toggles the window.
-- Closing the map (Esc/X) silently disarms placing; right click never
-- cancels because it is needed to zoom and navigate while armed.
local function AddMapButton()
    if mapButtonAdded then return end
    if type(WorldMapFrame) ~= "table" then return end
    local listButton = CreateFrame("Button", "WaymarkListButton", WorldMapFrame, "UIPanelButtonTemplate")
    listButton:SetSize(60, 22)
    listButton:SetPoint("TOPRIGHT", WorldMapFrame, "TOPRIGHT", -216, -28)
    listButton:SetText(L["List"])
    listButton:SetScript("OnClick", ToggleWindow)
    listButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Waymark", 1, 0.82, 0)
        GameTooltip:AddLine(L["Open list"], 1, 1, 1)
        GameTooltip:Show()
    end)
    listButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    mapButton = CreateFrame("Button", "WaymarkMapButton", WorldMapFrame, "UIPanelButtonTemplate")
    mapButton:SetSize(90, 22)
    mapButton:SetPoint("TOPRIGHT", WorldMapFrame, "TOPRIGHT", -120, -28)
    mapButton:SetText(L["Waymark"])
    mapButton:SetScript("OnClick", TogglePlacing)
    mapButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Waymark", 1, 0.82, 0)
        GameTooltip:AddLine(placing and L["Placing…"] or L["Waymark button: Add waymark"], 1, 1, 1)
        GameTooltip:Show()
    end)
    mapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    if type(WorldMapFrame.HookScript) == "function" then
        WorldMapFrame:HookScript("OnHide", function() CancelPlacing(true) end)
    end
    mapButtonAdded = true
end

local function RegisterProvider()
    if providerRegistered then return true end
    if type(WorldMapFrame) ~= "table" or type(WorldMapFrame.AddDataProvider) ~= "function" then
        return false
    end
    local instance
    if type(CreateFromMixins) == "function" then
        instance = CreateFromMixins(WaymarkDataProviderMixin)
    else
        instance = setmetatable({}, { __index = WaymarkDataProviderMixin })
    end
    WorldMapFrame:AddDataProvider(instance)
    providerInstance = instance
    addon._providerInstance = instance
    providerRegistered = true
    HookPlacementClick()
    AddMapButton()
    RefreshPins()
    return true
end

local function InitializeDB()
    db = EnsureDB(WaymarkDB)
    WaymarkDB = db
end

local function AddAtPlayer(note)
    local mapID, x, y = ReadPosition()
    if type(mapID) ~= "number" or type(x) ~= "number" or type(y) ~= "number" then
        Notify(L["Unknown position here."])
        return
    end
    local zone = ReadZoneForMap(mapID)
    if zone == nil and GetZoneText then
        zone = CleanZone(Readable(GetZoneText()))
    end
    local pin, err = AddPin(db, {
        mapID = mapID,
        x = x,
        y = y,
        zone = zone,
        note = note,
        created = (time and time()) or nil,
    })
    if not pin then
        Notify(err == "full" and L["Waymark list is full (20)."] or L["Unknown position here."])
        return
    end
    WaymarkDB = db
    RefreshPins()
    RefreshWindow()
    Notify(pin.zone and L["Waymark saved in %s."]:format(pin.zone) or L["Waymark saved."])
end

local function HandleSlash(message)
    local action, rest = ParseSlash(message)
    if action == "toggle" then
        ToggleWindow()
    elseif action == "place" then
        if type(WorldMapFrame) == "table" and type(WorldMapFrame.Show) == "function" then
            WorldMapFrame:Show()
        end
        ArmPlacing()
    elseif action == "add" then
        AddAtPlayer(rest)
    elseif action == "add-missing" then
        Notify(L["Write a note after /wm add."])
    else
        Notify(L["Unknown command. Use /wm, /wm place or /wm add <text>."])
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == addonName then
            InitializeDB()
        elseif arg1 == "Blizzard_WorldMap" then
            RegisterProvider()
        end
    elseif event == "PLAYER_LOGIN" then
        InitializeDB()
        RegisterProvider()
    end
end)

SLASH_WAYMARK1 = "/wm"
SLASH_WAYMARK2 = "/waymark"
SlashCmdList["WAYMARK"] = HandleSlash
