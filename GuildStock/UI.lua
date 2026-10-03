local _, addon = ...
local L = addon.L
local window, minimapButton, selected
local page, view, profession = "materials", "all", nil
local tabs, navigation, professionButtons = {}, {}, {}
local browser, inventory, settings, sidebar, materialList, details
local bagList, search, bagSearch, listTitle, listHint, detailName, detailProfessions, detailIcon, detailSlot, detailStar, emptyOwners
local inventoryNote, syncStatus, syncDescription, scaleLabel
local temporarySettings = {}
local gold, cream, muted = {0.68, 0.51, 0.24}, {0.94, 0.90, 0.76}, {0.61, 0.66, 0.67}
local backdrop = { bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 }
local viewLabels = { all = "All materials", favorites = "Favorites" }

local function Preferences()
    if addon.db.settings == nil then addon.db.settings = {} end
    addon.temporaryPreferences = type(addon.db.settings) ~= "table"
    return type(addon.db.settings) == "table" and addon.db.settings or temporarySettings
end

local function InitialView()
    local preferences = Preferences()
    if preferences.initialView == "mine" then preferences.initialView = "all" end
    local value = preferences.initialView
    return viewLabels[value] and value or "all"
end

local function Panel(parent, x, y, width, height, border)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetPoint("TOPLEFT", x, -y)
    frame:SetSize(width, height)
    frame:SetBackdrop(backdrop)
    frame:SetBackdropColor(0.18, 0.22, 0.24, 0.98)
    frame:SetBackdropBorderColor(unpack(border or {0.23, 0.28, 0.29}))
    return frame
end

local function Label(parent, value, x, y, width, size, color, heading)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont(heading and STANDARD_TEXT_FONT or (GetLocale():match("^en") or GetLocale():match("^es")) and "Fonts\\ARIALN.TTF" or STANDARD_TEXT_FONT, size or 15)
    label:SetPoint("TOPLEFT", x, -y)
    label:SetWidth(width)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    label:SetTextColor(unpack(color or cream))
    label:SetText(value)
    return label
end

local function Icon(parent, texture, x, y, size)
    local icon = parent:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", x, -y)
    icon:SetSize(size, size)
    icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    return icon
end

