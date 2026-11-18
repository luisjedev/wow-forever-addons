local _, addon = ...
local L = addon.L
local BOOK_ICON = "Interface\\Icons\\INV_Misc_Book_09"
local guide -- nil while the overview is shown

local WIDTH, HEIGHT, CONTENT_W = 740, 580, 662
local GOLD = { 1, 0.82, 0 }
local cardBackdrop = { bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 }
local anchors = { TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true, CENTER = true, RIGHT = true,
    BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true }

local db, window, scroll, content, pager
local tabButtons, pageButtons, cards, pages, tiles, guideParts = {}, {}, {}, {}, {}, {}
-- pages[guideKey][tabKey] = page number; saved as db.pages.
local state = { key = nil, tab = "leveling", pages = {} }
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
    card.map = CreateFrame("Button", nil, card)
    card.map:SetSize(22, 22)
    card.map:SetPoint("TOPRIGHT", -8, -8)
    card.map:SetNormalTexture("Interface\\Icons\\INV_Misc_Map_01")
    card.map:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    card.map:SetScript("OnClick", function(self) addon.ShowOnMap(self.pin) end)
    card.map:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(L["Show on map"])
    end)
    card.map:SetScript("OnLeave", GameTooltip_Hide)
    -- Hovering a step with a recipe source shows where to get it.
    card:SetScript("OnEnter", function(self)
        if not self.source then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.source[1], 0.4, 0.8, 1)
        for i = 2, #self.source do GameTooltip:AddLine(self.source[i], 1, 1, 1, true) end
        GameTooltip:Show()
    end)
    card:SetScript("OnLeave", GameTooltip_Hide)
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
    local pin = block.pin or addon.SourcePin(block.source)
    card.source = block.source
    card:EnableMouse(block.source ~= nil)
    card.map.pin = pin
    card.map:SetShown(pin ~= nil)
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
    local width = CONTENT_W - left - (pin and 40 or 14)
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
    if block.badge then height = math.max(height, 12 + card.badge:GetStringHeight()) end
    height = math.max(height + 12, block.step and 68 or 36)
    card:SetHeight(height)
    return y + height + 6
end

local function GuidePages()
    state.pages[state.key] = state.pages[state.key] or {}
    return state.pages[state.key]
end

