local addonName, addon = ...
addon = addon or {}
local L = addon.L

local function CleanPart(text)
    text = tostring(text or ""):gsub("%c", " "):match("^%s*(.-)%s*$")
    if text == "" or #text > 48 or text:find("|", 1, true) or text:find("%s") then
        return nil
    end
    return text
end

local function NameKey(firstName, surname)
    return string.lower(firstName) .. "\31" .. string.lower(surname)
end

local function SelectNewestDB(characterDB, backupDB)
    if type(characterDB) ~= "table" then characterDB = nil end
    if type(backupDB) ~= "table" then backupDB = nil end
    local characterRevision = tonumber(characterDB and characterDB.revision) or 0
    local backupRevision = tonumber(backupDB and backupDB.revision) or 0
    return backupRevision > characterRevision and backupDB or characterDB or backupDB or {}
end

-- Optional private recovery data stays outside the public addon.
local function ApplyLocalRecovery(db, characterKey, recovery)
    if recovery and characterKey == recovery.key and db.revision < recovery.revision and not next(db.enemies) then
        for key, enemy in pairs(recovery.enemies) do db.enemies[key] = enemy end
        db.revision = recovery.revision
    end
end

addon.ApplyLocalRecovery = ApplyLocalRecovery
addon.CleanPart = CleanPart
addon.NameKey = NameKey
addon.SelectNewestDB = SelectNewestDB

-- Allows the small standalone test to load the pure helpers without mocking WoW.
if not CreateFrame then return addon end

local db, backupRoot, backupKey, window, countText, statusText, firstNameInput, surnameInput, quickAddButton
local previousButton, nextButton, pager
local rows, visibleUnits, markedUnits = {}, {}, {}
local page = 1
local PAGE_SIZE = 8
local ICON_TEXTURE = "Interface\\AddOns\\Revenge\\Assets\\RevengeIconV2"
local BAR_TEXTURE = "Interface\\AddOns\\Revenge\\Assets\\RevengeBar"
local BACKGROUND_TEXTURE = "Interface\\AddOns\\Revenge\\Assets\\RevengeBackgroundV2"
local DELETE_TEXTURE = "Interface\\AddOns\\Revenge\\Assets\\RevengeTrash"

local function TouchDB()
    if not db then return end
    db.revision = (tonumber(db.revision) or 0) + 1
    RevengeDB = db
    if backupRoot and backupKey then
        backupRoot.characters[backupKey] = db
        RevengeBackupDB = backupRoot
    end
end

local function PlainText(text)
    return tostring(text or ""):gsub("|", "||")
end

local function Button(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, height or 30)
    button:SetText(text)
    return button
end

local function PageButton(parent, direction)
    local button = CreateFrame("Button", nil, parent)
    local texture = "Interface\\Buttons\\UI-SpellbookIcon-" .. direction .. "Page-"
    button:SetSize(28, 28)
    button:SetNormalTexture(texture .. "Up")
    button:SetPushedTexture(texture .. "Down")
    button:SetDisabledTexture(texture .. "Disabled")
    button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    return button
end

local function SetStatus(text, success)
    if statusText then
        statusText:SetText(text or "")
        statusText:SetTextColor(success and 0.35 or 1, success and 1 or 0.3, success and 0.35 or 0.3)
    end
    if (not window or not window:IsShown()) and DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffb81fe6Revenge:|r " .. (text or ""))
    end
end

local function IsEnemyPlayer(unit)
    return UnitExists(unit)
        and UnitIsPlayer(unit)
        and not UnitIsUnit(unit, "player")
        and (UnitCanAttack("player", unit) or not UnitIsFriend("player", unit))
end

local function ReadUnitName(unit)
    local firstName, surname = UnitName(unit)
    if firstName == nil or surname == nil then return nil end
    if canaccessvalue and (not canaccessvalue(firstName) or not canaccessvalue(surname)) then
        return nil
    end
    firstName, surname = CleanPart(firstName), CleanPart(surname)
    if not firstName or not surname then return nil end
    return firstName, surname
end

local function ReadUnitClass(unit)
    local class = UnitClassBase(unit)
    if class == nil or (canaccessvalue and not canaccessvalue(class)) then return nil end
    return class
end

