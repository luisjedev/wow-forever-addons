local _, addon = ...
local L = addon.L
local MAX_MONEY = 9007199254740991 -- Only exactly representable, accessible copper amounts.
local temporary = {version = 1, items = {}}
local auctionOpen, requested, lastRequest, generation = false, false, nil, 0
local observation, latest = 0, {}

local function Table(value) return addon.Accessible(value) and type(value) == "table" end

local function Prices()
    if not addon.db then return temporary.items end
    if addon.db.auctionPrices == nil then addon.db.auctionPrices = {version = 1, items = {}} end
    local saved = addon.db.auctionPrices
    if not Table(saved) or saved.version ~= 1 or not Table(saved.items) then return temporary.items end
    return saved.items
end

function addon.AuctionPrice(itemID)
    if not addon.Integer(itemID, 1, 2147483647) then return end
    local entry = Prices()[itemID]
    if Table(entry) and addon.Integer(entry.copper, 1, MAX_MONEY)
        and addon.Integer(entry.observedAt, 0, time()) then return entry end
end

function addon.AuctionPriceAge(observedAt)
    local age = math.max(0, time() - observedAt)
    local count, key
    if age >= 3600 then
        count = math.floor(age / 3600)
        key = count == 1 and "Updated %s hour ago" or "Updated %s hours ago"
    elseif age >= 60 then
        count = math.floor(age / 60)
        key = count == 1 and "Updated %s minute ago" or "Updated %s minutes ago"
    else
        count = math.floor(age)
        key = count == 1 and "Updated %s second ago" or "Updated %s seconds ago"
    end
    return string.format(L[key], count), age > 86400 and "old" or age > 43200 and "stale" or "recent"
end

local function CanRead()
    return auctionOpen and addon.db and addon.Read(InCombatLockdown) == false
end

local function Save(prices, observedAt, order)
    local saved = Prices()
    for id, copper in pairs(prices) do
        local previous = addon.AuctionPrice(id)
        if (not previous or previous.observedAt <= observedAt) and (latest[id] or 0) <= order then
            saved[id] = {copper = copper, observedAt = observedAt}
            latest[id] = order
        end
    end
    addon.ScheduleRefresh()
end

local function Request()
    if not CanRead() or requested or not C_AuctionHouse or type(C_AuctionHouse.ReplicateItems) ~= "function"
        or (lastRequest and GetTime() - lastRequest < 900) then return end
    if C_AuctionHouse.IsThrottledMessageSystemReady
        and addon.Read(C_AuctionHouse.IsThrottledMessageSystemReady) ~= true then return end
    requested, lastRequest = true, GetTime()
    -- One request per visit, at most every 15 minutes; never retry a native denial.
    pcall(C_AuctionHouse.ReplicateItems)
end

local function ReplicatedPrices()
    if not CanRead() or not requested or not C_AuctionHouse then return end
    local total = addon.Read(C_AuctionHouse.GetNumReplicateItems)
    if not addon.Integer(total, 1, 1000000) or type(C_AuctionHouse.GetReplicateItemInfo) ~= "function" then return end
    generation, observation = generation + 1, observation + 1
    local token, index, observedAt = generation, 0, time()
    local order = observation
    local prices, blocked, catalog = {}, {}, addon.Catalog()
    local function Batch()
        if token ~= generation or not CanRead() then return end
        for i = index, math.min(index + 199, total - 1) do
            -- Do not retain names, owners, links or any other auction identity data.
            local ok, _, _, count, _, _, _, _, _, _, buyout, _, _, _, _, _, saleStatus, id, complete =
                pcall(C_AuctionHouse.GetReplicateItemInfo, i)
            if not ok or not addon.Integer(id, 1, 2147483647) then return end
            if catalog[id] then
                if not addon.Accessible(complete) or complete ~= true
                    or not addon.Integer(count, 1, 2147483647)
                    or not addon.Integer(buyout, 0, MAX_MONEY)
                    or not addon.Integer(saleStatus, 0, 1) then
                    blocked[id] = true
                elseif saleStatus == 0 and buyout > 0 then
                    local unit = math.max(1, math.floor(buyout / count + 0.5))
                    prices[id] = math.min(prices[id] or unit, unit)
                end
            end
        end
        index = index + 200
        if index < total then C_Timer.After(0, Batch); return end
        if addon.Read(C_AuctionHouse.GetNumReplicateItems) ~= total then return end
        for id in pairs(blocked) do prices[id] = nil end
        -- Missing, bid-only and unreadable items keep their earlier price AND date.
        Save(prices, observedAt, order)
    end
    Batch()
end

local function SearchPrices(key, commodity)
    if not CanRead() or not C_AuctionHouse then return end
    local id
    if commodity then id = key elseif Table(key) then id = key.itemID end
    if not addon.Integer(id, 1, 2147483647) or not addon.Catalog()[id] then return end
    if not commodity and (not addon.Integer(key.itemSuffix, 0, 0)
        or not addon.Integer(key.battlePetSpeciesID, 0, 0)) then return end
    local api = C_AuctionHouse
    local complete, size, read
    if commodity then
        complete, size, read = api.HasFullCommoditySearchResults, api.GetNumCommoditySearchResults, api.GetCommoditySearchResultInfo
    else
        complete, size, read = api.HasFullItemSearchResults, api.GetNumItemSearchResults, api.GetItemSearchResultInfo
    end
    if addon.Read(complete, key) ~= true then return end
    local count = addon.Read(size, key)
    if not addon.Integer(count, 1, 10000) then return end
    local minimum
    for i = 1, count do
        local entry = addon.Read(read, key, i)
        if not Table(entry) or not addon.Integer(entry.quantity, 1, 2147483647) then return end
        local price
        if commodity then price = entry.unitPrice else price = entry.buyoutAmount end
        if not addon.Accessible(price) then return end
        if price ~= nil then
            if not addon.Integer(price, 0, MAX_MONEY) then return end
            if price > 0 then
                local unit = commodity and price or math.max(1, math.floor(price / entry.quantity + 0.5))
                minimum = math.min(minimum or unit, unit)
            end
        elseif commodity then return end
    end
    if minimum then
        observation = observation + 1
        Save({[id] = minimum}, time(), observation)
    end
