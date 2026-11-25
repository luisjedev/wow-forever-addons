local _, addon = ...
local L = addon.L
-- Craftsman's Writs view and the vendor recipe lists, drawn inside the ProfGuide window (ProfGuide.lua).
-- No frames are created at load; ProfGuide.lua calls CreateWritsPanel / CreateRecipeList.

local ROW_H, LIST_W = 24, 930
-- Column x offsets inside a row: item, profession, reputation, recipient, item price, writ price, total.
local COL = { 28, 250, 345, 395, 610, 720, 830 }
local MAP_X = 575 -- map column, between the recipient and the prices
local PRICE_W = 100
-- Recipe list columns: name, skill, reputation, cost, learned.
local RCOL = { 28, 470, 560, 690, 820 }
local db, panel, content, summary, zoneMenu, vendorList
local writParts = {} -- writ list widgets, hidden on the vendor items filter
local zones = {} -- selected zone keys; empty means all zones
local rows, buttons = {}, {}
local filter = "all"
local FILTERS = { all = true, bags = true, vendor = true }

local function Price(id)
    if not (Auctionator and Auctionator.API and Auctionator.API.v1) then return nil end
    local ok, price = pcall(Auctionator.API.v1.GetAuctionPriceByItemID, "ProfGuide", id)
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

-- Waypoint on the recipient when coordinates are known; otherwise just the delivery zone's map.
local function ShowWrit(writ)
    if addon.ShowOnMap(writ.pin) then return end
    local mapID = addon.ZONE_MAPS[writ.zone]
    if mapID then pcall(function() if OpenWorldMap then OpenWorldMap(mapID) else ToggleWorldMap() end end) end
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
    row.map:SetScript("OnClick", function(self) ShowWrit(self:GetParent().writ) end)
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

-- Recipe tooltip; with Shift held, the crafted item instead, compared with what you have equipped.
local function RecipeTooltip(row)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    if row.item then
        GameTooltip:SetItemByID(row.id)
    elseif row.craft and IsShiftKeyDown() then
        GameTooltip:SetItemByID(row.craft)
        if GameTooltip_ShowCompareItem then GameTooltip_ShowCompareItem(GameTooltip) end
    else
        if GameTooltip_HideShoppingTooltips then GameTooltip_HideShoppingTooltips(GameTooltip) end
        GameTooltip:SetSpellByID(row.id)
        if row.craft and C_Item.IsEquippableItem(row.craft) then
            GameTooltip:AddLine(L["Hold Shift to compare with your equipped item"], 0.6, 0.8, 1, true)
        end
    end
    GameTooltip:Show()
end

local function RecipeRow(list, i)
    local row = CreateFrame("Button", nil, list.content)
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
    -- Shift pressed or released while hovering swaps between the recipe and the crafted item.
    row:SetScript("OnEnter", function(self)
        self:RegisterEvent("MODIFIER_STATE_CHANGED")
        RecipeTooltip(self)
    end)
    row:SetScript("OnEvent", RecipeTooltip)
    row:SetScript("OnLeave", function(self)
        self:UnregisterEvent("MODIFIER_STATE_CHANGED")
        GameTooltip_Hide()
    end)
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
    list.rows[i] = row
    return row
end

-- A vendor list: column labels, scrolling rows and its source line. `name` names the scroll frame.
function addon.CreateRecipeList(parent, name)
    local list = CreateFrame("Frame", nil, parent)
    list.rows = {}
    list.sub = list:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    list.sub:SetPoint("TOPLEFT", 4, -2)
    local labels = { L["Recipe"], L["Skill"], L["Reputation"], L["Merchant's Favor"], L["Learned"] }
    for i, label in ipairs(labels) do
        local text = list:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("TOPLEFT", RCOL[i], -24)
        text:SetText(label)
        if i == 5 then list.learnedLabel = text end
    end
    local scroll = CreateFrame("ScrollFrame", name, list, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 0, -40)
    scroll:SetPoint("BOTTOMRIGHT", -16, 18)
    list.content = CreateFrame("Frame", nil, scroll)
    list.content:SetSize(LIST_W, 1)
    scroll:SetScrollChild(list.content)
    local source = list:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    source:SetPoint("BOTTOMLEFT", 4, 2)
    source:SetText(L["Source: wow-professions.com · a green check means you know the recipe"])
    return list
end

