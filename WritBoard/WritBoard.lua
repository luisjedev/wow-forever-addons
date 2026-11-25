local _, addon = ...
local L = addon.L

local WIDTH, HEIGHT, ROW_H, LIST_W = 1000, 560, 24, 930
-- Column x offsets inside a row: item, profession, reputation, recipient, item price, writ price, total.
local COL = { 28, 250, 345, 395, 610, 720, 830 }
local MAP_X = 575 -- map column, between the recipient and the prices
local PRICE_W = 100
-- Recipes tab columns: name, skill, reputation, cost, learned.
local RCOL = { 28, 470, 560, 690, 820 }
local db, window, content, summary, zoneMenu, recipePanel
local writParts = {} -- writ list widgets, hidden on the Recipes tab
local recipeProf -- profession key open on the Recipes tab; nil shows the profession tiles
local recipeRows = {}
local zones = {} -- selected zone keys; empty means all zones
local rows, buttons = {}, {}
local filter = "all"

local function Price(id)
    if not (Auctionator and Auctionator.API and Auctionator.API.v1) then return nil end
    local ok, price = pcall(Auctionator.API.v1.GetAuctionPriceByItemID, "WritBoard", id)
    return ok and price or nil
end

local function Money(copper)
    return copper and GetMoneyString(copper, true) or "—"
end

-- Writs in the backpack and bags, by requested item.
local function ScanBags()
    local stacks = {}
    if not (C_Container and C_Container.GetContainerNumSlots) then return {} end
    for bag = 0, NUM_BAG_SLOTS or 4 do
        local ok, slots = pcall(C_Container.GetContainerNumSlots, bag)
        for slot = 1, ok and type(slots) == "number" and slots or 0 do
            local okInfo, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
            if okInfo and type(info) == "table" then
                stacks[#stacks + 1] = { id = info.itemID, link = info.hyperlink, count = info.stackCount }
            end
        end
    end
    return addon.CountWrits(stacks)
end

local function Have(writ)
    local total = 0
    for _, id in ipairs(writ.ids) do total = total + (C_Item.GetItemCount(id, true) or 0) end
    return total
end

-- Opens the delivery zone's map, with a waypoint on the recipient when coordinates are known (as in ProfGuide).
local function ShowOnMap(writ)
    local pin, mapID = writ.pin, writ.pin and writ.pin[1] or addon.ZONE_MAPS[writ.zone]
    if not mapID then return end
    pcall(function()
        if pin and C_Map and C_Map.SetUserWaypoint and UiMapPoint then
            C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(pin[1], pin[2] / 100, pin[3] / 100))
            if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
        end
        if OpenWorldMap then OpenWorldMap(mapID) else ToggleWorldMap() end
    end)
end

local function Text(parent, font, x, width)
    local text = parent:CreateFontString(nil, "OVERLAY", font)
    text:SetPoint("LEFT", x, 0)
    text:SetWidth(width)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    return text
end

local function RowTooltip(self)
    local writ = self.writ
    if not writ then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if writ.ids[1] then GameTooltip:SetItemByID(writ.ids[1]) else GameTooltip:SetText(writ.item) end
    if writ.skill then GameTooltip:AddLine(L[addon.TIERS[writ.tier]] .. " · " .. L["Skill %d"]:format(writ.skill), 1, 0.82, 0) end
    if writ.ids[1] then GameTooltip:AddLine(L["You have %d / %d"]:format(Have(writ), writ.qty or 1), 1, 1, 1) end
    if writ.ids[1] and not addon.Price(writ, Price) then
        GameTooltip:AddLine(L["No Auctionator price yet: scan the auction house with Auctionator."], 0.6, 0.6, 0.6, true)
    end
    GameTooltip:Show()
end

