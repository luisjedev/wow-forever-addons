local _, addon = ...
local L = addon.L
local guide = addon.guides.blacksmithing

local WIDTH, HEIGHT, CONTENT_W = 740, 580, 662
local GOLD = { 1, 0.82, 0 }
local cardBackdrop = { bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 }
local anchors = { TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true, CENTER = true, RIGHT = true,
    BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true }

local db, window, scroll, content, pager
local tabButtons, pageButtons, cards, pages = {}, {}, {}, {}
local state = { tab = "leveling", pages = {} }
local jumped
local Render

local function Button(parent, text, width)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 26)
    button:SetText(text)
    return button
end

local function Text(parent, font, height)
    local text = parent:CreateFontString(nil, "OVERLAY", font)
    if height then text:SetFontHeight(height) end
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    return text
end

local function Card(i)
    local card = CreateFrame("Frame", nil, content, "BackdropTemplate")
    card:SetBackdrop(cardBackdrop)
    card.badge = Text(card, "GameFontNormalLarge", 18)
    card.badge:SetJustifyH("CENTER")
    card.badge:SetWidth(70)
    card.status = Text(card, "GameFontNormalSmall")
    card.status:SetJustifyH("CENTER")
    card.status:SetWidth(70)
    card.title = Text(card, "GameFontHighlight", 15)
    card.body = Text(card, "GameFontHighlightSmall", 12)
    card.body:SetSpacing(3)
    card.line = card:CreateTexture(nil, "ARTWORK")
    card.line:SetColorTexture(0.45, 0.34, 0.16, 0.7)
    card.line:SetHeight(1)
    cards[i] = card
    return card
end

-- Lays one block out below `y` and returns the next free y.
local function Place(card, block, y, skill)
    card:ClearAllPoints()
    card:SetPoint("TOPLEFT", 0, -y)
    card:SetWidth(CONTENT_W)
    card:Show()
    for _, part in ipairs({ card.badge, card.status, card.title, card.body, card.line }) do part:Hide() end
    card.title:ClearAllPoints()
    card.body:ClearAllPoints()
    local kind = block.kind
    if kind == "heading" then
        card:SetBackdropColor(0, 0, 0, 0)
        card:SetBackdropBorderColor(0, 0, 0, 0)
        card.title:SetFontObject("GameFontNormalLarge")
        card.title:SetTextColor(unpack(GOLD))
        card.title:SetPoint("TOPLEFT", 4, -12)
        card.title:SetWidth(CONTENT_W - 8)
        card.title:SetText(block.title)
        card.title:Show()
        card.line:ClearAllPoints()
        card.line:SetPoint("TOPLEFT", 4, -34)
        card.line:SetPoint("TOPRIGHT", -4, -34)
        card.line:Show()
        card:SetHeight(42)
        return y + 42
    end
    if kind == "note" then
        card:SetBackdropColor(0, 0, 0, 0)
        card:SetBackdropBorderColor(0, 0, 0, 0)
        card.body:SetPoint("TOPLEFT", 8, -6)
        card.body:SetWidth(CONTENT_W - 16)
        card.body:SetTextColor(0.85, 0.8, 0.65)
        card.body:SetText(block.body)
        card.body:Show()
        local height = card.body:GetStringHeight() + 14
        card:SetHeight(height)
        return y + height
    end

    local progress = block.step and addon.StepState(block.step, skill) or "todo"
    local done, current = progress == "done", progress == "current"
    card:SetBackdropColor(current and 0.22 or 0.08, current and 0.16 or 0.075, current and 0.04 or 0.055, done and 0.45 or 0.88)
    if current then
        card:SetBackdropBorderColor(1, 0.82, 0, 1)
    else
        card:SetBackdropBorderColor(0.45, 0.34, 0.16, done and 0.3 or 0.6)
    end
    local left = 16
    if block.badge then
        left = 90
        card.badge:SetPoint("TOPLEFT", 10, -12)
        card.badge:SetText(block.badge)
        card.badge:SetFontObject(block.step and "GameFontNormalLarge" or "GameFontNormal")
        card.badge:SetAlpha(done and 0.5 or 1)
        card.badge:Show()
        if block.step and progress ~= "todo" then
            card.status:SetPoint("TOP", card.badge, "BOTTOM", 0, -4)
            card.status:SetText(done and L["Done"] or L["Now"])
            card.status:SetTextColor(done and 0.4 or 1, done and 0.8 or 0.82, done and 0.4 or 0)
            card.status:Show()
        end
    end
    local width = CONTENT_W - left - 14
    card.title:SetFontObject("GameFontHighlight")
    card.title:SetPoint("TOPLEFT", left, -11)
    card.title:SetWidth(width)
    card.title:SetTextColor(done and 0.6 or 1, done and 0.6 or 1, done and 0.6 or 1)
    card.title:SetText(block.title)
    card.title:Show()
    local height = 11 + card.title:GetStringHeight()
    if block.body then
        card.body:SetPoint("TOPLEFT", left, -(height + 5))
        card.body:SetWidth(width)
        card.body:SetTextColor(done and 0.55 or 0.82, done and 0.55 or 0.8, done and 0.5 or 0.72)
        card.body:SetText(block.body)
        card.body:Show()
        height = height + 5 + card.body:GetStringHeight()
    end
    height = math.max(height + 12, block.step and 68 or 36)
    card:SetHeight(height)
    return y + height + 6