local function SetPage(index)
    GuidePages()[state.tab] = math.max(1, math.min(index, #pages))
    Render()
end

local function SelectTab(key)
    local valid
    for _, tab in ipairs(addon.TabsFor(guide)) do valid = valid or tab.key == key end
    state.tab = valid and key or "leveling"
    if db then db.tab = state.tab end
    pages = addon.BuildPages(guide, state.tab)
    local saved = GuidePages()
    saved[state.tab] = math.max(1, math.min(saved[state.tab] or 1, #pages))
end

-- nil shows the overview. Opening a guide jumps to the tier of your current skill when it is known.
local function SelectGuide(key)
    state.key, guide = key, key and addon.guides[key]
    if not guide then return end
    local tier = addon.TierForSkill(guide, addon.ReadSkill(guide.skillLine))
    if tier then state.tab, GuidePages().leveling = "leveling", tier end
    SelectTab(state.tab)
end

local function UpdateProgress(skill)
    local bar = window.progress
    local ratio = skill and math.min(skill / guide.max, 1) or 0
    bar.fill:SetWidth(math.max(1, (bar:GetWidth() - 2) * ratio))
    bar.fill:SetShown(skill ~= nil)
    bar.text:SetText(skill and (guide.name .. " " .. skill .. " / " .. guide.max) or (guide.name .. " - " .. L["Not learned"]))
end

local function RenderOverview()
    window.icon:SetTexture(BOOK_ICON)
    window.name:SetText(L["Professions"])
    for _, tile in ipairs(tiles) do
        local tileGuide = addon.guides[tile.key]
        local skill = addon.ReadSkill(tileGuide.skillLine)
        tile.skill:SetText(skill and (skill .. " / " .. tileGuide.max) or L["Not learned"])
        tile.skill:SetTextColor(skill and 1 or 0.55, skill and 0.82 or 0.5, skill and 0 or 0.45)
        tile:SetBackdropBorderColor(skill and 1 or 0.45, skill and 0.82 or 0.34, skill and 0 or 0.16, skill and 0.9 or 0.7)
    end
end

Render = function()
    if not window then return end
    for _, tile in ipairs(tiles) do tile:SetShown(guide == nil) end
    for _, part in ipairs(guideParts) do part:SetShown(guide ~= nil) end
    if not guide then return RenderOverview() end
    window.icon:SetTexture(guide.icon)
    window.name:SetText(guide.name)
    local skill = addon.ReadSkill(guide.skillLine)
    UpdateProgress(skill)
    local x = 30
    for _, tab in ipairs(tabButtons) do
        tab:SetShown(guide[tab.key] ~= nil or tab.key == "leveling")
        if tab:IsShown() then tab:SetPoint("TOPLEFT", x, -98); x = x + 154 end
        local selected = tab.key == state.tab
        tab:SetBackdropColor(selected and 0.28 or 0.1, selected and 0.2 or 0.09, selected and 0.05 or 0.07, 0.95)
        tab:SetBackdropBorderColor(selected and 1 or 0.45, selected and 0.82 or 0.34, selected and 0 or 0.16, selected and 1 or 0.7)
        tab.label:SetTextColor(selected and 1 or 0.75, selected and 0.82 or 0.7, selected and 0 or 0.55)
    end
    local index = GuidePages()[state.tab]
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
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    window.icon = icon
    local name = window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    name:SetFontHeight(24)
    name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -1)
    window.name = name
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
    guideParts[#guideParts + 1] = bar

    -- Overview: one tile per profession, 4 per row.
    for i, key in ipairs(addon.guideOrder) do
        local tileGuide = addon.guides[key]
        local tile = CreateFrame("Button", nil, window, "BackdropTemplate")
        tile:SetSize(162, 92)
        tile:SetPoint("TOPLEFT", 31 + ((i - 1) % 4) * 172, -104 - math.floor((i - 1) / 4) * 102)
        tile:SetBackdrop(cardBackdrop)
        tile:SetBackdropColor(0.08, 0.075, 0.055, 0.9)
        tile:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
        tile.key = key
        local tileIcon = tile:CreateTexture(nil, "ARTWORK")
        tileIcon:SetSize(40, 40)
        tileIcon:SetPoint("TOP", 0, -10)
        tileIcon:SetTexture(tileGuide.icon)
        tileIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        local label = tile:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOP", tileIcon, "BOTTOM", 0, -5)
        label:SetText(tileGuide.name)
        tile.skill = tile:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        tile.skill:SetPoint("TOP", label, "BOTTOM", 0, -3)
        tile:SetScript("OnClick", function() SelectGuide(key); Render() end)
        tiles[i] = tile
    end

    local back = Button(window, L["Back"], 70)
    back:SetPoint("RIGHT", bar, "LEFT", -10, 0)
    back:SetHeight(22)
    back:SetScript("OnClick", function() SelectGuide(nil); Render() end)
    guideParts[#guideParts + 1] = back

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
        guideParts[#guideParts + 1] = button
    end

    local panel = CreateFrame("Frame", nil, window, "BackdropTemplate")
    panel:SetPoint("TOPLEFT", 24, -128)
    panel:SetPoint("BOTTOMRIGHT", -24, 78)
    panel:SetBackdrop(cardBackdrop)
    panel:SetBackdropColor(0.03, 0.025, 0.02, 0.7)
    panel:SetBackdropBorderColor(0.45, 0.34, 0.16, 0.9)
    guideParts[#guideParts + 1] = panel
    scroll = CreateFrame("ScrollFrame", "ProfGuideScrollFrame", window, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 28, -132)
    scroll:SetPoint("BOTTOMRIGHT", -50, 82)
    scroll.ScrollBar:ClearAllPoints()
    scroll.ScrollBar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 8, -16)
    scroll.ScrollBar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 8, 16)
    guideParts[#guideParts + 1] = scroll
    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(CONTENT_W, 1)
    scroll:SetScrollChild(content)

    pager = CreateFrame("Frame", nil, window)
    pager:SetPoint("BOTTOMLEFT", 28, 22)
    pager:SetPoint("BOTTOMRIGHT", -28, 22)
    pager:SetHeight(30)
    guideParts[#guideParts + 1] = pager
    pager.previous = Button(pager, L["Previous"], 100)
    pager.previous:SetPoint("LEFT")
    pager.previous:SetScript("OnClick", function() SetPage(GuidePages()[state.tab] - 1) end)
    pager.next = Button(pager, L["Next"], 100)
    pager.next:SetPoint("RIGHT")
    pager.next:SetScript("OnClick", function() SetPage(GuidePages()[state.tab] + 1) end)
    pager.label = pager:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pager.label:SetPoint("BOTTOM", pager, "TOP", 0, 6)
    for i = 1, 6 do
        local button = Button(pager, tostring(i), 28)
        button:SetHeight(24)
        button:SetScript("OnClick", function() SetPage(i) end)
        pageButtons[i] = button
    end

    window:SetScript("OnShow", function()
        if guide then SelectTab(state.tab) end
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
minimapIcon:SetTexture(BOOK_ICON)
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
    local function ValidPage(page) return type(page) == "number" and page >= 1 and page == math.floor(page) end
    if type(db.pages) == "table" then
        for key, value in pairs(db.pages) do
            if addon.guides[key] and type(value) == "table" then
                for tab, page in pairs(value) do
                    if valid[tab] and ValidPage(page) then
                        state.pages[key] = state.pages[key] or {}
                        state.pages[key][tab] = page
                    end
                end
            elseif valid[key] and ValidPage(value) then
                -- 0.1.0-snapshot-1 saved one flat table for Blacksmithing.
                state.pages.blacksmithing = state.pages.blacksmithing or {}
                state.pages.blacksmithing[key] = state.pages.blacksmithing[key] or value
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