-- key: a profession skill line (its vendor recipes) or "other" (the other items sold for Merchant's Favor).
function addon.RefreshRecipeList(list, key)
    local isItem = key == "other"
    local entries = isItem and addon.vendorItems or addon.recipes[key]
    if isItem then
        list.sub:SetText(L["Camp quartermasters and recipe vendors"])
    else
        local vendor = addon.RECIPE_VENDORS[key][UnitFactionGroup("player") == "Horde" and 2 or 1]
        list.sub:SetText(vendor .. " · " .. L["%d / %d learned"]:format(addon.CountKnown(entries, Known), #entries))
    end
    list.learnedLabel:SetShown(not isItem)
    for i, entry in ipairs(entries) do
        local row = list.rows[i] or RecipeRow(list, i)
        local id, english, skill, rep, cost, craft = unpack(entry)
        row.id, row.item, row.craft = id, isItem, not isItem and craft or nil
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
    for i = #entries + 1, #list.rows do list.rows[i]:Hide() end
    list.content:SetHeight(math.max(1, #entries * ROW_H))
end

function addon.RefreshWrits()
    if not (panel and panel:IsShown()) then return end
    local vendor = filter == "vendor"
    for _, part in ipairs(writParts) do part:SetShown(not vendor) end
    vendorList:SetShown(vendor)
    for key, button in pairs(buttons) do button:SetEnabled(key ~= filter) end
    if vendor then return addon.RefreshRecipeList(vendorList, "other") end
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
    panel.count:SetText(L["%d writs"]:format(#list))
    local picked = 0
    for _ in pairs(zones) do picked = picked + 1 end
    if zoneMenu.OverrideText then
        zoneMenu:OverrideText(picked == 0 and L["All zones"] or picked == 1 and ((next(zones) == "" and L["Unknown"]) or next(zones))
            or L["%d zones"]:format(picked))
    end
end

-- The writs view; the caller anchors it and calls RefreshWrits once shown. Needs LoadWritsDB (PLAYER_LOGIN).
function addon.CreateWritsPanel(parent)
    panel = CreateFrame("Frame", nil, parent)
    local labels = { all = L["All"], bags = L["In bags"], vendor = L["Vendor items"] }
    for i, key in ipairs({ "all", "bags", "vendor" }) do
        local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        button:SetSize(110, 24)
        button:SetPoint("TOPLEFT", (i - 1) * 116, 0)
        button:SetText(labels[key])
        button:SetScript("OnClick", function()
            filter = key
            db.filter = key
            addon.RefreshWrits()
        end)
        buttons[key] = button
    end
    -- Zone selector: tick any number of zones; "All zones" clears the selection.
    zoneMenu = CreateFrame("DropdownButton", nil, panel, "WowStyle1DropdownTemplate")
    zoneMenu:SetWidth(220)
    zoneMenu:SetPoint("TOPLEFT", 3 * 116 + 10, 0)
    writParts[#writParts + 1] = zoneMenu
    zoneMenu:SetupMenu(function(_, root)
        root:CreateButton(L["All zones"], function()
            wipe(zones)
            addon.RefreshWrits()
        end)
        root:CreateDivider()
        for _, key in ipairs(addon.ZoneKeys()) do
            root:CreateCheckbox(key == "" and L["Unknown"] or key, function() return zones[key] == true end, function()
                zones[key] = not zones[key] or nil
                addon.RefreshWrits()
            end)
        end
    end)
    panel.count = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    panel.count:SetPoint("TOPRIGHT", -16, -8)
    writParts[#writParts + 1] = panel.count

    local columns = { L["Item"], L["Profession"], L["Rep"], L["Deliver to"], L["Item price"], L["Writ price"], L["Total"] }
    for i, label in ipairs(columns) do
        local text = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("TOPLEFT", COL[i], -32)
        if i >= 5 then text:SetWidth(PRICE_W); text:SetJustifyH("RIGHT") end
        text:SetText(label)
        writParts[#writParts + 1] = text
    end
    local mapLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mapLabel:SetPoint("TOPLEFT", MAP_X - 4, -32)
    mapLabel:SetText(L["Map"])
    writParts[#writParts + 1] = mapLabel

    local scroll = CreateFrame("ScrollFrame", "ProfGuideWritsScrollFrame", panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 0, -50)
    scroll:SetPoint("BOTTOMRIGHT", -16, 36)
    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(LIST_W, 1)
    scroll:SetScrollChild(content)

    summary = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    summary:SetPoint("BOTTOMLEFT", 4, 16)
    local source = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    source:SetPoint("BOTTOMLEFT", 4, 2)
    source:SetText(L["Sources: conquestcapped.com and foreverchanges.pro · prices from Auctionator"])
    for _, part in ipairs({ scroll, summary, source }) do writParts[#writParts + 1] = part end

    vendorList = addon.CreateRecipeList(panel, "ProfGuideVendorScrollFrame")
    vendorList:SetPoint("TOPLEFT", 0, -32)
    vendorList:SetPoint("BOTTOMRIGHT")
    return panel
end

-- Writ filter and zones, kept in ProfGuideDB.writs. WritBoard's own WritBoardDB stays in its old SavedVariables file.
function addon.LoadWritsDB(saved)
    if type(saved.writs) ~= "table" then saved.writs = {} end
    db = saved.writs
    if FILTERS[db.filter] then filter = db.filter end
    -- Keep only saved zones that still exist in the data.
    local valid = {}
    for _, key in ipairs(addon.ZoneKeys()) do valid[key] = true end
    if type(db.zones) == "table" then
        for key, on in pairs(db.zones) do if valid[key] and on == true then zones[key] = true end end
    end
    db.zones = zones
end
