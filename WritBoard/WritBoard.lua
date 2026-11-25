local _, addon = ...
local L = addon.L

local WIDTH, HEIGHT, ROW_H, LIST_W = 860, 560, 24, 790
-- Column x offsets inside a row: item, profession, reputation, recipient, price.
local COL = { 28, 280, 390, 450, 690 }
local db, window, content, summary
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
                stacks[#stacks + 1] = { link = info.hyperlink, count = info.stackCount }
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

-- Marks the recipient on the world map and opens it; same helper as ProfGuide.
local function ShowOnMap(pin)
    if type(pin) ~= "table" or not (C_Map and C_Map.SetUserWaypoint and UiMapPoint) then return end
    pcall(function()
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(pin[1], pin[2] / 100, pin[3] / 100))
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
        if OpenWorldMap then OpenWorldMap(pin[1]) else ToggleWorldMap() end
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
    row.to = Text(row, "GameFontHighlightSmall", COL[4], COL[5] - COL[4] - 30)
    row.price = Text(row, "GameFontHighlightSmall", COL[5], LIST_W - COL[5] - 4)
    row.price:SetJustifyH("RIGHT")
    row.map = CreateFrame("Button", nil, row)
    row.map:SetSize(18, 18)
    row.map:SetPoint("LEFT", COL[5] - 26, 0)
    row.map:SetNormalTexture("Interface\\Icons\\INV_Misc_Map_01")
    row.map:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    row.map:SetScript("OnClick", function(self) ShowOnMap(self:GetParent().writ.pin) end)
    row.map:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(L["Show on map"])
    end)
    row.map:SetScript("OnLeave", GameTooltip_Hide)
    row:SetScript("OnEnter", RowTooltip)
    row:SetScript("OnLeave", GameTooltip_Hide)
    rows[i] = row
    return row
end

local function Refresh()
    if not (window and window:IsShown()) then return end
    local owned = ScanBags()
    local list = addon.Rows(filter, owned)
    local entries = addon.Grouped(list)
    for i, writ in ipairs(entries) do
        local row = rows[i] or Row(i)
        local header = writ.ids == nil
        row.writ = not header and writ or nil
        for _, part in ipairs({ row.icon, row.prof, row.rep, row.to, row.price }) do part:SetShown(not header) end
        row.stripe:SetColorTexture(0.45, 0.34, 0.16, header and 0.35 or (i % 2 == 0 and 0.04 or 0))
        row.item:SetPoint("LEFT", header and 6 or COL[1], 0)
        if header then
            row.item:SetText(writ.zone or L["Unknown"])
            row.item:SetTextColor(1, 0.82, 0)
            row.map:Hide()
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
            row.map:SetShown(writ.pin ~= nil)
        end
        row:Show()
    end
    for i = #entries + 1, #rows do rows[i]:Hide() end
    content:SetHeight(math.max(1, #entries * ROW_H))
    local count, rep, cost, unpriced = addon.Summary(owned, Price)
    summary:SetText(L["Writs in bags: %d · %d reputation · cost %s"]:format(count, rep, Money(cost))
        .. (unpriced > 0 and ("  |cff999999(" .. unpriced .. " ?)|r") or ""))
    for key, button in pairs(buttons) do button:SetEnabled(key ~= filter) end
    window.count:SetText(L["%d writs"]:format(#list))
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

    for i, key in ipairs({ "all", "bags" }) do
        local button = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
        button:SetSize(110, 24)
        button:SetPoint("TOPLEFT", 24 + (i - 1) * 116, -32)
        button:SetText(key == "all" and L["All"] or L["In bags"])
        button:SetScript("OnClick", function()
            filter = key
            db.filter = key
            Refresh()
        end)
        buttons[key] = button
    end
    window.count = window:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    window.count:SetPoint("TOPRIGHT", -40, -40)

    local labels = { L["Item"], L["Profession"], L["Rep"], L["Deliver to"], L["Auction"] }
    for i, label in ipairs(labels) do
        local text = window:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("TOPLEFT", 24 + COL[i], -66)
        text:SetText(label)
    end

    local scroll = CreateFrame("ScrollFrame", "WritBoardScrollFrame", window, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 24, -84)
    scroll:SetPoint("BOTTOMRIGHT", -40, 52)
    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(LIST_W, 1)
    scroll:SetScrollChild(content)

    summary = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    summary:SetPoint("BOTTOMLEFT", 28, 30)
    local source = window:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    source:SetPoint("BOTTOMLEFT", 28, 16)
    source:SetText(L["Sources: conquestcapped.com and foreverchanges.pro · prices from Auctionator"])

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
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        if type(WritBoardDB) ~= "table" then WritBoardDB = {} end
        db = WritBoardDB
        if db.filter == "all" or db.filter == "bags" then filter = db.filter end
        return
    end
    Refresh()
end)

SLASH_WRITBOARD1 = "/writboard"
SLASH_WRITBOARD2 = "/writs"
SlashCmdList["WRITBOARD"] = WritBoard_Toggle