end

local function SetPage(index)
    state.pages[state.tab] = math.max(1, math.min(index, #pages))
    Render()
end

local function SelectTab(key)
    state.tab = key
    if db then db.tab = key end
    pages = addon.BuildPages(guide, key)
    state.pages[key] = math.max(1, math.min(state.pages[key] or 1, #pages))
end

local function UpdateProgress(skill)
    local bar = window.progress
    local ratio = skill and math.min(skill / guide.max, 1) or 0
    bar.fill:SetWidth(math.max(1, (bar:GetWidth() - 2) * ratio))
    bar.fill:SetShown(skill ~= nil)
    bar.text:SetText(skill and (guide.name .. " " .. skill .. " / " .. guide.max) or (guide.name .. " - " .. L["Not learned"]))
end

Render = function()
    if not window then return end
    local skill = addon.ReadSkill(guide.skillLine)
    UpdateProgress(skill)
    for _, tab in ipairs(tabButtons) do
        local selected = tab.key == state.tab
        tab:SetBackdropColor(selected and 0.28 or 0.1, selected and 0.2 or 0.09, selected and 0.05 or 0.07, 0.95)
        tab:SetBackdropBorderColor(selected and 1 or 0.45, selected and 0.82 or 0.34, selected and 0 or 0.16, selected and 1 or 0.7)
        tab.label:SetTextColor(selected and 1 or 0.75, selected and 0.82 or 0.7, selected and 0 or 0.55)
    end
    local index = state.pages[state.tab]
    local page = pages[index]
    local y = 4
    for i, block in ipairs(page.blocks) do y = Place(cards[i] or Card(i), block, y, skill) end
    for i = #page.blocks + 1, #cards do cards[i]:Hide() end
    content:SetHeight(y + 8)
    scroll:SetVerticalScroll(0)
    pager.label:SetText(page.title .. "  -  " .. string.format(L["Page %d / %d"], index, #pages))
    pager.previous:SetEnabled(index > 1)
    pager.next:SetEnabled(index < #pages)
    local first = -(#pages * 32) / 2 + 16
    for i, button in ipairs(pageButtons) do
        button:SetShown(i <= #pages)
        button:SetEnabled(i ~= index)
        button:ClearAllPoints()
        button:SetPoint("CENTER", pager, "CENTER", first + (i - 1) * 32, 0)
    end
end

local function CreateWindow()
    window = CreateFrame("Frame", "ProfGuideFrame", UIParent, "BackdropTemplate")
    window:Hide()
    window:SetSize(WIDTH, HEIGHT)
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
        if anchors[point] and anchors[relativePoint] and type(x) == "number" and type(y) == "number" then
            window:ClearAllPoints()
            window:SetPoint(point, UIParent, relativePoint, x, y)
        end
    end
    table.insert(UISpecialFrames, "ProfGuideFrame")
    window:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 } })

    local header = window:CreateTexture(nil, "ARTWORK")
    header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    header:SetSize(300, 64)
    header:SetPoint("TOP", 0, 12)
    local title = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", header, "TOP", 0, -14)
    title:SetText("ProfGuide")
    local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -8, -8)
    close:SetScript("OnClick", function() window:Hide() end)

    local icon = window:CreateTexture(nil, "ARTWORK")
    icon:SetSize(44, 44)
    icon:SetPoint("TOPLEFT", 30, -38)
    icon:SetTexture(guide.icon)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    local name = window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    name:SetFontHeight(24)
    name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -1)
    name:SetText(guide.name)
    local subtitle = window:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    subtitle:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)
    subtitle:SetText(L["Based on wow-professions.com · Forever beta"])

    local bar = CreateFrame("Frame", nil, window, "BackdropTemplate")
    bar:SetSize(250, 20)
    bar:SetPoint("TOPRIGHT", -44, -50)
    bar:SetBackdrop(cardBackdrop)
    bar:SetBackdropColor(0.04, 0.04, 0.03, 0.9)
    bar:SetBackdropBorderColor(0.45, 0.34, 0.16, 1)
    bar.fill = bar:CreateTexture(nil, "ARTWORK")
    bar.fill:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar.fill:SetVertexColor(0.75, 0.5, 0.1)
    bar.fill:SetPoint("TOPLEFT", 1, -1)
    bar.fill:SetPoint("BOTTOMLEFT", 1, 1)
    bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.text:SetPoint("CENTER")
    window.progress = bar

    for i, tab in ipairs(addon.tabs) do
        local button = CreateFrame("Button", nil, window, "BackdropTemplate")
        button:SetSize(150, 28)
        button:SetPoint("TOPLEFT", 30 + (i - 1) * 154, -98)
        button:SetBackdrop(cardBackdrop)
        button.key = tab.key
        button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        button.label:SetPoint("CENTER")
        button.label:SetText(tab.label)
        button:SetScript("OnClick", function() SelectTab(tab.key); Render() end)
        tabButtons[i] = button
    end

    local panel = CreateFrame("Frame", nil, window, "BackdropTemplate")
    panel:SetPoint("TOPLEFT", 24, -128)
    panel:SetPoint("BOTTOMRIGHT", -24, 78)
    panel:SetBackdrop(cardBackdrop)
    panel:SetBackdropColor(0.03, 0.025, 0.02, 0.7)
    panel:SetBackdropBorderColor(0.45, 0.34, 0.16, 0.9)
    scroll = CreateFrame("ScrollFrame", "ProfGuideScrollFrame", window, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 28, -132)
    scroll:SetPoint("BOTTOMRIGHT", -50, 82)
    scroll.ScrollBar:ClearAllPoints()
    scroll.ScrollBar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 8, -16)
    scroll.ScrollBar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 8, 16)
    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(CONTENT_W, 1)
    scroll:SetScrollChild(content)

    pager = CreateFrame("Frame", nil, window)
    pager:SetPoint("BOTTOMLEFT", 28, 22)
    pager:SetPoint("BOTTOMRIGHT", -28, 22)
    pager:SetHeight(30)
    pager.previous = Button(pager, L["Previous"], 100)
    pager.previous:SetPoint("LEFT")
    pager.previous:SetScript("OnClick", function() SetPage(state.pages[state.tab] - 1) end)
    pager.next = Button(pager, L["Next"], 100)
    pager.next:SetPoint("RIGHT")
    pager.next:SetScript("OnClick", function() SetPage(state.pages[state.tab] + 1) end)
    pager.label = pager:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pager.label:SetPoint("BOTTOM", pager, "TOP", 0, 6)
    for i = 1, 6 do
        local button = Button(pager, tostring(i), 28)
        button:SetHeight(24)
        button:SetScript("OnClick", function() SetPage(i) end)
        pageButtons[i] = button
    end

    window:SetScript("OnShow", function()
        if not jumped then
            jumped = true
            local tier = addon.TierForSkill(guide, addon.ReadSkill(guide.skillLine))
            if tier then state.tab, state.pages.leveling = "leveling", tier end
        end
        SelectTab(state.tab)
        Render()
    end)
    window:SetScript("OnHide", function() GameTooltip:Hide() end)
end

function ProfGuide_Toggle()
    if not db then return end
    if not window then CreateWindow() end
    window:SetShown(not window:IsShown())
end

local minimapButton = CreateFrame("Button", "ProfGuideMinimapButton", Minimap)
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
minimapIcon:SetTexture(guide.icon)
minimapIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
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
    if self:GetScript("OnUpdate") then self:SetScript("OnUpdate", nil) end
    GameTooltip:Hide()
end

minimapButton:SetScript("OnDragStart", function(self)
    if not db then return end
    GameTooltip:Hide()
    self:SetScript("OnUpdate", DragMinimapButton)
end)
minimapButton:SetScript("OnDragStop", StopMinimapDrag)
minimapButton:SetScript("OnHide", StopMinimapDrag)
minimapButton:SetScript("OnClick", ProfGuide_Toggle)
minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("ProfGuide", 1, 0.82, 0)
    GameTooltip:AddLine(L["Left-click: Open / close"], 1, 1, 1)
    GameTooltip:AddLine(L["Drag: Move"], 1, 1, 1)
    GameTooltip:Show()
end)
minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("SKILL_LINES_CHANGED")
events:SetScript("OnEvent", function(self, event)
    if event == "SKILL_LINES_CHANGED" then
        if window and window:IsShown() then Render() end
        return
    end
    if type(ProfGuideDB) ~= "table" then ProfGuideDB = {} end
    db = ProfGuideDB
    -- Keep valid saved choices; anything unexpected falls back to the defaults.
    local valid = {}
    for _, tab in ipairs(addon.tabs) do valid[tab.key] = true end
    if valid[db.tab] then state.tab = db.tab end
    if type(db.pages) == "table" then
        for key, page in pairs(db.pages) do
            if valid[key] and type(page) == "number" and page >= 1 and page == math.floor(page) then
                state.pages[key] = page
            end
        end
    end
    db.pages = state.pages
    UpdateMinimapPosition()
    self:UnregisterEvent("PLAYER_LOGIN")
end)

SLASH_PROFGUIDE1 = "/profguide"
SLASH_PROFGUIDE2 = "/pg"
SlashCmdList["PROFGUIDE"] = ProfGuide_Toggle