local function SortedEnemies()
    local enemies = {}
    for key, enemy in pairs(db.enemies) do
        enemies[#enemies + 1] = {
            key = key,
            firstName = enemy.firstName,
            surname = enemy.surname,
            class = enemy.class,
        }
    end
    table.sort(enemies, function(a, b)
        local aName = string.lower(a.surname .. "\31" .. a.firstName)
        local bName = string.lower(b.surname .. "\31" .. b.firstName)
        return aName < bName
    end)
    return enemies
end

local function RefreshWindow()
    if not window then return end
    local enemies = SortedEnemies()
    local pages = math.max(1, math.ceil(#enemies / PAGE_SIZE))
    page = math.max(1, math.min(page, pages))
    countText:SetText(L["Saved enemies: %d"]:format(#enemies))
    pager:SetText(("%d / %d"):format(page, pages))
    previousButton:SetEnabled(page > 1)
    nextButton:SetEnabled(page < pages)

    for index, row in ipairs(rows) do
        local enemy = enemies[(page - 1) * PAGE_SIZE + index]
        row.enemyKey = enemy and enemy.key or nil
        row:SetShown(enemy ~= nil)
        if enemy then
            row.name:SetText(PlainText(enemy.firstName .. " " .. enemy.surname))
            local color = enemy.class and RAID_CLASS_COLORS[enemy.class]
            row.name:SetTextColor(color and color.r or 1, color and color.g or 0.95, color and color.b or 0.82)
            if enemy.class then
                row.icon:SetAtlas(GetClassAtlas(enemy.class))
            else
                row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                row.icon:SetTexCoord(0, 1, 0, 1)
            end
        end
    end
end

local function GetEnemyForUnit(unit)
    if not IsEnemyPlayer(unit) then return nil end
    local firstName, surname = ReadUnitName(unit)
    if not firstName then return nil end
    local enemy = db.enemies[NameKey(firstName, surname)]
    if enemy then
        enemy.firstName, enemy.surname = firstName, surname
        enemy.class = enemy.class or ReadUnitClass(unit)
    end
    return enemy
end

local function RefreshQuickAddButton()
    if not quickAddButton then return end
    quickAddButton:SetShown(db ~= nil)
end

local function EnsureMarker(unitFrame)
    if unitFrame.RevengeMarker then return end
    local healthBar = unitFrame.healthBar
    local glow = unitFrame:CreateTexture(nil, "BACKGROUND", nil, 7)
    glow:SetPoint("TOPLEFT", healthBar, -4, 4)
    glow:SetPoint("BOTTOMRIGHT", healthBar, 4, -4)
    glow:SetColorTexture(1, 0.02, 0.08, 0.85)
    glow:SetBlendMode("ADD")
    unitFrame.RevengeGlow = glow

    local marker = unitFrame:CreateTexture(nil, "OVERLAY", nil, 7)
    marker:SetSize(48, 48)
    marker:SetPoint("RIGHT", healthBar, "LEFT", -6, 0)
    marker:SetTexture(ICON_TEXTURE)
    unitFrame.RevengeMarker = marker
end

local function ApplyRevengeStyle(unitFrame)
    EnsureMarker(unitFrame)
    unitFrame.RevengeMarker:Show()
    unitFrame.RevengeGlow:Show()
    unitFrame.healthBar:SetStatusBarTexture(BAR_TEXTURE)
    unitFrame.healthBar:SetStatusBarColor(1, 1, 1)
    unitFrame.RevengeStyled = true
end

local function RestoreNativeStyle(unitFrame)
    if unitFrame.RevengeMarker then
        unitFrame.RevengeMarker:Hide()
        unitFrame.RevengeGlow:Hide()
    end
    if not unitFrame.RevengeStyled then return end
    if NamePlateSetupOptions and NamePlateSetupOptions.useClassicHealthBar then
        unitFrame.healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-TargetingFrame-BarFill")
    else
        unitFrame.healthBar.barTexture:SetAtlas("UI-HUD-CoolDownManager-Bar", true)
    end
    unitFrame.RevengeStyled = nil
    CompactUnitFrame_UpdateHealthColor(unitFrame)
end

local function ApplyToUnit(unit)
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    local unitFrame = plate and plate.UnitFrame
    if not unitFrame then
        markedUnits[unit] = nil
        return nil, false
    end

    local enemy = GetEnemyForUnit(unit)
    markedUnits[unit] = enemy and true or nil
    if enemy then
        ApplyRevengeStyle(unitFrame)
    else
        RestoreNativeStyle(unitFrame)
    end
    return unitFrame, enemy ~= nil
end

local function RefreshUnit(unit)
    ApplyToUnit(unit)
end

local function RefreshVisible()
    for unit in pairs(visibleUnits) do
        if UnitExists(unit) then
            RefreshUnit(unit)
        else
            visibleUnits[unit], markedUnits[unit] = nil, nil
        end
    end
    RefreshWindow()
    RefreshQuickAddButton()
end

local function AddEnemy(firstName, surname, class)
    firstName, surname = CleanPart(firstName), CleanPart(surname)
    if not firstName or not surname then
        return false, L["Enter a valid first name and surname without internal spaces."]
    end

    local playerFirstName, playerSurname = ReadUnitName("player")
    local key = NameKey(firstName, surname)
    if playerFirstName and key == NameKey(playerFirstName, playerSurname) then
        return false, L["You cannot add yourself."]
    end
    if db.enemies[key] then
        return false, L["%s is already on the list."]:format(firstName .. " " .. surname)
    end

    db.enemies[key] = { firstName = firstName, surname = surname, class = class }
    TouchDB()
    page = math.ceil((#SortedEnemies()) / PAGE_SIZE)
    RefreshVisible()
    return true, L["%s added."]:format(firstName .. " " .. surname)
end

local function AddManualEnemy()
    local success, message = AddEnemy(firstNameInput:GetText(), surnameInput:GetText())
    SetStatus(message, success)
    if success then
        firstNameInput:SetText("")
        surnameInput:SetText("")
        surnameInput:ClearFocus()
    end
end

local function AddTargetEnemy()
    if not UnitExists("target") then
        SetStatus(L["Select an enemy player first."], false)
        return
    end
    if not IsEnemyPlayer("target") then
        SetStatus(L["Your target must be an enemy player."], false)
        return
    end
    local firstName, surname = ReadUnitName("target")
    if not firstName then
        SetStatus(L["The game does not allow reading this target's full name."], false)
        return
    end
    local success, message = AddEnemy(firstName, surname, ReadUnitClass("target"))
    SetStatus(message, success)
end

quickAddButton = CreateFrame("Button", "RevengeQuickAddButton", UIParent)
quickAddButton:Hide()
quickAddButton:SetSize(46, 46)
quickAddButton:SetFrameStrata("LOW")
quickAddButton:SetClampedToScreen(true)
quickAddButton:SetMovable(true)
quickAddButton:EnableMouse(true)
quickAddButton:RegisterForClicks("LeftButtonUp")
quickAddButton:RegisterForDrag("RightButton")
if TargetFrame then
    quickAddButton:SetFrameLevel(TargetFrame:GetFrameLevel() + 1)
    quickAddButton:SetPoint("LEFT", TargetFrame, "RIGHT", -8, -4)
else
    quickAddButton:SetPoint("CENTER", UIParent, "CENTER", -200, -160)
end
quickAddButton:SetNormalTexture(ICON_TEXTURE)
quickAddButton:GetNormalTexture():SetAllPoints()
quickAddButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
quickAddButton:SetScript("OnClick", function()
    AddTargetEnemy()
    RefreshQuickAddButton()
end)
quickAddButton:SetScript("OnDragStart", function(self) self:StartMoving() end)
quickAddButton:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local x, y = self:GetCenter()
    local centerX, centerY = UIParent:GetCenter()
    if db and x and y and centerX and centerY then
        db.quickButtonPosition = { x - centerX, y - centerY }
        TouchDB()
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "CENTER", db.quickButtonPosition[1], db.quickButtonPosition[2])
    end
end)
quickAddButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L["Add to Revenge"], 0.72, 0.12, 0.90)
    GameTooltip:AddLine(L["Left-click: add target"], 1, 1, 1)
    GameTooltip:AddLine(L["Right-drag: move"], 0.7, 0.7, 0.7)
    GameTooltip:Show()
end)
quickAddButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

local function CreateWindow()
    window = CreateFrame("Frame", "RevengeFrame", UIParent, "BasicFrameTemplateWithInset")
    window:Hide()
    window:SetSize(520, 582)
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
        TouchDB()
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
    window.TitleText:SetText("Revenge")
    table.insert(UISpecialFrames, "RevengeFrame")
    if window.Inset then window.Inset:Hide() end
    local background = window:CreateTexture(nil, "ARTWORK", nil, -7)
    background:SetPoint("TOPLEFT", 8, -31)
    background:SetPoint("BOTTOMRIGHT", -8, 8)
    background:SetTexture(BACKGROUND_TEXTURE)
    background:SetTexCoord(0, 1, 0, 1)
    background:SetVertexColor(0.82, 0.82, 0.82)

    countText = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    countText:SetPoint("TOPLEFT", 24, -45)

    nextButton = PageButton(window, "Next")
    nextButton:SetPoint("TOPRIGHT", -22, -37)
    nextButton:SetScript("OnClick", function() page = page + 1; RefreshWindow() end)
    pager = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pager:SetSize(54, 28)
    pager:SetPoint("RIGHT", nextButton, "LEFT", -2, 0)
    pager:SetJustifyH("CENTER")
    previousButton = PageButton(window, "Prev")
    previousButton:SetPoint("RIGHT", pager, "LEFT", -2, 0)
    previousButton:SetScript("OnClick", function() page = page - 1; RefreshWindow() end)

    for index = 1, PAGE_SIZE do
        local row = CreateFrame("Frame", nil, window)
        row:SetSize(472, 40)
        row:SetPoint("TOPLEFT", 24, -72 - (index - 1) * 44)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(30, 30)
        row.icon:SetPoint("LEFT", 7, 0)
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.name:SetPoint("LEFT", 48, 0)
        row.name:SetSize(360, 34)
        row.name:SetJustifyH("LEFT")
        local deleteButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        deleteButton:SetSize(36, 36)
        deleteButton:SetPoint("RIGHT", -3, 0)
        local deleteIcon = deleteButton:CreateTexture(nil, "ARTWORK")
        deleteIcon:SetSize(28, 28)
        deleteIcon:SetPoint("CENTER")
        deleteIcon:SetTexture(DELETE_TEXTURE)
        deleteButton:SetScript("OnClick", function()
            local enemy = row.enemyKey and db.enemies[row.enemyKey]
            if not enemy then return end
            local displayName = enemy.firstName .. " " .. enemy.surname
            db.enemies[row.enemyKey] = nil
            TouchDB()
            RefreshVisible()
            SetStatus(L["%s removed."]:format(displayName), true)
        end)
        deleteButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(L["Remove enemy"], 1, 0.82, 0)
            GameTooltip:Show()
        end)
        deleteButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
        rows[index] = row
    end

    window:EnableMouseWheel(true)
    window:SetScript("OnMouseWheel", function(_, delta)
        page = page + (delta > 0 and -1 or 1)
        RefreshWindow()
    end)

    local separator = window:CreateTexture(nil, "ARTWORK")
    separator:SetColorTexture(0.55, 0.36, 0.12, 0.65)
    separator:SetPoint("TOPLEFT", 24, -434)
    separator:SetPoint("TOPRIGHT", -24, -434)
    separator:SetHeight(1)

    local targetButton = Button(window, L["Add current target"], 240, 32)
    targetButton:SetPoint("BOTTOMLEFT", 24, 12)
    targetButton:SetScript("OnClick", AddTargetEnemy)

    local firstNameLabel = window:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    firstNameLabel:SetPoint("TOPLEFT", 28, -460)
    firstNameLabel:SetText(L["First name"])
    firstNameInput = CreateFrame("EditBox", "RevengeFirstNameInput", window, "InputBoxTemplate")
    firstNameInput:SetSize(160, 30)
    firstNameInput:SetPoint("TOPLEFT", 24, -477)
    firstNameInput:SetAutoFocus(false)
    firstNameInput:SetMaxBytes(48)
    firstNameInput:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        surnameInput:SetFocus()
    end)

    local surnameLabel = window:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    surnameLabel:SetPoint("TOPLEFT", 204, -460)
    surnameLabel:SetText(L["Surname"])
    surnameInput = CreateFrame("EditBox", "RevengeSurnameInput", window, "InputBoxTemplate")
    surnameInput:SetSize(160, 30)
    surnameInput:SetPoint("TOPLEFT", 200, -477)
    surnameInput:SetAutoFocus(false)
    surnameInput:SetMaxBytes(48)
    surnameInput:SetScript("OnEnterPressed", AddManualEnemy)

    local addButton = Button(window, L["Add"], 116, 30)
    addButton:SetPoint("TOPLEFT", 380, -477)
    addButton:SetScript("OnClick", AddManualEnemy)

    statusText = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusText:SetPoint("BOTTOMLEFT", 280, 12)
    statusText:SetPoint("BOTTOMRIGHT", -24, 12)
    statusText:SetJustifyH("CENTER")

    local function EscapeInput(self)
        self:ClearFocus()
        window:Hide()
    end
    firstNameInput:SetScript("OnEscapePressed", EscapeInput)
    surnameInput:SetScript("OnEscapePressed", EscapeInput)
    window:SetScript("OnShow", RefreshWindow)
    window:SetScript("OnHide", function()
        firstNameInput:ClearFocus()
        surnameInput:ClearFocus()
    end)