local function Row(i)
    local row = CreateFrame("Button", nil, content)
    row:SetSize(LIST_W, ROW_H)
    row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row.stripe = row:CreateTexture(nil, "BACKGROUND")
    row.stripe:SetAllPoints()
    row.stripe:SetColorTexture(1, 1, 1, i % 2 == 0 and 0.04 or 0)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(20, 20)
    row.icon:SetPoint("LEFT", 4, 0)
    row.item = Text(row, "GameFontHighlight", COL[1], COL[2] - COL[1] - 6)
    row.prof = Text(row, "GameFontHighlightSmall", COL[2], COL[3] - COL[2] - 6)
    row.rep = Text(row, "GameFontNormal", COL[3], COL[4] - COL[3] - 6)
    row.to = Text(row, "GameFontHighlightSmall", COL[4], MAP_X - COL[4] - 6)
    row.price = Text(row, "GameFontHighlightSmall", COL[5], PRICE_W)
    row.writPrice = Text(row, "GameFontHighlightSmall", COL[6], PRICE_W)
    row.total = Text(row, "GameFontHighlight", COL[7], PRICE_W)
    for _, text in ipairs({ row.price, row.writPrice, row.total }) do text:SetJustifyH("RIGHT") end
    row.map = CreateFrame("Button", nil, row)
    row.map:SetSize(18, 18)
    row.map:SetPoint("LEFT", MAP_X, 0)
    row.map:SetNormalTexture("Interface\\Icons\\INV_Misc_Map_01")
    row.map:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    row.map:SetScript("OnClick", function(self) ShowOnMap(self:GetParent().writ) end)
    row.map:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        local writ = self:GetParent().writ
        GameTooltip:SetText(writ.zone)
        GameTooltip:AddLine(writ.pin and L["Show on map"] or L["Open the zone map (exact spot not published yet)"], 1, 1, 1, true)
        GameTooltip:Show()
    end)
    row.map:SetScript("OnLeave", GameTooltip_Hide)
    row:SetScript("OnEnter", RowTooltip)
    -- Shift-click links the item into chat or any search box (auction house); Ctrl-click previews it.
    row:SetScript("OnClick", function(self)
        local writ = self.writ
        if not writ or not IsModifiedClick() then return end
        local link = writ.ids[1] and select(2, C_Item.GetItemInfo(writ.ids[1]))
        if link then HandleModifiedItemClick(link) elseif IsModifiedClick("CHATLINK") then ChatEdit_InsertLink(writ.item) end
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    rows[i] = row
    return row
end

-- Learned check for a vendor recipe's crafting spell.
-- shortcut: IsPlayerSpell on profession recipes is not yet verified in the Forever client; see docs/BLIZZARD_API.md.
local function Known(spell)
    if IsPlayerSpell and IsPlayerSpell(spell) then return true end
    if not (C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo) then return false end
    local ok, info = pcall(C_TradeSkillUI.GetRecipeInfo, spell)
    return ok and type(info) == "table" and info.learned == true
end

local function Standing(rep)
    return _G["FACTION_STANDING_LABEL" .. (rep + 4)] or L[addon.STANDINGS[rep + 1]]
end

local function ProfName(key)
    return key == "other" and L["Other items"] or L[addon.PROFS[key]]
end

-- Vendor list of a tile: recipes (by spell) or the other items (by item ID).
local function VendorList(key)
    return key == "other" and addon.vendorItems or addon.recipes[key]
end

local function RecipeRow(i)
    local row = CreateFrame("Button", nil, recipePanel.content)
    row:SetSize(LIST_W, ROW_H)
    row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    local stripe = row:CreateTexture(nil, "BACKGROUND")
    stripe:SetAllPoints()
    stripe:SetColorTexture(1, 1, 1, i % 2 == 0 and 0.04 or 0)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(20, 20)
    row.icon:SetPoint("LEFT", 4, 0)
    row.name = Text(row, "GameFontHighlight", RCOL[1], RCOL[2] - RCOL[1] - 6)
    row.skill = Text(row, "GameFontHighlightSmall", RCOL[2], RCOL[3] - RCOL[2] - 6)
    row.rep = Text(row, "GameFontNormal", RCOL[3], RCOL[4] - RCOL[3] - 6)
    row.cost = Text(row, "GameFontHighlight", RCOL[4], RCOL[5] - RCOL[4] - 6)
    row.learned = row:CreateTexture(nil, "ARTWORK")
    row.learned:SetSize(18, 18)
    row.learned:SetPoint("LEFT", RCOL[5] + 14, 0)
    row:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.item then GameTooltip:SetItemByID(self.id) else GameTooltip:SetSpellByID(self.id) end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    row:SetScript("OnClick", function(self)
        if not IsModifiedClick() then return end
        if self.item then
            local link = select(2, C_Item.GetItemInfo(self.id))
            if link then HandleModifiedItemClick(link) end
        elseif IsModifiedClick("CHATLINK") and C_Spell and C_Spell.GetSpellLink then
            local link = C_Spell.GetSpellLink(self.id)
            if link then ChatEdit_InsertLink(link) end
        end
    end)
    recipeRows[i] = row
    return row
end

local function RefreshRecipes()
    local panel = recipePanel
    panel.tiles:SetShown(recipeProf == nil)
    panel.list:SetShown(recipeProf ~= nil)
    if not recipeProf then
        for _, tile in ipairs(panel.tileButtons) do
            local list = VendorList(tile.key)
            if tile.key == "other" then
                tile.sub:SetText(L["%d items"]:format(#list))
            else
                local known = addon.CountKnown(list, Known)
                tile.sub:SetText(L["%d / %d learned"]:format(known, #list))
            end
        end
        return
    end
    local list, isItem = VendorList(recipeProf), recipeProf == "other"
    panel.icon:SetTexture(addon.RECIPE_ICONS[recipeProf])
    panel.title:SetText(ProfName(recipeProf))
    local vendor = addon.RECIPE_VENDORS[recipeProf]
    local known = not isItem and addon.CountKnown(list, Known) or 0
    panel.sub:SetText(isItem and L["Camp quartermasters and recipe vendors"]
        or (vendor[UnitFactionGroup("player") == "Horde" and 2 or 1] .. " · " .. L["%d / %d learned"]:format(known, #list)))
    panel.learnedLabel:SetShown(not isItem)
    for i, entry in ipairs(list) do
        local row = recipeRows[i] or RecipeRow(i)
        local id, english, skill, rep, cost = unpack(entry)
        row.id, row.item = id, isItem
        local name = isItem and C_Item.GetItemNameByID(id) or (not isItem and C_Spell and C_Spell.GetSpellName(id)) or english
        local icon = isItem and C_Item.GetItemIconByID(id) or (not isItem and C_Spell and C_Spell.GetSpellTexture(id))
        row.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.name:SetText(name)
        row.skill:SetText(skill > 0 and skill or "")
        row.rep:SetText(Standing(rep))
        row.cost:SetText(cost)
        local learned = not isItem and Known(id)
        if learned then row.name:SetTextColor(0.4, 1, 0.4) else row.name:SetTextColor(1, 1, 1) end
        row.learned:SetShown(not isItem)
        row.learned:SetTexture(learned and "Interface\\RaidFrame\\ReadyCheck-Ready" or "Interface\\RaidFrame\\ReadyCheck-NotReady")
        row:Show()
    end
    for i = #list + 1, #recipeRows do recipeRows[i]:Hide() end
    panel.content:SetHeight(math.max(1, #list * ROW_H))
end

local function CreateRecipePanel()
    local panel = CreateFrame("Frame", nil, window)
    panel:SetPoint("TOPLEFT", 24, -66)
    panel:SetPoint("BOTTOMRIGHT", -40, 52)
    recipePanel = panel

    -- Profession tiles, 4 per row, as in ProfGuide.
    panel.tiles = CreateFrame("Frame", nil, panel)
    panel.tiles:SetAllPoints()
    panel.tileButtons = {}
    local backdrop = { bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 }
    for i, key in ipairs(addon.RECIPE_ORDER) do
        local tile = CreateFrame("Button", nil, panel.tiles, "BackdropTemplate")
        tile:SetSize(162, 92)
        tile:SetPoint("TOPLEFT", 120 + ((i - 1) % 4) * 172, -40 - math.floor((i - 1) / 4) * 102)
        tile:SetBackdrop(backdrop)
        tile:SetBackdropColor(0.08, 0.075, 0.055, 0.9)
        tile:SetBackdropBorderColor(1, 0.82, 0, 0.9)
        tile:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
        tile.key = key
        local icon = tile:CreateTexture(nil, "ARTWORK")
        icon:SetSize(40, 40)
        icon:SetPoint("TOP", 0, -10)
        icon:SetTexture(addon.RECIPE_ICONS[key])
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        local label = tile:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOP", icon, "BOTTOM", 0, -5)
        label:SetText(ProfName(key))
        tile.sub = tile:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        tile.sub:SetPoint("TOP", label, "BOTTOM", 0, -3)
        tile:SetScript("OnClick", function() recipeProf = key; RefreshRecipes() end)
        panel.tileButtons[i] = tile
    end

    -- One profession's vendor list.
    local list = CreateFrame("Frame", nil, panel)
    list:SetAllPoints()
    panel.list = list
    local back = CreateFrame("Button", nil, list, "UIPanelButtonTemplate")
    back:SetSize(110, 22)
    back:SetPoint("TOPLEFT", 0, 0)
    back:SetText(L["Professions"])
    back:SetScript("OnClick", function() recipeProf = nil; RefreshRecipes() end)
    panel.icon = list:CreateTexture(nil, "ARTWORK")
    panel.icon:SetSize(24, 24)
    panel.icon:SetPoint("LEFT", back, "RIGHT", 12, 0)
    panel.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    panel.title = list:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    panel.title:SetPoint("LEFT", panel.icon, "RIGHT", 8, 0)
    panel.sub = list:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panel.sub:SetPoint("LEFT", panel.title, "RIGHT", 12, 0)
    local labels = { L["Recipe"], L["Skill"], L["Reputation"], L["Merchant's Favor"], L["Learned"] }
    for i, label in ipairs(labels) do
        local text = list:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("TOPLEFT", RCOL[i], -32)
        text:SetText(label)
        if i == 5 then panel.learnedLabel = text end
    end
    local scroll = CreateFrame("ScrollFrame", "WritBoardRecipeScrollFrame", list, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 0, -50)
    scroll:SetPoint("BOTTOMRIGHT", 0, 0)
    panel.content = CreateFrame("Frame", nil, scroll)
    panel.content:SetSize(LIST_W, 1)
    scroll:SetScrollChild(panel.content)
end

local function Refresh()
    if not (window and window:IsShown()) then return end
    local recipes = filter == "recipes"
    for _, part in ipairs(writParts) do part:SetShown(not recipes) end
    recipePanel:SetShown(recipes)
    window.source:SetText(recipes and L["Source: wow-professions.com · a green check means you know the recipe"]
        or L["Sources: conquestcapped.com and foreverchanges.pro · prices from Auctionator"])
    for key, button in pairs(buttons) do button:SetEnabled(key ~= filter) end
    if recipes then RefreshRecipes() return end
    local owned = ScanBags()
    local list = addon.Rows(filter, owned, zones)
    local entries = addon.Grouped(list, Price)
    for i, writ in ipairs(entries) do
        local row = rows[i] or Row(i)
        local header = writ.ids == nil
        row.writ = not header and writ or nil
        for _, part in ipairs({ row.icon, row.prof, row.price, row.writPrice }) do part:SetShown(not header) end
        row.stripe:SetColorTexture(0.45, 0.34, 0.16, header and 0.35 or (i % 2 == 0 and 0.04 or 0))
        row.item:SetPoint("LEFT", header and 6 or COL[1], 0)
        if header then
            row.item:SetText(writ.zone or L["Unknown"])
            row.item:SetTextColor(1, 0.82, 0)
            row.map:Hide()
            -- Zone summary over its priced writs: count, reputation, cost per reputation point (with travel), total.
            row.rep:SetText(writ.count > 0 and writ.rep or "")
            row.to:SetText(writ.score and L["%d writs · %s per rep"]:format(writ.count, Money(math.floor(writ.score + 0.5))) or "")
            row.to:SetTextColor(1, 0.82, 0)
            row.total:SetText(writ.count > 0 and Money(writ.cost) or "")
        else
            row.icon:SetTexture(writ.ids[1] and C_Item.GetItemIconByID(writ.ids[1]) or "Interface\\Icons\\INV_Misc_QuestionMark")
            local held = owned[writ.item]
            local name = (writ.qty and writ.qty > 1 and (writ.qty .. " x ") or "") .. writ.item
            row.item:SetText(held and ("|cff33ff33" .. held .. "x|r " .. name) or name)
            if writ.ids[1] and Have(writ) >= (writ.qty or 1) then row.item:SetTextColor(0.4, 1, 0.4) else row.item:SetTextColor(1, 1, 1) end
            row.prof:SetText(writ.prof and L[addon.PROFS[writ.prof]] or "")
            row.rep:SetText(writ.tier and addon.REP[writ.tier] or "?")
            row.to:SetText(writ.npc or L["Unknown"])
            if writ.npc then row.to:SetTextColor(1, 1, 1) else row.to:SetTextColor(0.6, 0.6, 0.6) end
            row.price:SetText(writ.ids[1] and Money(addon.Price(writ, Price)) or "")
            row.writPrice:SetText(writ.writ and Money(addon.WritPrice(writ, Price)) or "")
            row.total:SetText(writ.writ and Money(addon.Total(writ, Price)) or "")
            row.map:SetShown(writ.pin ~= nil or addon.ZONE_MAPS[writ.zone] ~= nil)
            row.map:GetNormalTexture():SetDesaturated(writ.pin == nil)
        end
        row:Show()
    end
    for i = #entries + 1, #rows do rows[i]:Hide() end
    content:SetHeight(math.max(1, #entries * ROW_H))
    local count, rep, cost, unpriced = addon.Summary(owned, Price)
    summary:SetText(L["Writs in bags: %d · %d reputation · cost %s"]:format(count, rep, Money(cost))
        .. (unpriced > 0 and ("  |cff999999(" .. unpriced .. " ?)|r") or ""))
    window.count:SetText(L["%d writs"]:format(#list))
    local picked = 0
    for _ in pairs(zones) do picked = picked + 1 end
    if zoneMenu.OverrideText then
        zoneMenu:OverrideText(picked == 0 and L["All zones"] or picked == 1 and ((next(zones) == "" and L["Unknown"]) or next(zones))
            or L["%d zones"]:format(picked))
    end
end

local function CreateWindow()
    window = CreateFrame("Frame", "WritBoardFrame", UIParent, "BackdropTemplate")
    window:Hide()
    window:SetSize(WIDTH, HEIGHT)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    table.insert(UISpecialFrames, "WritBoardFrame")
    window:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 } })
    local header = window:CreateTexture(nil, "ARTWORK")
    header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    header:SetSize(300, 64)
    header:SetPoint("TOP", 0, 12)
    local title = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", header, "TOP", 0, -14)
    title:SetText("WritBoard")
    local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -8, -8)

    local tabLabels = { all = L["All"], bags = L["In bags"], recipes = L["Recipes"] }
    for i, key in ipairs({ "all", "bags", "recipes" }) do
        local button = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
        button:SetSize(110, 24)
        button:SetPoint("TOPLEFT", 24 + (i - 1) * 116, -32)
        button:SetText(tabLabels[key])
        button:SetScript("OnClick", function()
            filter = key
            db.filter = key
            Refresh()
        end)
        buttons[key] = button
    end
    -- Zone selector: tick any number of zones; "All zones" clears the selection.
    zoneMenu = CreateFrame("DropdownButton", nil, window, "WowStyle1DropdownTemplate")
    zoneMenu:SetWidth(220)
    zoneMenu:SetPoint("TOPLEFT", 24 + 3 * 116 + 10, -32)
    writParts[#writParts + 1] = zoneMenu
    zoneMenu:SetupMenu(function(_, root)
        root:CreateButton(L["All zones"], function()
            wipe(zones)
            Refresh()
        end)
        root:CreateDivider()
        for _, key in ipairs(addon.ZoneKeys()) do
            root:CreateCheckbox(key == "" and L["Unknown"] or key, function() return zones[key] == true end, function()
                zones[key] = not zones[key] or nil
                Refresh()
            end)
        end
    end)
    window.count = window:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    window.count:SetPoint("TOPRIGHT", -40, -40)
    writParts[#writParts + 1] = window.count

    local labels = { L["Item"], L["Profession"], L["Rep"], L["Deliver to"], L["Item price"], L["Writ price"], L["Total"] }
    for i, label in ipairs(labels) do
        local text = window:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("TOPLEFT", 24 + COL[i], -66)
        if i >= 5 then text:SetWidth(PRICE_W); text:SetJustifyH("RIGHT") end
        text:SetText(label)
        writParts[#writParts + 1] = text
    end
    local mapLabel = window:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mapLabel:SetPoint("TOPLEFT", 24 + MAP_X - 4, -66)
    mapLabel:SetText(L["Map"])
    writParts[#writParts + 1] = mapLabel

    local scroll = CreateFrame("ScrollFrame", "WritBoardScrollFrame", window, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 24, -84)
    scroll:SetPoint("BOTTOMRIGHT", -40, 52)
    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(LIST_W, 1)
    scroll:SetScrollChild(content)

    summary = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    summary:SetPoint("BOTTOMLEFT", 28, 30)
    window.source = window:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    window.source:SetPoint("BOTTOMLEFT", 28, 16)
    for _, part in ipairs({ scroll, summary }) do writParts[#writParts + 1] = part end
    CreateRecipePanel()

    window:SetScript("OnShow", Refresh)
    window:SetScript("OnHide", GameTooltip_Hide)
end

function WritBoard_Toggle()
    if not db then return end
    if not window then CreateWindow() end
    window:SetShown(not window:IsShown())
end
WritBoard_OnCompartmentClick = WritBoard_Toggle

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("BAG_UPDATE_DELAYED")
pcall(events.RegisterEvent, events, "NEW_RECIPE_LEARNED") -- the event may not exist in this client
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        if type(WritBoardDB) ~= "table" then WritBoardDB = {} end
        db = WritBoardDB
        if db.filter == "all" or db.filter == "bags" or db.filter == "recipes" then filter = db.filter end
        -- Keep only saved zones that still exist in the data.
        local valid = {}
        for _, key in ipairs(addon.ZoneKeys()) do valid[key] = true end
        if type(db.zones) == "table" then
            for key, on in pairs(db.zones) do if valid[key] and on == true then zones[key] = true end end
        end
        db.zones = zones
        return
    end
    Refresh()
end)

SLASH_WRITBOARD1 = "/writboard"
SLASH_WRITBOARD2 = "/writs"
SlashCmdList["WRITBOARD"] = WritBoard_Toggle
