local _, beta = ...
local L = beta.L
local betaDB = TDLDB
if beta.character then TDLDB = beta.native end

local db, window, input, saveButton, cancelButton, editorLabel, scroll, content
local rows, editing = {}, nil
local Refresh

local function PlainText(text)
    return (text:gsub("|", "||"))
end

local function Button(parent, text, width)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 24)
    button:SetText(text)
    return button
end

local function ResetEditor()
    editing = nil
    input:SetText("")
    input:ClearFocus()
    editorLabel:SetText(L["New task"])
    saveButton:SetText(L["Add"])
    cancelButton:Hide()
    input:SetPoint("RIGHT", saveButton, "LEFT", -12, 0)
end

local function CreateRow(i)
    local row = CreateFrame("Button", nil, content)
    row:SetHeight(38)
    row:SetPoint("TOPLEFT")
    row:SetPoint("TOPRIGHT")
    local background = row:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(1, 0.82, 0.4, i % 2 == 1 and 0.06 or 0.02)
    row.check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    row.check:SetPoint("TOPLEFT", 0, -3)
    row.check:SetScript("OnClick", function(self)
        row.task.done = self:GetChecked() and true or false
        Refresh()
    end)
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.text:SetPoint("TOPLEFT", 38, -12)
    row.text:SetPoint("TOPRIGHT", -52, -12)
    row.text:SetJustifyH("LEFT")
    row.text:SetJustifyV("TOP")
    row.disclosure = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.disclosure:SetPoint("TOPRIGHT", -34, -12)
    row:SetScript("OnClick", function()
        if row.canExpand then
            row.expanded = not row.expanded
            Refresh()
        end
    end)

    local edit = Button(row, L["Edit"], 72)
    row.edit = edit
    edit:SetPoint("BOTTOMRIGHT", -112, 8)
    edit:SetScript("OnClick", function()
        editing = row.task
        editorLabel:SetText(L["Edit task"])
        input:SetText(editing.text)
        saveButton:SetText(L["Save"])
        cancelButton:Show()
        input:SetPoint("RIGHT", cancelButton, "LEFT", -12, 0)
        input:SetFocus()
        input:HighlightText()
    end)
    local delete = Button(row, L["Delete"], 78)
    row.delete = delete
    delete:SetPoint("BOTTOMRIGHT", -30, 8)
    delete:SetScript("OnClick", function()
        StaticPopup_Show("TDL_DELETE", PlainText(row.task.text), nil, row.task)
    end)
    return row
end

Refresh = function()
    -- ponytail: one frame per task; virtualize only if large lists make refresh slow.
    for i = #rows + 1, #db.tasks do rows[i] = CreateRow(i) end
    local height = 0
    for i, row in ipairs(rows) do
        local task = db.tasks[i]
        if row.task ~= task then row.expanded = false end
        row.task = task
        row:SetShown(task ~= nil)
        if task then
            row.check:SetChecked(task.done)
            row.text:SetText(PlainText(task.text))
            row.canExpand = row.text:GetUnboundedStringWidth() > row.text:GetWidth()
            row.expanded = row.expanded and row.canExpand
            row.text:SetWordWrap(row.expanded or false)
            row.text:SetNonSpaceWrap(row.expanded or false)
            row.text:SetHeight(0)
            local textHeight = row.expanded and row.text:GetStringHeight() or row.text:GetLineHeight()
            row.text:SetHeight(textHeight)
            row:SetHeight(math.max(38, textHeight + 24) + 32)
            row.disclosure:SetText(row.expanded and "-" or "+")
            row.disclosure:SetShown(row.canExpand)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 0, -height)
            row:SetPoint("TOPRIGHT", 0, -height)
            height = height + row:GetHeight() + 2
            if task.done then
                row.text:SetTextColor(0.5, 0.8, 0.5)
            else
                row.text:SetTextColor(1, 0.95, 0.82)
            end
        end
    end
    content:SetHeight(math.max(1, height - 2))
    scroll:UpdateScrollChildRect()
    scroll.ScrollBar:SetValue(math.min(scroll.ScrollBar:GetValue(), scroll:GetVerticalScrollRange()))
end

local function SaveTask()
    local text = input:GetText():gsub("%c", " "):match("^%s*(.-)%s*$")
    if text == "" or #text > 240 then
        editorLabel:SetText(text == "" and L["Enter a task before saving."] or L["Shorten the task text."])
        input:SetFocus()
        return
    end
    local adding = not editing
    if editing then
        editing.text = text
    else
        table.insert(db.tasks, { text = text, done = false })
    end
    ResetEditor()
    Refresh()
    if adding then scroll.ScrollBar:SetValue(scroll:GetVerticalScrollRange()) end
end

