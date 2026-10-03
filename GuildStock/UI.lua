local _, addon = ...
local L = addon.L
local window, minimapButton, selected
local page, view, profession = "materials", "all", nil
local tabs, navigation, professionButtons = {}, {}, {}
local professionList
local browser, inventory, settings, sidebar, materialList, details
local bagList, search, bagSearch, listTitle, listHint, detailName, detailProfessions, detailIcon, detailSlot, detailStar, emptyOwners
local inventoryNote, hiddenList, syncStatus, syncDescription, scaleLabel
local characters, characterList, characterItems, characterSearch, characterItemSearch
local selectedCharacter, characterName, characterNote
local temporarySettings = {}
local gold, cream, muted = {0.64, 0.46, 0.23}, {0.94, 0.88, 0.73}, {0.70, 0.64, 0.54}
local colors = {
    window = {0.095, 0.075, 0.045, 1}, panel = {0.125, 0.10, 0.06, 1},
    border = {0.35, 0.27, 0.17}, button = {0.105, 0.08, 0.045, 1},
    selected = {0.18, 0.14, 0.06, 1}, accent = {1, 0.82, 0},
    header = {0.16, 0.12, 0.06, 1},
    text = {0.83, 0.78, 0.67},
}
local backdrop = { bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 }
local viewLabels = { all = "All materials", favorites = "Favorites" }
local playerColumns = {
    {"Player", 15, 144}, {"Skills", 176, 64}, {"Bags", 259, 44},
    {"Last online", 321, 113}, {"Whisper", 449, 89},
}

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
    frame:SetBackdropColor(unpack(colors.panel))
    if border then frame:SetBackdropBorderColor(unpack(border))
    else frame:SetBackdropBorderColor(0, 0, 0, 0) end
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

-- Character rows will supply validated primary-profession keys from guild data.
function addon.SetPlayerSkills(row, skills)
    if not row.skillSlots then
        row.skillSlots = {}
        for i = 1, 2 do
            local slot = Panel(row, 0, 0, 26, 26, colors.border)
            slot:ClearAllPoints()
            slot:SetPoint("LEFT", playerColumns[2][2] + 3 + (i - 1) * 32, 0)
            slot.icon = Icon(slot, nil, 2, 2, 22)
            row.skillSlots[i] = slot
        end
    end
    for i = 1, 2 do
        local key = addon.Accessible(skills) and type(skills) == "table" and skills[i]
        local texture
        if addon.Accessible(key) and type(key) == "string"
            and key ~= "Cooking" and key ~= "FirstAid" and key ~= "Fishing" then
            for _, profession in ipairs(addon.professions) do
                if profession[1] == key then texture = "Interface\\Icons\\" .. profession[2]; break end
            end
        end
        local icon = row.skillSlots[i].icon
        icon:SetTexture(texture)
        icon:SetShown(texture ~= nil)
    end
end

