local _, beta = ...
local L = beta.L
local betaDB = TDLDB
if beta.character then TDLDB = beta.native end

local db, window, input, saveButton, cancelButton, editorLabel, pager
local previousButton, nextButton
local rows, page, editing = {}, 1, nil
local PAGE_SIZE = 8

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
end

local function Refresh()
    local total = #db.tasks
    local pages = math.max(1, math.ceil(total / PAGE_SIZE))
    page = math.max(1, math.min(page, pages))
    pager:SetText(string.format("%d / %d", page, pages))
    previousButton:SetEnabled(page > 1)
    nextButton:SetEnabled(page < pages)

    for i, row in ipairs(rows) do
        local task = db.tasks[(page - 1) * PAGE_SIZE + i]
        row.task = task
        row:SetShown(task ~= nil)
        if task then
            row.check:SetChecked(task.done)
            row.text:SetText(PlainText(task.text))
            if task.done then
                row.text:SetTextColor(0.5, 0.8, 0.5)
            else
                row.text:SetTextColor(1, 0.95, 0.82)
            end
        end
    end
end

local function SaveTask()
    local text = input:GetText():gsub("%c", " "):match("^%s*(.-)%s*$")
    if text == "" or #text > 240 then
        editorLabel:SetText(text == "" and L["Enter a task before saving."] or L["Shorten the task text."])
        input:SetFocus()
        return
    end
    if editing then
        editing.text = text
    else
        table.insert(db.tasks, { text = text, done = false })
        page = math.ceil(#db.tasks / PAGE_SIZE)
    end
    ResetEditor()
    Refresh()
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

    for i = 1, PAGE_SIZE do
        local row = CreateFrame("Frame", nil, window)
        row:SetSize(560, 38)
        row:SetPoint("TOPLEFT", 20, -40 - (i - 1) * 40)
        local background = row:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints()
        background:SetColorTexture(1, 0.82, 0.4, i % 2 == 1 and 0.06 or 0.02)
        row.check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        row.check:SetPoint("LEFT", 0, 0)
        row.check:SetScript("OnClick", function(self)
            row.task.done = self:GetChecked() and true or false
            Refresh()
        end)
        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.text:SetPoint("LEFT", 38, 0)
        row.text:SetSize(348, 34)
        row.text:SetJustifyH("LEFT")
        row.text:SetWordWrap(true)
        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(PlainText(self.task.text), 1, 0.95, 0.82, 1, true)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)

        local edit = Button(row, L["Edit"], 72)
        edit:SetPoint("RIGHT", -84, 0)
        edit:SetScript("OnClick", function()
            editing = row.task
            editorLabel:SetText(L["Edit task"])
            input:SetText(editing.text)
            saveButton:SetText(L["Save"])
            cancelButton:Show()
            input:SetFocus()
            input:HighlightText()
        end)
        local delete = Button(row, L["Delete"], 78)
        delete:SetPoint("RIGHT", -2, 0)
        delete:SetScript("OnClick", function()
            StaticPopup_Show("TDL_DELETE", PlainText(row.task.text), nil, row.task)
        end)
        rows[i] = row
    end

    previousButton = Button(window, L["Previous"], 90)
    previousButton:SetPoint("TOPLEFT", 20, -374)
    previousButton:SetScript("OnClick", function() page = page - 1; Refresh() end)
    nextButton = Button(window, L["Next"], 90)
    nextButton:SetPoint("TOPRIGHT", -20, -374)
    nextButton:SetScript("OnClick", function() page = page + 1; Refresh() end)
    pager = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pager:SetPoint("TOP", 0, -380)
    window:EnableMouseWheel(true)
    window:SetScript("OnMouseWheel", function(_, delta)
        page = page + (delta > 0 and -1 or 1)
        Refresh()
    end)

    editorLabel = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    editorLabel:SetPoint("TOPLEFT", 20, -414)
    input = CreateFrame("EditBox", "TDLInput", window, "InputBoxTemplate")
    input:SetSize(348, 26)
    input:SetPoint("TOPLEFT", 26, -439)
    input:SetAutoFocus(false)
    input:SetMaxBytes(240)
    input:SetScript("OnEnterPressed", SaveTask)
    input:SetScript("OnEscapePressed", function(self)
        if editing then ResetEditor() else self:ClearFocus(); window:Hide() end
    end)
    saveButton = Button(window, L["Add"], 94)
    saveButton:SetPoint("TOPLEFT", 382, -440)
    saveButton:SetScript("OnClick", SaveTask)
    cancelButton = Button(window, L["Cancel"], 94)
    cancelButton:SetPoint("TOPLEFT", 484, -440)
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
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
local icon = minimapButton:CreateTexture(nil, "BACKGROUND")
icon:SetSize(20, 20)
icon:SetPoint("CENTER", 0, 1)
icon:SetTexture("Interface\\AddOns\\TDL\\Assets\\Icon")
local border = minimapButton:CreateTexture(nil, "OVERLAY")
border:SetSize(54, 54)
border:SetPoint("TOPLEFT")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
minimapButton:SetScript("OnClick", TDL_Toggle)
minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("TDL", 1, 0.82, 0)
    GameTooltip:AddLine(L["Click to show or hide your tasks."], 1, 1, 1)
    GameTooltip:Show()
end)
minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self)
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
    self:UnregisterEvent("PLAYER_LOGIN")
end)

SLASH_TDL1 = "/tdl"
SLASH_TDL2 = "/todo"
SlashCmdList["TDL"] = TDL_Toggle