end

local events = CreateFrame("Frame")
for _, event in ipairs({"AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED", "REPLICATE_ITEM_LIST_UPDATE",
    "AUCTION_HOUSE_THROTTLED_SYSTEM_READY", "COMMODITY_SEARCH_RESULTS_UPDATED", "COMMODITY_SEARCH_RESULTS_ADDED",
    "ITEM_SEARCH_RESULTS_UPDATED", "ITEM_SEARCH_RESULTS_ADDED", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED",
    "PLAYER_ENTERING_WORLD"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent", function(_, event, key)
    if event == "AUCTION_HOUSE_SHOW" then
        auctionOpen, requested = true, false
        Request()
    elseif event == "AUCTION_HOUSE_CLOSED" or event == "PLAYER_ENTERING_WORLD" then
        auctionOpen, requested, generation = false, false, generation + 1
    elseif event == "PLAYER_REGEN_DISABLED" then
        generation = generation + 1
    elseif event == "REPLICATE_ITEM_LIST_UPDATE" then
        ReplicatedPrices()
    elseif event == "COMMODITY_SEARCH_RESULTS_UPDATED" or event == "COMMODITY_SEARCH_RESULTS_ADDED" then
        SearchPrices(key, true)
    elseif event == "ITEM_SEARCH_RESULTS_UPDATED" or event == "ITEM_SEARCH_RESULTS_ADDED" then
        SearchPrices(key, false)
    else
        Request()
    end
end)

local ageColors = {recent = {0.70, 0.68, 0.62}, stale = {1, 0.55, 0.15}, old = {1, 0.22, 0.18}}
local function HideTip(self)
    self.hovered = false
    if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
end

local function UpdateIndicator(frame)
    local entry = addon.AuctionPrice(frame.itemID)
    local copper = entry and entry.copper
    if frame.copper ~= copper then
        frame.copper = copper
        frame.text:SetText(copper and ("~ " .. GetMoneyString(copper)) or "—")
        local width = math.min(frame.text:GetStringWidth(), frame:GetWidth() - 22)
        frame.text:SetWidth(width)
        frame.clock:ClearAllPoints()
        frame.clock:SetPoint("LEFT", frame, "LEFT", width + 4, 0)
    end
    local age, state
    if entry then age, state = addon.AuctionPriceAge(entry.observedAt) end
    frame.clock.icon:SetVertexColor(unpack(ageColors[state or "recent"]))
    if frame.clock.hovered and GameTooltip:IsOwned(frame.clock) then
        local text = (age or L["No auction price recorded."]) .. "\n" .. L["Estimated unit price"]
        if not entry or state ~= "recent" then text = text .. "\n" .. L["Visit the auction house to update this information."] end
        GameTooltip:SetText(text, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end
end

function addon.CreatePriceIndicator(parent, x, y, width, size)
    local frame = CreateFrame("Frame", nil, parent)
    frame.copper = false -- Native GetText returns nil for an empty FontString.
    frame:SetPoint("TOPLEFT", x, -y)
    frame:SetSize(width, 18)
    frame.text = frame:CreateFontString(nil, "OVERLAY")
    frame.text:SetFontObject("ChatFontNormal")
    frame.text:SetFontHeight(size or 12)
    frame.text:SetShadowOffset(0, 0)
    frame.text:SetPoint("LEFT")
    frame.text:SetJustifyH("LEFT")
    frame.text:SetWordWrap(false)
    frame.text:SetTextColor(0.70, 0.64, 0.54)
    frame.text:SetText("")
    frame.clock = CreateFrame("Frame", nil, frame)
    frame.clock:SetSize(18, 18)
    frame.clock:EnableMouse(true)
    frame.clock:SetMouseClickEnabled(false)
    frame.clock.icon = frame.clock:CreateTexture(nil, "ARTWORK")
    frame.clock.icon:SetPoint("CENTER")
    frame.clock.icon:SetSize(14, 14)
    frame.clock.icon:SetAtlas("auctionhouse-icon-clock")
    frame.clock.icon:SetDesaturated(true)
    frame.clock:SetScript("OnEnter", function(self)
        self.hovered = true
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        UpdateIndicator(frame)
    end)
    frame.clock:SetScript("OnLeave", HideTip)
    frame.clock:SetScript("OnHide", HideTip)
    local elapsed = 0
    frame:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed >= 1 then elapsed = 0; UpdateIndicator(frame) end
    end)
    frame:SetScript("OnShow", UpdateIndicator)
    frame:SetScript("OnHide", function() HideTip(frame.clock) end)
    return frame
end

function addon.SetPriceItem(frame, itemID)
    if frame.itemID ~= itemID then HideTip(frame.clock) end
    frame.itemID = itemID
    frame:SetShown(itemID ~= nil)
    if itemID then UpdateIndicator(frame) end
end