StaticPopupDialogs["TDL_DELETE"] = {
    text = L["Delete this task?\n\n%s"],
    button1 = L["Delete"],
    button2 = L["Cancel"],
    OnAccept = function(_, task)
        for i, item in ipairs(db.tasks) do
            if item == task then
                table.remove(db.tasks, i)
                if editing == task then ResetEditor() end
                Refresh()
                break
            end
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

local function CreateWindow()
    window = CreateFrame("Frame", "TDLFrame", UIParent, "BasicFrameTemplateWithInset")
    window:Hide()
    window:SetSize(600, 480)
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
    end)
    if type(db.position) == "table" then
        local point, relativePoint, x, y = unpack(db.position)
        local anchors = { TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true,
            CENTER = true, RIGHT = true, BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true }
        if anchors[point] and anchors[relativePoint] and type(x) == "number" and type(y) == "number" then
            window:ClearAllPoints()
            window:SetPoint(point, UIParent, relativePoint, x, y)
        end
    end
    window.TitleText:SetText(L["My tasks"])
    table.insert(UISpecialFrames, "TDLFrame")
    if window.Inset then window.Inset:Hide() end
    local background = window:CreateTexture(nil, "ARTWORK", nil, -7)
    background:SetPoint("TOPLEFT", 8, -31)
    background:SetPoint("BOTTOMRIGHT", -8, 8)
    background:SetTexture("Interface\\AddOns\\TDL\\Assets\\Background")
    background:SetTexCoord(0, 1, 0, 1)
    background:SetVertexColor(0.82, 0.82, 0.82)

    scroll = CreateFrame("ScrollFrame", "TDLScrollFrame", window, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 20, -40)
    scroll:SetPoint("BOTTOMRIGHT", -20, 80)
    scroll.ScrollBar:ClearAllPoints()
    scroll.ScrollBar:SetPoint("TOPRIGHT", 0, -16)
    scroll.ScrollBar:SetPoint("BOTTOMRIGHT", 0, 16)
    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(scroll:GetWidth(), 1)
    scroll:SetScrollChild(content)

    editorLabel = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    editorLabel:SetPoint("BOTTOMLEFT", 20, 58)
    input = CreateFrame("EditBox", "TDLInput", window, "InputBoxTemplate")
    input:SetHeight(26)
    input:SetPoint("BOTTOMLEFT", 26, 20)
    input:SetAutoFocus(false)
    input:SetMaxBytes(240)
    input:SetScript("OnEnterPressed", SaveTask)
    input:SetScript("OnEscapePressed", function(self)
        if editing then ResetEditor() else self:ClearFocus(); window:Hide() end
    end)
    saveButton = Button(window, L["Add"], 94)
    saveButton:SetPoint("BOTTOMRIGHT", -20, 21)
    saveButton:SetScript("OnClick", SaveTask)
    cancelButton = Button(window, L["Cancel"], 94)
    cancelButton:SetPoint("RIGHT", saveButton, "LEFT", -8, 0)
    cancelButton:SetScript("OnClick", ResetEditor)

    window:SetScript("OnShow", Refresh)
    window:SetScript("OnHide", function()
        input:ClearFocus()
        GameTooltip:Hide()
        StaticPopup_Hide("TDL_DELETE")
    end)
    ResetEditor()
end

function TDL_Toggle()
    if not db then return end
    if not window then CreateWindow() end
    window:SetShown(not window:IsShown())
end

local minimapButton = CreateFrame("Button", "TDLMinimapButton", Minimap)
minimapButton:SetSize(32, 32)
minimapButton:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 0, 0)
minimapButton:SetFrameLevel(Minimap:GetFrameLevel() + 8)
minimapButton:RegisterForClicks("LeftButtonUp")
minimapButton:SetMovable(true)
minimapButton:RegisterForDrag("LeftButton")
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
local icon = minimapButton:CreateTexture(nil, "BACKGROUND")
icon:SetSize(20, 20)
icon:SetPoint("CENTER", 0, 1)
icon:SetTexture("Interface\\AddOns\\TDL\\Assets\\Icon")
local border = minimapButton:CreateTexture(nil, "OVERLAY")
border:SetSize(54, 54)
border:SetPoint("TOPLEFT")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
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
minimapButton:SetScript("OnClick", TDL_Toggle)
minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("TDL", 1, 0.82, 0)
    GameTooltip:AddLine(L["Left-click: Open / close"], 1, 1, 1)
    GameTooltip:AddLine(L["Drag: Move"], 1, 1, 1)
    GameTooltip:Show()
end)
minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function(self, event, isInitialLogin, isReloadingUi)
    if event == "PLAYER_ENTERING_WORLD" then
        if db and (isInitialLogin or isReloadingUi) then
            for _, task in ipairs(db.tasks) do
                if not task.done then
                    if not window then CreateWindow() end
                    window:Show()
                    break
                end
            end
        end
        return
    end
    -- ponytail: this beta workaround covers the character configured in Beta.lua;
    -- remove it and the Data TOC entry once the native loader works.
    if TDLDB == nil and beta.character then
        local firstName, surname = UnitNameUnmodified("player")
        local character = NameUtil.GetFullNameWithoutRealm(firstName, surname):gsub("%s+", "-")
        if character == beta.character and GetRealmName() == beta.realm then
            TDLDB = betaDB
        end
    end
    if type(TDLDB) ~= "table" then TDLDB = {} end
    db = TDLDB
    db.recoveryReady = nil
    if type(db.tasks) ~= "table" then db.tasks = {} end
    UpdateMinimapPosition()
    self:UnregisterEvent("PLAYER_LOGIN")
end)

SLASH_TDL1 = "/tdl"
SLASH_TDL2 = "/todo"
SlashCmdList["TDL"] = TDL_Toggle