end

local function ToggleWindow()
    if not db then return end
    if not window then CreateWindow() end
    window:SetShown(not window:IsShown())
end

local minimapButton = CreateFrame("Button", "RevengeMinimapButton", Minimap)
minimapButton:SetSize(32, 32)
minimapButton:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 2, 2)
minimapButton:SetFrameLevel(Minimap:GetFrameLevel() + 8)
minimapButton:RegisterForClicks("LeftButtonUp")
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
local minimapIcon = minimapButton:CreateTexture(nil, "BACKGROUND")
minimapIcon:SetSize(20, 20)
minimapIcon:SetPoint("CENTER", 0, 1)
minimapIcon:SetTexture(ICON_TEXTURE)
local minimapBorder = minimapButton:CreateTexture(nil, "OVERLAY")
minimapBorder:SetSize(54, 54)
minimapBorder:SetPoint("TOPLEFT")
minimapBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
minimapButton:SetScript("OnClick", ToggleWindow)
minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Revenge", 0.72, 0.12, 0.90)
    GameTooltip:AddLine(L["Click to show or hide your enemy list."], 1, 1, 1)
    GameTooltip:Show()
end)
minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
    if frame and frame.unit and markedUnits[frame.unit] and frame.healthBar then
        ApplyRevengeStyle(frame)
    end