local function Tip(frame, value)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(value, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function Button(parent, text, x, y, width, height, callback, texture)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetPoint("TOPLEFT", x, -y)
    button:SetSize(width, height)
    button:SetBackdrop(backdrop)
    button:SetBackdropColor(0.12, 0.16, 0.18, 0.7)
    button:SetBackdropBorderColor(0.20, 0.25, 0.26)
    button:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
    button:GetHighlightTexture():SetVertexColor(1, 0.8, 0.4, 0.08)
    button.label = Label(button, text, texture and 47 or 10, (height - 18) / 2, width - (texture and 58 or 20), 16)
    button.label:SetWordWrap(false)
    if not texture then button.label:SetJustifyH("CENTER") end
    if texture then button.image = Icon(button, texture, 9, (height - 30) / 2, 30) end
    button:RegisterForClicks("LeftButtonUp")
    button:SetScript("OnClick", callback)
    return button
end

local function Highlight(button, active)
    button:SetBackdropColor(active and 0.40 or 0.13, active and 0.31 or 0.17, active and 0.12 or 0.19, 0.96)
    button:SetBackdropBorderColor(unpack(active and gold or {0.12, 0.17, 0.18}))
    button.label:SetTextColor(unpack(active and cream or {0.79, 0.82, 0.80}))
end

local function Search(parent, placeholder, x, y, width)
    local shell = Panel(parent, x, y, width, 35)
    local field = CreateFrame("EditBox", nil, shell)
    field:SetPoint("TOPLEFT", 12, -5)
    field:SetPoint("BOTTOMRIGHT", -34, 5)
    field:SetFontObject("GameFontHighlight")
    field:SetAutoFocus(false)
    field:SetMaxLetters(80)
    local hint = Label(shell, L[placeholder], 12, 9, width - 48, 14, muted)
    field:SetScript("OnTextChanged", function(self)
        hint:SetShown(self:GetText() == "")
        if materialList then materialList.scroll.ScrollBar:SetValue(0) end
        if bagList then bagList.scroll.ScrollBar:SetValue(0) end
        addon.Refresh()
    end)
    field:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    field:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    Button(shell, "×", width - 31, 3, 28, 28, function() field:SetText(""); field:ClearFocus() end)
    field:SetText("")
    return field
end

local function Scroll(parent, x, y, width, height)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", x, -y)
    scroll:SetSize(width - 24, height)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(width - 24, 1)
    scroll:SetScrollChild(content)
    return {scroll = scroll, content = content, rows = {}, width = width - 24}
end

local function Favorite(id)
    return type(addon.db.favorites) == "table" and addon.db.favorites[id] == true
end

local function Star(button, id)
    local favorite = Favorite(id)
    button.icon:SetTexCoord(0, 0.5, favorite and 0 or 0.5, favorite and 0.5 or 1)
    button.icon:SetDesaturated(true)
    button.icon:SetVertexColor(1, 0.85, 0.52)
    button.icon:SetAlpha(favorite and 1 or 0.85)
    Tip(button, L[Favorite(id) and "Remove from favorites" or "Add to favorites"])
end

local function StarButton(parent, x, y, callback)
    local button = CreateFrame("Button", nil, parent)
    button:SetPoint("TOPLEFT", x, -y)
    button:SetSize(32, 32)
    button.icon = Icon(button, "Interface\\COMMON\\ReputationStar", 4, 4, 24)
    button:RegisterForClicks("LeftButtonUp")
    button:SetScript("OnClick", callback)
    return button
end

local function RenderList(list, entries, own)
    -- ponytail: one reused row per discovered material; virtualize if large catalogs make refresh slow.
    for i, entry in ipairs(entries) do
        local row = list.rows[i]
        if not row then
            row = Button(list.content, "", 0, (i - 1) * 55, list.width, 55, function(self)
                if not own then selected = self.itemID; addon.Refresh() end
            end)
            local slot = Panel(row, 7, 6, 43, 43, gold)
            row.icon = Icon(slot, nil, 2, 2, 39)
            row.label:ClearAllPoints()
            row.label:SetPoint("LEFT", 59, 0)
            row.label:SetWidth(own and list.width * 0.65 - 65 or list.width - 96)
            row.label:SetJustifyH("LEFT")
            if own then
                row.count = Label(row, "", list.width * 0.72, 18, 100, 16)
                row.count:SetJustifyH("CENTER")
            else
                row.star = StarButton(row, list.width - 36, 11, function() addon.ToggleFavorite(row.itemID); addon.Refresh() end)
            end
            list.rows[i] = row
        end
        row.itemID = entry.id
        row.label:SetText(entry.name)
        row.icon:SetTexture(entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        Highlight(row, not own and entry.id == selected)
        if own then
            row.count:SetText(entry.count)
            local snapshot = addon.snapshot
            Tip(row, entry.name .. "\n" .. L["Bound"] .. ": " .. snapshot.items[entry.id].bound .. "\n"
                .. string.format(L["Observed: %s"], date("%Y-%m-%d %H:%M:%S", snapshot.observedAt)))
        else
            Star(row.star, entry.id)
        end
        row:Show()
    end
    for i = #entries + 1, #list.rows do list.rows[i]:Hide() end
    list.content:SetHeight(math.max(1, #entries * 55))
    list.scroll:UpdateScrollChildRect()
    list.scroll.ScrollBar:SetValue(math.min(list.scroll.ScrollBar:GetValue(), list.scroll:GetVerticalScrollRange()))
end

local function ApplyScale()
    if not window then return end
    local scale = Preferences().scale
    if type(scale) ~= "number" or scale ~= scale or scale < 0.8 or scale > 1.2 then scale = 1 end
    local width, height = UIParent:GetWidth(), UIParent:GetHeight()
    if addon.Accessible(width) and addon.Accessible(height) and width > 0 and height > 0 then
        scale = math.min(scale, (width - 24) / 1180, (height - 24) / 650)
    end
    window:SetScale(scale)
end

function addon.Refresh()
    if not window or not window:IsShown() then return end
    local preferences = Preferences()
    for key, button in pairs(tabs) do Highlight(button, key == page) end
    browser:SetShown(page == "materials")
    inventory:SetShown(page == "inventory")
    settings:SetShown(page == "settings")
    if page == "materials" then
        for key, button in pairs(navigation) do Highlight(button, key == view) end
        for key, button in pairs(professionButtons) do Highlight(button, key == (profession or "all")) end
        local entries = addon.Materials(view, profession, search:GetText())
        local found = false
        for _, entry in ipairs(entries) do if entry.id == selected then found = true end end
        if not found then selected = entries[1] and entries[1].id end
        listTitle:SetText(L[viewLabels[view]])
        listHint:SetText(L["Partial catalog · discovered materials"])
        materialList.empty:SetShown(#entries == 0)
        materialList.empty:SetText(L["No matching materials."] .. "\n\n" .. L[view == "favorites"
            and "Mark materials with a star to add them to favorites."
            or "Open your profession windows to discover recipe materials."])
        RenderList(materialList, entries)
        detailSlot:SetShown(selected ~= nil)
        detailStar:SetShown(selected ~= nil)
        if selected then
            local data, names = addon.ItemData(selected), {}
            detailName:SetText(data.name)
            detailIcon:SetTexture(data.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            local professions = addon.Catalog()[selected]
            for _, entry in ipairs(addon.professions) do
                if professions[entry[1]] == true then names[#names + 1] = L[entry[1]] end
            end
            detailProfessions:SetText(#names > 0 and table.concat(names, " · ") or L["Profession not yet identified"])
            Star(detailStar, selected)
        else
            detailName:SetText(L["Select a material"])
            detailProfessions:SetText("")
        end
        local restricted = addon.Read(C_ChatInfo and C_ChatInfo.AreOutgoingAddonChatMessagesRestricted)
        emptyOwners:SetText(L[restricted == true and "Guild data is unavailable while addon messages are restricted." or "Waiting for guild data"])
    elseif page == "inventory" then
        local entries = addon.Materials("all", nil, bagSearch:GetText(), true)
        RenderList(bagList, entries, true)
        bagList.empty:SetShown(#entries == 0)
        bagList.empty:SetText(L[addon.snapshot and "No matching materials." or "No complete bag observation yet."])
        inventoryNote:SetText(addon.incomplete and L["Incomplete bag read; retaining the previous observation."] or L["Quantities for your current character."])
    else
        local restricted = addon.Read(C_ChatInfo and C_ChatInfo.AreOutgoingAddonChatMessagesRestricted)
        syncStatus:SetText(L[restricted == true and "Addon messages restricted" or "Awaiting communication validation"])
        syncDescription:SetText(L[restricted == true and "Outgoing addon messages are restricted. Your bag inventory remains available." or "Guild inventory sharing is not active yet. Your bag inventory remains available."])
        settings.offline:SetChecked(preferences.showOffline ~= false)
        settings.minimap:SetChecked(preferences.showMinimap ~= false)
        settings.initial.label:SetText(L[viewLabels[InitialView()]])
        scaleLabel:SetText(string.format("%d %%", math.floor((window:GetScale() or 1) * 100 + 0.5)))
        settings.saveNotice:SetText(L[(addon.temporary or addon.temporaryPreferences)
            and "Saved data is unsupported; using temporary data without replacing it." or "Changes are saved automatically."])
    end
end

local function SelectPage(value)
    page = value
    if search then search:ClearFocus(); bagSearch:ClearFocus() end
    addon.Refresh()
end

local function CreateWindow()
    window = CreateFrame("Frame", "GuildStockFrame", UIParent, "BackdropTemplate")
    window:Hide()
    window:SetSize(1180, 650)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4} })
    window:SetBackdropColor(0.15, 0.19, 0.21, 0.99)
    window:SetBackdropBorderColor(unpack(gold))
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    UISpecialFrames[#UISpecialFrames + 1] = "GuildStockFrame"
    Icon(window, "Interface\\Icons\\INV_Crate_01", 19, 15, 49)
    Label(window, "GuildStock", 82, 13, 260, 28, cream, true)
    Label(window, L["Guild materials"], 83, 45, 260, 15, muted)
    for i, tab in ipairs({{"Materials", "materials"}, {"My inventory", "inventory"}, {"Settings", "settings"}}) do
        tabs[tab[2]] = Button(window, L[tab[1]], 348 + (i - 1) * 166, 16, 166, 45, function() SelectPage(tab[2]) end)
    end
    Button(window, "×", 1138, 14, 30, 30, function() window:Hide() end)
    Panel(window, 7, 73, 1166, 1, gold)
    browser = CreateFrame("Frame", nil, window)
    browser:SetAllPoints()
    sidebar = Panel(browser, 7, 77, 247, 566)
    for i, entry in ipairs({{"all", "INV_Crate_01"}, {"favorites", "INV_Misc_Note_01"}}) do
        navigation[entry[1]] = Button(sidebar, L[viewLabels[entry[1]]], 7, 13 + (i - 1) * 47, 233, 44, function()
            view = entry[1]
            if view == "all" then profession = nil end
            materialList.scroll.ScrollBar:SetValue(0)
            addon.Refresh()
        end, entry[1] == "favorites" and "Interface\\COMMON\\ReputationStar" or "Interface\\Icons\\" .. entry[2])
    end
    navigation.favorites.image:SetTexCoord(0, 0.5, 0, 0.5)
    navigation.favorites.image:SetVertexColor(1, 0.78, 0.38)
    Label(sidebar, L["Professions"], 15, 118, 218, 13, muted)
    local professionList = Scroll(sidebar, 7, 145, 234, 404)
    professionButtons.all = Button(professionList.content, L["All professions"], 0, 0, 210, 40, function()
        profession = nil; materialList.scroll.ScrollBar:SetValue(0); addon.Refresh()
    end, "Interface\\Icons\\Trade_Mining")
    for i, entry in ipairs(addon.professions) do
        professionButtons[entry[1]] = Button(professionList.content, L[entry[1]], 0, i * 40, 210, 40, function()
            profession = entry[1]; materialList.scroll.ScrollBar:SetValue(0); addon.Refresh()
        end, "Interface\\Icons\\" .. entry[2])
    end
    professionList.content:SetHeight((#addon.professions + 1) * 40)
    local middle = Panel(browser, 258, 77, 324, 566)
    search = Search(middle, "Search materials...", 11, 13, 301)
    listTitle = Label(middle, "", 14, 64, 295, 19)
    listHint = Label(middle, "", 14, 90, 295, 12, muted)
    materialList = Scroll(middle, 8, 119, 307, 434)
    materialList.empty = Label(middle, "", 22, 184, 278, 15, muted)
    materialList.empty:SetJustifyH("CENTER")
    details = Panel(browser, 586, 77, 587, 566)
    detailSlot = Panel(details, 20, 20, 89, 89, gold)
    detailIcon = Icon(detailSlot, nil, 2, 2, 85)
    detailName = Label(details, "", 127, 27, 389, 25, cream, true)
    detailProfessions = Label(details, "", 128, 77, 390, 14, muted)
    detailStar = StarButton(details, 539, 23, function() if selected then addon.ToggleFavorite(selected); addon.Refresh() end end)
    local tablePanel = Panel(details, 17, 133, 554, 284)
    local columns = {{"Player", 15, 174}, {"Bags", 199, 60}, {"Last online", 287, 131}, {"Whisper", 442, 96}}
    local tableHeader = Panel(tablePanel, 0, 0, 554, 41)
    tableHeader:SetBackdropColor(0.25, 0.29, 0.31, 1)
    for _, column in ipairs(columns) do Label(tableHeader, L[column[1]], column[2], 13, column[3], 14) end
    Icon(tablePanel, "Interface\\Icons\\INV_Crate_01", 249, 96, 48):SetAlpha(0.45)
    emptyOwners = Label(tablePanel, "", 35, 166, 484, 18, muted)
    emptyOwners:SetJustifyH("CENTER")
    Label(details, L["Quantities reflect the last synchronization."], 21, 436, 537, 13, muted)
    Label(details, L["Offline members: last known counts."], 21, 458, 537, 13, muted)

    inventory = Panel(window, 7, 77, 1166, 566)
    Label(inventory, L["My inventory"], 25, 20, 1050, 29, cream, true)
    Label(inventory, L["Profession materials in your bags"], 26, 63, 1050, 17, muted)
    bagSearch = Search(inventory, "Search my bags...", 23, 98, 1118)
    local inventoryHeader = Panel(inventory, 23, 148, 1118, 39)
    inventoryHeader:SetBackdropColor(0.25, 0.29, 0.31, 1)
    Label(inventoryHeader, L["Material"], 19, 11, 700, 15)
    Label(inventoryHeader, L["Bags"], 789, 11, 100, 15):SetJustifyH("CENTER")
    bagList = Scroll(inventory, 23, 187, 1118, 325)
    bagList.empty = Label(inventory, "", 160, 283, 840, 17, muted)
    bagList.empty:SetJustifyH("CENTER")
    inventoryNote = Label(inventory, "", 26, 534, 1090, 13, muted)

    settings = Panel(window, 7, 77, 1166, 566)
    Label(settings, L["Settings"], 27, 20, 1000, 28, cream, true)
    local display = Panel(settings, 26, 76, 1114, 192)
    Label(display, L["Material view"], 16, 14, 1040, 20, cream, true)
    local function Check(parent, key, title, y, callback)
        local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        check:SetPoint("TOPLEFT", 14, -y)
        check:SetSize(28, 28)
        Label(parent, L[title], 51, y + 5, 1000, 16)
        check:SetScript("OnClick", function(self)
            Preferences()[key] = self:GetChecked() == true
            if callback then callback() end
        end)
        return check
    end
    settings.offline = Check(display, "showOffline", "Show offline members", 49)
    Label(display, L["Their quantities are the last known counts."], 51, 81, 1000, 13, muted)
    settings.minimap = Check(display, "showMinimap", "Show minimap button", 102, function()
        if minimapButton then minimapButton:SetShown(Preferences().showMinimap ~= false) end
    end)
    Label(display, L["Opening view"], 19, 154, 160, 16)
    settings.initial = Button(display, "", 181, 143, 271, 34, function()
        settings.choices:SetShown(not settings.choices:IsShown())
    end)
    Icon(settings.initial, "Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up", 241, 5, 24)
    settings.choices = Panel(settings, 207, 253, 271, 73, gold)
    settings.choices:SetFrameLevel(settings.initial:GetFrameLevel() + 10)
    settings.choices:Hide()
    for i, key in ipairs({"all", "favorites"}) do
        Button(settings.choices, L[viewLabels[key]], 2, 2 + (i - 1) * 35, 267, 34, function()
            Preferences().initialView = key; settings.choices:Hide(); addon.Refresh()
        end)
    end
    local interface = Panel(settings, 26, 280, 1114, 96)
    Label(interface, L["Interface"], 16, 14, 1040, 20, cream, true)
    Label(interface, L["Window scale"], 19, 60, 175, 16)
    local slider = CreateFrame("Slider", nil, interface, "BackdropTemplate")
    slider:SetPoint("TOPLEFT", 219, -57)
    slider:SetSize(296, 19)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(0.8, 1.2)
    slider:SetValueStep(0.05)
    slider:SetObeyStepOnDrag(true)
    slider:SetBackdrop(backdrop)
    slider:SetBackdropColor(0.12, 0.14, 0.14, 1)
    slider:SetBackdropBorderColor(unpack(gold))
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    slider:GetThumbTexture():SetSize(28, 28)
    local scale = Preferences().scale
    slider:SetValue(type(scale) == "number" and scale == scale and scale >= 0.8 and scale <= 1.2 and scale or 1)
    scaleLabel = Label(interface, "100 %", 543, 60, 90, 16)
    slider:SetScript("OnValueChanged", function(_, value)
        Preferences().scale = math.floor(value * 20 + 0.5) / 20
        ApplyScale(); addon.Refresh()
    end)
    local sync = Panel(settings, 26, 388, 1114, 131)
    Label(sync, L["Synchronization"], 16, 14, 1040, 20, cream, true)
    syncStatus = Label(sync, "", 21, 52, 1050, 16, gold)
    syncDescription = Label(sync, "", 21, 83, 1050, 15, muted)
    settings.saveNotice = Label(settings, "", 26, 536, 1114, 13, muted)
    settings.saveNotice:SetJustifyH("RIGHT")
    window:SetScript("OnShow", addon.Refresh)
    window:SetScript("OnHide", function() search:ClearFocus(); bagSearch:ClearFocus(); settings.choices:Hide() end)
    ApplyScale()
end

local function Toggle()
    if not addon.db then return end
    if not window then CreateWindow() end
    if not window:IsShown() then view = InitialView(); page = "materials"; profession = nil end
    window:SetShown(not window:IsShown())
end

function addon.CreateMinimapButton()
    local button = CreateFrame("Button", "GuildStockMinimapButton", Minimap)
    minimapButton = button
    button:SetSize(32, 32)
    button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    button:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
    button:RegisterForClicks("LeftButtonUp")
    button:SetMovable(true)
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 1)
    icon:SetTexture("Interface\\Icons\\INV_Crate_01")
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    local function Position()
        local angle = addon.db.minimapAngle
        if not addon.Accessible(angle) or type(angle) ~= "number" or angle ~= angle or math.abs(angle) == math.huge then return end
        local width, height = Minimap:GetWidth(), Minimap:GetHeight()
        if not addon.Accessible(width) or not addon.Accessible(height) then return end
        button:ClearAllPoints()
        button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * (width / 2 + 8), math.sin(angle) * (height / 2 + 8))
    end
    button:SetScript("OnDragStart", function(self)
        GameTooltip:Hide()
        self:SetScript("OnUpdate", function()
            local x, y = GetCursorPosition()
            local cx, cy = Minimap:GetCenter()
            local scale = Minimap:GetEffectiveScale()
            if not addon.Accessible(x) or not addon.Accessible(y) or not addon.Accessible(cx)
                or not addon.Accessible(cy) or not addon.Accessible(scale) then return end
            if not cx or not cy then return end
            x, y = x / scale - cx, y / scale - cy
            if x == 0 and y == 0 then return end
            addon.db.minimapAngle = math.atan2(y, x)
            Position()
        end)
    end)
    local function Stop(self) self:SetScript("OnUpdate", nil); GameTooltip:Hide() end
    button:SetScript("OnDragStop", Stop)
    button:SetScript("OnHide", Stop)
    button:SetScript("OnClick", Toggle)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("GuildStock", 1, 0.82, 0)
        GameTooltip:AddLine(L["Left-click: Open / close"], 1, 1, 1)
        GameTooltip:AddLine(L["Drag: Move"], 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    Position()
    button:SetShown(Preferences().showMinimap ~= false)
end


SLASH_GUILDSTOCK1 = "/guildstock"
SlashCmdList.GUILDSTOCK = function(command)
    command = command:lower():match("^%s*(.-)%s*$")
    if command == "probe" then
        print("GuildStock: " .. addon.StartProbe())
    elseif command == "diagnostics" then
        local version, build, _, interface = GetBuildInfo()
        print("GuildStock: " .. version .. "." .. build .. " / " .. interface)
        print(L["Prefix registration"] .. ": " .. (addon.probe.registration or L["Unavailable"]))
        for _, key in ipairs({"GUILD", "received", "confirmed", "unmatched"}) do
            print(key .. ": " .. tostring(addon.probe[key] or L["Not tested"]))
        end
        print(L["Professions"] .. ": " .. addon.ProfessionNames())
    else
        Toggle()
    end
end