local function Tip(frame, value)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(value, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function InventoryHeader(parent, x, y, width, sharing)
    local header = Panel(parent, x, y, width, 39)
    header:SetBackdropColor(unpack(colors.header))
    local contentWidth = width - 24 - (sharing and 92 or 0) -- same scrollbar/action space as the rows
    Label(header, L["Material"], 19, 11, contentWidth * 0.5 - 33, 15)
    Label(header, L["Used by"], contentWidth * 0.5, 11, contentWidth * 0.5 - 114, 15)
    Label(header, L["Bags"], contentWidth - 100, 11, 100, 15):SetJustifyH("CENTER")
end

local function MaterialProfessionCell(parent, x, y, width)
    local cell = CreateFrame("Frame", nil, parent)
    cell:SetPoint("TOPLEFT", x, -y)
    cell:SetSize(width, 24)
    cell.slots = {}
    cell.unknown = Label(cell, "—", 0, 3, 24, 16, muted)
    return cell
end

local function SetMaterialProfessions(cell, professions)
    local count = 0
    local size, columns = 24, math.max(1, math.floor((cell:GetWidth() + 2) / 26))
    if addon.Accessible(professions) and type(professions) == "table" then
        for _, profession in ipairs(addon.professions) do
            local known = professions[profession[1]]
            if addon.Accessible(known) and known == true then
                local name = L[profession[1]]
                count = count + 1
                local slot = cell.slots[count]
                if not slot then
                    slot = Panel(cell, (count - 1) * (size + 2), 0, size, size, colors.border)
                    slot:EnableMouse(true)
                    slot.icon = Icon(slot, nil, 2, 2, size - 4)
                    cell.slots[count] = slot
                end
                slot.icon:SetTexture("Interface\\Icons\\" .. profession[2])
                Tip(slot, name)
                slot:Show()
            end
        end
    end
    -- Keep icons readable in narrow inventories, centering two lines inside the 55-pixel row.
    local top = (24 - (math.ceil(count / columns) * 26 - 2)) / 2
    for i = 1, count do
        local slot = cell.slots[i]
        slot:ClearAllPoints()
        slot:SetPoint("TOPLEFT", ((i - 1) % columns) * 26, -top - math.floor((i - 1) / columns) * 26)
    end
    for i = count + 1, #cell.slots do cell.slots[i]:Hide() end
    cell.unknown:SetShown(count == 0)
end

local function Button(parent, text, x, y, width, height, callback, texture)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetPoint("TOPLEFT", x, -y)
    button:SetSize(width, height)
    button:SetBackdrop(backdrop)
    button:SetBackdropColor(unpack(colors.button))
    button:SetBackdropBorderColor(0, 0, 0, 0)
    button:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
    button:GetHighlightTexture():SetVertexColor(1, 0.8, 0.4, 0.025)
    button.label = Label(button, text, texture and 47 or 10, (height - 18) / 2, width - (texture and 58 or 20), 16)
    button.label:SetWordWrap(false)
    if not texture then button.label:SetJustifyH("CENTER") end
    if texture then button.image = Icon(button, texture, 9, (height - 30) / 2, 30) end
    button:RegisterForClicks("LeftButtonUp")
    button:SetScript("OnClick", callback)
    return button
end

local function CloseButton(parent, x, y, size, callback)
    local button = CreateFrame("Button", nil, parent, "UIPanelCloseButtonNoScripts")
    button:SetPoint("TOPLEFT", x, -y)
    button:SetSize(size, size)
    button:RegisterForClicks("LeftButtonUp")
    button:SetScript("OnClick", callback)
    return button
end

local function Highlight(button, active)
    if not button.selection then
        local marker = button:CreateTexture(nil, "ARTWORK")
        marker:SetTexture("Interface\\Buttons\\WHITE8X8")
        marker:SetVertexColor(unpack(colors.accent))
        if button.tab then
            marker:SetPoint("BOTTOMLEFT", 10, 0)
            marker:SetSize(button:GetWidth() - 20, 2)
        else
            marker:SetPoint("LEFT", 0, 0)
            marker:SetSize(2, button:GetHeight() - 12)
        end
        button.selection = marker
    end
    button.selection:SetShown(active)
    button:SetBackdropColor(unpack(active and colors.selected or colors.button))
    button.label:SetTextColor(unpack(active and cream or colors.text))
end

local function Search(parent, placeholder, x, y, width)
    local shell = Panel(parent, x, y, width, 35, colors.border)
    local field = CreateFrame("EditBox", nil, shell)
    field:SetPoint("TOPLEFT", 12, -5)
    field:SetPoint("BOTTOMRIGHT", -34, 5)
    field:SetFontObject("GameFontHighlight")
    field:SetAutoFocus(false)
    field:SetMaxLetters(80)
    local hint = Label(shell, L[placeholder], 12, 9, width - 48, 14, muted)
    field:SetScript("OnTextChanged", function(self, userInput)
        local text = self:GetText()
        hint:SetShown(text == "")
        self.searchRevision = (self.searchRevision or 0) + 1
        local revision = self.searchRevision
        local function ApplySearch()
            if revision ~= self.searchRevision then return end
            self.appliedText = text
            if self.list then self.list.scroll.ScrollBar:SetValue(0) end
            addon.Refresh()
        end
        if userInput and text ~= "" then C_Timer.After(0.15, ApplySearch) else ApplySearch() end
    end)
    field:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    field:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    CloseButton(shell, width - 31, 3, 28, function() field:SetText(""); field:ClearFocus() end)
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

local function LayoutProfessions()
    local learned = addon.LearnedProfessions()
    if not learned then return end -- Keep the last layout when the client cannot supply a complete read.
    local order = table.concat(learned, ":")
    if professionList.order == order then return end
    professionList.order = order
    local y, seen = 40, {}
    local function Heading(label, shown)
        label:SetShown(shown)
        label.separator:SetShown(shown)
        if shown then
            label:ClearAllPoints()
            label:SetPoint("TOPLEFT", 8, -y - 12)
            y = y + 36
        end
    end
    local function Place(key)
        local button = professionButtons[key]
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", 0, -y)
        y = y + 40
    end
    Heading(professionList.myTitle, #learned > 0)
    for _, key in ipairs(learned) do Place(key); seen[key] = true end
    Heading(professionList.otherTitle, #learned < #addon.professions)
    for _, entry in ipairs(addon.professions) do
        if not seen[entry[1]] then Place(entry[1]) end
    end
    professionList.content:SetHeight(y)
    professionList.scroll:UpdateScrollChildRect()
    local maximum = math.max(0, y - professionList.scroll:GetHeight())
    professionList.scroll.ScrollBar:SetValue(math.min(professionList.scroll:GetVerticalScroll(), maximum))
end

local function Favorite(id)
    return type(addon.db.favorites) == "table" and addon.db.favorites[id] == true
end

local function Star(button, id)
    local favorite = Favorite(id)
    local atlas = favorite and "auctionhouse-icon-favorite" or "auctionhouse-icon-favorite-off"
    button.icon:SetAtlas(atlas)
    button:GetHighlightTexture():SetAtlas(atlas)
    button:GetHighlightTexture():SetAlpha(favorite and 0.2 or 0.4)
    Tip(button, L[favorite and "Remove from favorites" or "Add to favorites"])
end

local function StarButton(parent, x, y, callback)
    local button = CreateFrame("Button", nil, parent)
    button:SetPoint("TOPLEFT", x, -y)
    button:SetSize(32, 32)
    -- Native favorite atlases retain their 20:18 proportions inside a larger click target.
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("CENTER")
    button.icon:SetSize(20, 18)
    button:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
    local highlight = button:GetHighlightTexture()
    highlight:ClearAllPoints()
    highlight:SetPoint("CENTER")
    highlight:SetSize(20, 18)
    button:RegisterForClicks("LeftButtonUp")
    button:SetScript("OnClick", callback)
    return button
end

local RefreshMaterialDetail
local function RenderVisibleRows(list)
    local entries = list.entries
    local own = list.snapshot ~= nil
    local hidden = list.hidden
    local contentWidth = list.width - (list.sharing and 92 or 0)
    local catalog = own and addon.Catalog()
    local first = math.max(1, math.floor(list.scroll:GetVerticalScroll() / 55) + 1)
    local count = math.max(0, math.min(math.ceil(list.scroll:GetHeight() / 55) + 1, #entries - first + 1))
    for i = 1, count do
        local index = first + i - 1
        local entry = entries[index]
        local row = list.rows[i]
        if not row then
            row = Button(list.content, "", 0, (i - 1) * 55, list.width, 55, function(self)
                if not own and not hidden and selected ~= self.itemID then
                    selected = self.itemID
                    for _, visible in ipairs(list.rows) do Highlight(visible, visible.itemID == selected) end
                    RefreshMaterialDetail()
                end
            end)
            local slot = Panel(row, 7, 6, 43, 43)
            row.icon = Icon(slot, nil, 2, 2, 39)
            row.label:ClearAllPoints()
            row.label:SetPoint("LEFT", 59, 0)
            row.label:SetWidth(own and contentWidth * 0.5 - 73 or list.width - (hidden and 155 or 96))
            row.label:SetJustifyH("LEFT")
            if own then
                row.usedBy = MaterialProfessionCell(row, contentWidth * 0.5, 15.5, contentWidth * 0.5 - 114)
                row.count = Label(row, "", contentWidth - 100, 18, 100, 16)
                row.count:SetJustifyH("CENTER")
            elseif not hidden then
                row.star = StarButton(row, list.width - 36, 11, function() addon.ToggleFavorite(row.itemID); addon.Refresh() end)
            end
            if list.sharing then
                row.sharing = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
                row.sharing:SetPoint("TOPLEFT", list.width - 88, -13.5)
                row.sharing:SetSize(28, 28)
                Label(row, L["Share"], list.width - 59, 20, 59, 14)
                row.sharing:SetScript("OnClick", function(self)
                    addon.SetItemHidden(row.itemID, not self:GetChecked())
                    GameTooltip:Hide()
                    addon.Refresh()
                end)
                Tip(row.sharing, L["Share this item with your guild. Uncheck to stop sharing."])
                row.privateNote = Label(row, L["Not shared with guild"], 59, 32, contentWidth * 0.5 - 73, 12, muted)
                row.privateNote:SetWordWrap(false)
            elseif hidden then
                row.sharing = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                row.sharing:SetPoint("TOPLEFT", list.width - 88, -14)
                row.sharing:SetSize(84, 27)
                row.sharing:SetText(L["Share"])
                row.sharing:SetScript("OnClick", function()
                    addon.SetItemHidden(row.itemID, false)
                    GameTooltip:Hide()
                    addon.Refresh()
                end)
                Tip(row.sharing, L["Share this item again."])
            end
            list.rows[i] = row
        end
        if row.itemID ~= entry.id then
            -- A recycled row must not leave a tooltip describing its previous item.
            GameTooltip:Hide()
        end
        row:SetPoint("TOPLEFT", 0, -(index - 1) * 55)
        row.itemID = entry.id
        row.label:SetText(entry.name)
        row.icon:SetTexture(entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        Highlight(row, not own and not hidden and entry.id == selected)
        if list.sharing then
            local excluded = addon.IsItemHidden(entry.id)
            row.sharing:SetChecked(not excluded)
            row.privateNote:SetShown(excluded)
            row.label:ClearAllPoints()
            row.label:SetPoint("LEFT", 59, excluded and 8 or 0)
        end
        if own then
            row.count:SetText(entry.count)
            SetMaterialProfessions(row.usedBy, catalog[entry.id])
        elseif not hidden then
            Star(row.star, entry.id)
        end
        row:Show()
    end
    for i = count + 1, #list.rows do list.rows[i]:Hide() end
end

local function RenderList(list, entries, snapshot)
    list.entries, list.snapshot = entries, snapshot
    if not list.virtualized then
        list.virtualized = true
        list.scroll:HookScript("OnVerticalScroll", function()
            if not list.updating then RenderVisibleRows(list) end
        end)
    end
    list.updating = true
    list.content:SetHeight(math.max(1, #entries * 55))
    list.scroll:UpdateScrollChildRect()
    list.scroll.ScrollBar:SetValue(math.min(list.scroll.ScrollBar:GetValue(), list.scroll:GetVerticalScrollRange()))
    list.updating = false
    RenderVisibleRows(list)
end

local function RefreshCharacters()
    local entries = addon.GuildCharacters((characterSearch.appliedText or ""))
    local current
    for _, entry in ipairs(entries) do if entry.id == selectedCharacter then current = entry end end
    current = current or entries[1]
    local nextID = current and current.id
    if selectedCharacter ~= nextID then characterItems.scroll.ScrollBar:SetValue(0) end
    selectedCharacter = nextID
    for i, entry in ipairs(entries) do
        local row = characterList.rows[i]
        if not row then
            row = Button(characterList.content, "", 0, (i - 1) * 46, characterList.width, 46, function(self)
                selectedCharacter = self.characterID
                characterItems.scroll.ScrollBar:SetValue(0)
                addon.Refresh()
            end)
            row.label:SetJustifyH("LEFT")
            characterList.rows[i] = row
        end
        row.characterID = entry.id
        row.label:SetText(entry.name)
        Tip(row, entry.name)
        Highlight(row, entry.id == selectedCharacter)
        row:Show()
    end
    for i = #entries + 1, #characterList.rows do characterList.rows[i]:Hide() end
    characterList.content:SetHeight(math.max(1, #entries * 46))
    characterList.scroll:UpdateScrollChildRect()
    characterList.scroll.ScrollBar:SetValue(math.min(characterList.scroll.ScrollBar:GetValue(), characterList.scroll:GetVerticalScrollRange()))
    characterList.empty:SetShown(#entries == 0)
    characterList.empty:SetText(L[(characterSearch.appliedText or "") == "" and "No character data yet." or "No matching characters."])
    characterName:SetText(current and current.name or L["Select a character"])
    characterNote:SetText(current and string.format(L["Observed: %s"], date("%Y-%m-%d %H:%M:%S", current.snapshot.observedAt)) or "")
    local items = addon.CharacterItems(current, (characterItemSearch.appliedText or ""))
    RenderList(characterItems, items, current and current.snapshot)
    characterItems.empty:SetShown(#items == 0)
    characterItems.empty:SetText(L[not current and "Select a character to view their items."
        or (characterItemSearch.appliedText or "") ~= "" and "No matching materials." or "No items recorded for this character."])
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

RefreshMaterialDetail = function()
    detailSlot:SetShown(selected ~= nil)
    detailStar:SetShown(selected ~= nil)
    detailProfessions:SetShown(selected ~= nil)
    if selected then
        local data = addon.ItemData(selected)
        detailName:SetText(data.name)
        detailIcon:SetTexture(data.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        SetMaterialProfessions(detailProfessions, addon.Catalog()[selected])
        Star(detailStar, selected)
    else
        detailName:SetText(L["Select a material"])
    end
    emptyOwners:SetText(L[selected and "No players found with this material." or "Select a material"])
end

function addon.Refresh()
    if not window or not window:IsShown() then return end
    local preferences = Preferences()
    for key, button in pairs(tabs) do Highlight(button, key == page) end
    browser:SetShown(page == "materials")
    characters:SetShown(page == "characters")
    inventory:SetShown(page == "inventory")
    settings:SetShown(page == "settings")
    if page == "materials" then
        LayoutProfessions()
        for key, button in pairs(navigation) do Highlight(button, key == view) end
        for key, button in pairs(professionButtons) do Highlight(button, key == (profession or "all")) end
        local entries = addon.Materials(view, profession, (search.appliedText or ""))
        local found = false
        for _, entry in ipairs(entries) do if entry.id == selected then found = true; break end end
        if not found then selected = entries[1] and entries[1].id end
        listTitle:SetText(L[viewLabels[view]])
        listHint:SetText(L["Partial catalog · discovered materials"])
        materialList.empty:SetShown(#entries == 0)
        materialList.empty:SetText(L["No matching materials."] .. "\n\n" .. L[view == "favorites"
            and "Mark materials with a star to add them to favorites."
            or "Open your profession windows to discover recipe materials."])
        RenderList(materialList, entries)
        RefreshMaterialDetail()
    elseif page == "characters" then
        RefreshCharacters()
    elseif page == "inventory" then
        local entries = addon.Materials("all", nil, (bagSearch.appliedText or ""), true)
        RenderList(bagList, entries, addon.snapshot)
        bagList.empty:SetShown(#entries == 0)
        bagList.empty:SetText(L[addon.snapshot and "No matching materials." or "No complete bag observation yet."])
        local hidden = addon.HiddenItems()
        RenderList(hiddenList, hidden)
        hiddenList.empty:SetShown(#hidden == 0)
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
    if search then
        search:ClearFocus(); bagSearch:ClearFocus(); characterSearch:ClearFocus(); characterItemSearch:ClearFocus()
    end
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
    window:SetBackdropColor(unpack(colors.window))
    window:SetBackdropBorderColor(unpack(gold))
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    UISpecialFrames[#UISpecialFrames + 1] = "GuildStockFrame"
    Icon(window, "Interface\\Icons\\INV_Crate_01", 19, 15, 49)
    Label(window, "GuildStock", 82, 13, 260, 28, cream, true)
    Label(window, L["Guild materials"], 83, 45, 260, 15, muted)
    for i, tab in ipairs({{"Materials", "materials"}, {"Characters", "characters"}, {"My inventory", "inventory"}, {"Settings", "settings"}}) do
        tabs[tab[2]] = Button(window, L[tab[1]], 348 + (i - 1) * 166, 16, 166, 45, function() SelectPage(tab[2]) end)
        tabs[tab[2]].tab = true
    end
    CloseButton(window, 1138, 14, 30, function() window:Hide() end)
    browser = CreateFrame("Frame", nil, window)
    browser:SetAllPoints()
    sidebar = Panel(browser, 7, 77, 247, 566)
    for i, entry in ipairs({{"all", "INV_Crate_01"}, {"favorites", "INV_Misc_Note_01"}}) do
        navigation[entry[1]] = Button(sidebar, L[viewLabels[entry[1]]], 7, 13 + (i - 1) * 47, 233, 44, function()
            if view == entry[1] and (view ~= "all" or profession == nil) then return end
            view = entry[1]
            if view == "all" then profession = nil end
            materialList.scroll.ScrollBar:SetValue(0)
            addon.Refresh()
        end, "Interface\\Icons\\" .. entry[2])
    end
    navigation.favorites.image:SetTexCoord(0, 1, 0, 1)
    navigation.favorites.image:SetAtlas("auctionhouse-icon-favorite")
    navigation.favorites.image:SetSize(20, 18)
    navigation.favorites.image:ClearAllPoints()
    navigation.favorites.image:SetPoint("LEFT", 14, 0)
    local usedByTitle = Label(sidebar, L["Used by"], 15, 118, 202, 13, muted)
    professionList = Scroll(sidebar, 7, 145, 234, 404)
    professionButtons.all = Button(professionList.content, L["All professions"], 0, 0, 210, 40, function()
        if profession == nil then return end
        profession = nil; materialList.scroll.ScrollBar:SetValue(0); addon.Refresh()
    end, "Interface\\Icons\\Trade_Mining")
    for i, entry in ipairs(addon.professions) do
        professionButtons[entry[1]] = Button(professionList.content, L[entry[1]], 0, i * 40, 210, 40, function()
            if profession == entry[1] then return end
            profession = entry[1]; materialList.scroll.ScrollBar:SetValue(0); addon.Refresh()
        end, "Interface\\Icons\\" .. entry[2])
    end
    professionList.content:SetHeight((#addon.professions + 1) * 40)
    professionList.myTitle = Label(professionList.content, L["My professions"], 8, 0, 202, 13, muted)
    professionList.otherTitle = Label(professionList.content, L["Other professions"], 8, 0, 202, 13, muted)
    professionList.myTitle:SetWordWrap(false)
    professionList.otherTitle:SetWordWrap(false)
    professionList.myTitle:Hide()
    professionList.otherTitle:Hide()
    for _, entry in ipairs({{sidebar, usedByTitle}, {professionList.content, professionList.myTitle},
        {professionList.content, professionList.otherTitle}}) do
        local title = entry[2]
        title.separator = entry[1]:CreateTexture(nil, "ARTWORK")
        title.separator:SetTexture("Interface\\Buttons\\WHITE8X8")
        title.separator:SetVertexColor(unpack(gold))
        title.separator:SetRoundLayoutToNearestPixel(true)
        title.separator:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
        title.separator:SetSize(title:GetWidth() * 0.6, 1)
        title.separator:SetShown(title:IsShown())
    end
    local middle = Panel(browser, 258, 77, 324, 566)
    search = Search(middle, "Search materials...", 11, 13, 301)
    listTitle = Label(middle, "", 14, 64, 295, 19)
    listHint = Label(middle, "", 14, 90, 295, 12, muted)
    materialList = Scroll(middle, 8, 119, 307, 434)
    search.list = materialList
    materialList.empty = Label(middle, "", 22, 184, 278, 15, muted)
    materialList.empty:SetJustifyH("CENTER")
    details = Panel(browser, 586, 77, 587, 566)
    detailSlot = Panel(details, 17, 12, 43, 43)
    detailIcon = Icon(detailSlot, nil, 2, 2, 39)
    detailName = Label(details, "", 76, 14, 453, 16)
    detailName:SetWordWrap(false)
    detailProfessions = MaterialProfessionCell(details, 76, 36, 453)
    detailStar = StarButton(details, 539, 17, function() if selected then addon.ToggleFavorite(selected); addon.Refresh() end end)
    local tablePanel = Panel(details, 17, 67, 554, 463)
    tablePanel:SetPoint("BOTTOMRIGHT", -16, 36)
    local tableHeader = Panel(tablePanel, 0, 0, 554, 41)
    tableHeader:SetBackdropColor(unpack(colors.header))
    for _, column in ipairs(playerColumns) do
        local heading = Label(tableHeader, L[column[1]], column[2], 13, column[3], 14)
        heading:SetWordWrap(false)
        if column[1] == "Skills" then heading:SetJustifyH("CENTER") end
    end
    emptyOwners = Label(tablePanel, "", 35, 0, 484, 18, muted)
    emptyOwners:ClearAllPoints()
    emptyOwners:SetPoint("CENTER", 0, -20)
    emptyOwners:SetJustifyV("MIDDLE")
    emptyOwners:SetJustifyH("CENTER")
    local quantityNote = Label(details, L["Quantities reflect the last synchronization."], 17, 538, 269, 13, muted)
    quantityNote:SetWordWrap(false)
    quantityNote:SetHeight(16)
    local offlineNote = Label(details, L["Offline members: last known counts."], 302, 538, 269, 13, muted)
    offlineNote:SetWordWrap(false)
    offlineNote:SetHeight(16)
    offlineNote:SetJustifyH("RIGHT")

    characters = CreateFrame("Frame", nil, window)
    characters:SetAllPoints()
    local characterSidebar = Panel(characters, 7, 77, 300, 566)
    Label(characterSidebar, L["Characters"], 18, 16, 264, 24, cream, true)
    Label(characterSidebar, L["Guildmates with inventory data"], 18, 51, 264, 14, muted)
    characterSearch = Search(characterSidebar, "Search characters...", 14, 82, 272)
    characterList = Scroll(characterSidebar, 12, 129, 276, 421)
    characterSearch.list = characterList
    characterList.empty = Label(characterSidebar, "", 18, 225, 264, 16, muted)
    characterList.empty:SetJustifyH("CENTER")
    local characterDetail = Panel(characters, 311, 77, 862, 566)
    characterName = Label(characterDetail, "", 22, 18, 818, 25, cream, true)
    characterName:SetWordWrap(false)
    Label(characterDetail, L["Last known bag inventory"], 22, 53, 818, 15, muted)
    characterItemSearch = Search(characterDetail, "Search character items...", 20, 82, 820)
    InventoryHeader(characterDetail, 20, 130, 820)
    characterItems = Scroll(characterDetail, 20, 169, 820, 351)
    characterItemSearch.list = characterItems
    characterItems.empty = Label(characterDetail, "", 62, 300, 738, 17, muted)
    characterItems.empty:SetJustifyH("CENTER")
    characterNote = Label(characterDetail, "", 22, 536, 818, 13, muted)

    inventory = Panel(window, 7, 77, 1166, 566)
    Label(inventory, L["My inventory"], 25, 20, 1050, 29, cream, true)
    Label(inventory, L["Profession materials in your bags"], 26, 63, 1050, 17, muted)
    local bagWidth, hiddenWidth = 1100 * 0.7, 1100 * 0.3 -- 18-pixel gutter
    bagSearch = Search(inventory, "Search my bags...", 23, 98, bagWidth)
    InventoryHeader(inventory, 23, 148, bagWidth, true)
    bagList = Scroll(inventory, 23, 187, bagWidth, 325)
    bagList.sharing = true
    bagSearch.list = bagList
    bagList.empty = Label(inventory, "", 45, 283, bagWidth - 68, 17, muted)
    bagList.empty:SetJustifyH("CENTER")
    local hiddenPanel = Panel(inventory, 23 + bagWidth + 18, 98, hiddenWidth, 414)
    Label(hiddenPanel, L["Not shared"], 14, 12, hiddenWidth - 28, 22, cream, true)
    Label(hiddenPanel, L["Excluded from guild sharing. Use Share to include them again."], 14, 44, hiddenWidth - 28, 14, muted)
    hiddenList = Scroll(hiddenPanel, 0, 89, hiddenWidth, 325)
    hiddenList.hidden = true
    hiddenList.empty = Label(hiddenPanel, L["No excluded items."], 20, 185, hiddenWidth - 40, 17, muted)
    hiddenList.empty:SetJustifyH("CENTER")
    inventoryNote = Label(inventory, "", 26, 534, 1090, 13, muted)

    settings = Panel(window, 7, 77, 1166, 566)
    Label(settings, L["Settings"], 27, 20, 1000, 29, cream, true)
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
    settings.initial:SetBackdropBorderColor(unpack(colors.border))
    Icon(settings.initial, "Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up", 241, 5, 24)
    settings.choices = Panel(settings, 207, 253, 271, 73, colors.border)
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
    slider:SetBackdropColor(unpack(colors.button))
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
    window:SetScript("OnHide", function()
        search:ClearFocus(); bagSearch:ClearFocus(); characterSearch:ClearFocus(); characterItemSearch:ClearFocus()
        settings.choices:Hide()
    end)
    ApplyScale()
end

local function Toggle()
    if not addon.db then return end
    if not window then CreateWindow() end
    if not window:IsShown() then view = InitialView(); page = "materials"; profession = nil end
    window:SetShown(not window:IsShown())
end

-- Forever loads its profession window on demand. Keep this shortcut outside
-- rightProfessionTabs so native profession selection never treats it as a skill.
local professionEvents = CreateFrame("Frame")
local function CreateProfessionsShortcut()
    local parent = ProfessionsFrame
    if not parent or not parent.ProfessionsOverviewTab or InCombatLockdown() then return end
    local button = CreateFrame("Frame", "GuildStockProfessionsButton", parent, "LargeSideTabButtonTemplate")
    button:SetPoint("BOTTOMLEFT", parent, "BOTTOMRIGHT", 0, 4)
    button:EnableMouse(true)
    button.Icon:SetTexture("Interface\\Icons\\INV_Crate_01")
    button:SetFillToInterior(true)
    button:SetChecked(false)
    button.tooltipText = "GuildStock"
    button:SetCustomOnMouseUpHandler(function(_, mouseButton, upInside)
        if mouseButton == "LeftButton" and upInside then
            GameTooltip:Hide()
            Toggle()
        end
    end)
    button:SetScript("OnHide", function(self)
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)
    professionEvents:UnregisterAllEvents()
end
for _, event in ipairs({"ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_REGEN_ENABLED"}) do
    professionEvents:RegisterEvent(event)
end
professionEvents:SetScript("OnEvent", function(_, event, loadedName)
    if event ~= "ADDON_LOADED" or loadedName == "Blizzard_Professions" then
        CreateProfessionsShortcut()
    end
end)

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