end)

local function InitializeDB()
    backupRoot = type(RevengeBackupDB) == "table" and RevengeBackupDB or backupRoot or {}
    if type(backupRoot.characters) ~= "table" then backupRoot.characters = {} end
    backupKey = backupKey or UnitGUID("player")
    local backupDB = backupKey and backupRoot.characters[backupKey] or nil
    db = SelectNewestDB(RevengeDB, backupDB)
    if type(db.enemies) ~= "table" then db.enemies = {} end
    db.revision = tonumber(db.revision) or 0
    ApplyLocalRecovery(db, backupKey, WoWForeverLocal and WoWForeverLocal.RevengeRecovery)
    RevengeDB = db
    RevengeBackupDB = backupRoot
    if backupKey then backupRoot.characters[backupKey] = db end
    local position = db.quickButtonPosition
    if type(position) == "table" and type(position[1]) == "number" and type(position[2]) == "number" then
        quickAddButton:ClearAllPoints()
        quickAddButton:SetPoint("CENTER", UIParent, "CENTER", position[1], position[2])
    end
    RefreshQuickAddButton()
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_LOGOUT")
events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
events:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
events:RegisterEvent("UNIT_NAME_UPDATE")
events:RegisterEvent("UNIT_FACTION")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == addonName then InitializeDB() end
    elseif event == "PLAYER_LOGIN" then
        InitializeDB()
    elseif event == "PLAYER_LOGOUT" then
        if db then
            RevengeDB = db
            if backupRoot and backupKey then
                backupRoot.characters[backupKey] = db
                RevengeBackupDB = backupRoot
            end
        end
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        visibleUnits[arg1] = true
        C_Timer.After(0, function()
            if visibleUnits[arg1] then
                ApplyToUnit(arg1)
                RefreshWindow()
            end
        end)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        visibleUnits[arg1], markedUnits[arg1] = nil, nil
    elseif event == "UNIT_NAME_UPDATE" or event == "UNIT_FACTION" then
        if visibleUnits[arg1] then
            RefreshUnit(arg1)
            RefreshWindow()
        end
        if arg1 == "target" then RefreshQuickAddButton() end
    elseif event == "PLAYER_ENTERING_WORLD" then
        wipe(visibleUnits)
        wipe(markedUnits)
        RefreshQuickAddButton()
    elseif event == "PLAYER_TARGET_CHANGED" then
        RefreshQuickAddButton()
    end
end)

SLASH_REVENGE1 = "/rvg"
SlashCmdList.REVENGE = ToggleWindow
