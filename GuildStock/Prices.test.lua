-- Synthetic auction results only; no game, network or personal saved files.
local source = assert(loadfile("GuildStock/Prices.lua"))
local secret = setmetatable({}, {__tostring = function() error("secret used") end})
local function Client(saved)
    local clock, epoch, combat = 100, 1800000000, false
    local timers, frames, refreshes, replicated = {}, {}, 0, 0
    local full, results = true, {}
    local env = setmetatable({GuildStockDB = saved}, {__index = _G})
    env.GetLocale = function() return "enUS" end
    env.GetTime = function() return clock end
    env.time = function() return epoch end
    env.canaccessvalue = function(value) return value ~= secret end
    env.InCombatLockdown = function() return combat end
    env.CreateFrame = function()
        local f = {events = {}}
        function f:RegisterEvent(event) self.events[event] = true end
        function f:SetScript(_, callback) self.callback = callback end
        frames[#frames + 1] = f
        return f
    end
    env.C_Timer = {After = function(_, callback) timers[#timers + 1] = callback end}
    env.C_AuctionHouse = {
        ReplicateItems = function() replicated = replicated + 1 end,
        HasFullCommoditySearchResults = function() return full end,
        GetNumCommoditySearchResults = function() return #results end,
        GetCommoditySearchResultInfo = function(_, index) return results[index] end,
        HasFullItemSearchResults = function() return full end,
        GetNumItemSearchResults = function() return #results end,
        GetItemSearchResultInfo = function(_, index) return results[index] end,
    }
    local addon = {}
    for _, file in ipairs({"Locales", "GuildStock"}) do
        setfenv(assert(loadfile("GuildStock/" .. file .. ".lua")), env)("GuildStock", addon)
    end
    addon.ResetInventory = function() end
    addon.Catalog = function() return {[10] = {}, [20] = {}, [30] = {}} end
    addon.ScheduleRefresh = function() refreshes = refreshes + 1 end
    addon.SyncChanged = function() error("prices must never trigger guild synchronization") end
    setfenv(source, env)("GuildStock", addon)
    addon.Initialize()
    local c = {addon = addon, env = env}
    function c.event(event, ...)
        for _, f in ipairs(frames) do
            if f.events[event] and f ~= frames[1] then f.callback(f, event, ...) end
        end
    end
    function c.advance(seconds) clock, epoch = clock + seconds, epoch + seconds end
    function c.results(value, complete) results, full = value, complete end
    function c.combat(value) combat = value end
    function c.replicated() return replicated end
    function c.pending() return #timers end
    -- A completed commodity search for one item, as the native auction UI reports it.
    function c.observe(id, value)
        c.results(value, true)
        c.event("COMMODITY_SEARCH_RESULTS_UPDATED", id)
    end
    return c
end

local c = Client(nil)
local a = c.addon
assert(a.db == c.env.GuildStockDB and not a.AuctionPrice(10))
c.observe(10, {{quantity = 2, unitPrice = 250}})
assert(not a.AuctionPrice(10), "cached native results outside a visit are not fresh observations")
c.event("AUCTION_HOUSE_SHOW")
assert(c.replicated() == 0 and c.pending() == 0, "opening the auction house never requests a full replication")
c.observe(10, {{quantity = 2, unitPrice = 250}, {quantity = 5, unitPrice = 150}})
c.observe(20, {{quantity = 3, unitPrice = 33}})
c.observe(999, {{quantity = 1, unitPrice = 1}})
assert(a.AuctionPrice(10).copper == 150 and a.AuctionPrice(20).copper == 33 and not a.AuctionPrice(999))
assert(a.db.auctionPrices.version == 1)
local initial = a.AuctionPrice(10)
for key in pairs(initial) do assert(key == "copper" or key == "observedAt", "save no auction identity data") end
c.advance(30)
c.observe(10, {{quantity = 1, unitPrice = 500}})
assert(a.AuctionPrice(10).copper == 500 and a.AuctionPrice(10).observedAt == initial.observedAt + 30,
    "a new observation can increase the minimum; it is not an all-time low")
assert(a.AuctionPrice(20).observedAt == initial.observedAt)
local previous = a.AuctionPrice(10)
for _, bad in ipairs({-1, 0 / 0, math.huge, "300", secret, 9007199254740992}) do
    c.observe(10, {{quantity = 1, unitPrice = bad}, {quantity = 1, unitPrice = 600}})
    assert(a.AuctionPrice(10) == previous, "unreadable prices cannot freshen a partial minimum")
end
for _, bad in ipairs({0, -1, 0.5, secret}) do
    c.observe(10, {{quantity = bad, unitPrice = 300}, {quantity = 1, unitPrice = 600}})
    assert(a.AuctionPrice(10) == previous)
end
c.observe(10, {})
assert(a.AuctionPrice(10) == previous, "empty results preserve historical observations")
c.combat(true); c.observe(10, {{quantity = 1, unitPrice = 1}})
assert(a.AuctionPrice(10) == previous, "combat blocks reading results")
c.combat(false)

-- Completed user searches update only their item; no searches are issued by the addon.
c.advance(10)
c.results({{quantity = 2, unitPrice = 45}, {quantity = 3, unitPrice = 30}}, false)
c.event("COMMODITY_SEARCH_RESULTS_UPDATED", 10)
assert(a.AuctionPrice(10) == previous, "incomplete results are ignored")
c.results({{quantity = 2, unitPrice = 45}, {quantity = 3, unitPrice = 30}}, true)
c.event("COMMODITY_SEARCH_RESULTS_ADDED", 10)
assert(a.AuctionPrice(10).copper == 30)
previous = a.AuctionPrice(10)
local key = {itemID = 10, itemSuffix = 0, itemLevel = 0, battlePetSpeciesID = 0}
c.results({{quantity = 3, buyoutAmount = 600}, {quantity = 1}, {quantity = 2, buyoutAmount = 350}}, true)
c.event("ITEM_SEARCH_RESULTS_UPDATED", key)
assert(a.AuctionPrice(10).copper == 175, "item prices divide stack buyout; bids are not buyouts")
previous = a.AuctionPrice(10)
c.results({{quantity = 1, buyoutAmount = secret}}, true)
c.event("ITEM_SEARCH_RESULTS_UPDATED", key)
assert(a.AuctionPrice(10) == previous)
key.itemSuffix = 123
c.results({{quantity = 1, buyoutAmount = 1}}, true)
c.event("ITEM_SEARCH_RESULTS_UPDATED", key)
assert(a.AuctionPrice(10) == previous, "suffix variants are not substituted for a base material")
c.event("ITEM_SEARCH_RESULTS_UPDATED", secret)
c.event("COMMODITY_SEARCH_RESULTS_UPDATED", secret)
c.event("AUCTION_HOUSE_CLOSED")
c.event("COMMODITY_SEARCH_RESULTS_UPDATED", 10)
assert(a.AuctionPrice(10) == previous)
assert(c.replicated() == 0)

-- Reloaded saved prices keep the exact observation timestamp and never enter inventory exports.
local saved = a.db
saved.own = {observedAt = 1800000000, items = {[10] = {count = 2, bound = 0}}}
saved.auctionPrices.items[10] = {copper = 800, observedAt = 1799900000}
local reload = Client(saved)
assert(reload.addon.AuctionPrice(10) == saved.auctionPrices.items[10])
local exported = reload.addon.ShareableSnapshot()
assert(exported.auctionPrices == nil and exported.items[10].copper == nil and exported.items[10].count == 2)
for _, invalid in ipairs({{}, {copper = 0, observedAt = 1800000000}, {copper = 1, observedAt = 1800000001},
    {copper = secret, observedAt = 1800000000}, {copper = 1, observedAt = secret}}) do
    saved.auctionPrices.items[20] = invalid
    assert(not reload.addon.AuctionPrice(20))
end
for _, unsupported in ipairs({"preserve", {version = 2, items = {[10] = {copper = 1, observedAt = 1800000000}}},
    {version = 1, items = false}}) do
    local db = {version = 1, auctionPrices = unsupported, favorites = {[10] = true}}
    local client = Client(db)
    client.event("AUCTION_HOUSE_SHOW"); client.observe(10, {{quantity = 1, unitPrice = 900}})
    assert(db.auctionPrices == unsupported and db.favorites[10])
    assert(client.addon.AuctionPrice(10).copper == 900, "unsupported price schemas use temporary storage")
end
for _, db in ipairs({{version = 99, marker = true}, "unsupported"}) do
    local client = Client(db)
    client.event("AUCTION_HOUSE_SHOW"); client.observe(10, {{quantity = 1, unitPrice = 900}})
    assert(client.env.GuildStockDB == db and client.addon.temporary)
    assert(type(db) ~= "table" or db.auctionPrices == nil)
end
local unavailable = Client(nil)
unavailable.env.C_AuctionHouse = nil
unavailable.event("AUCTION_HOUSE_SHOW"); unavailable.event("COMMODITY_SEARCH_RESULTS_UPDATED", 10)
assert(not unavailable.addon.AuctionPrice(10) and unavailable.pending() == 0)

local ages = Client(nil).addon
for _, case in ipairs({{0, "0 seconds", "recent"}, {1, "1 second", "recent"}, {59, "59 seconds", "recent"},
    {60, "1 minute", "recent"}, {120, "2 minutes", "recent"}, {3599, "59 minutes", "recent"},
    {3600, "1 hour", "recent"}, {43200, "12 hours", "recent"}, {43201, "12 hours", "stale"},
    {86400, "24 hours", "stale"}, {86401, "24 hours", "old"}}) do
    local text, state = ages.AuctionPriceAge(1800000000 - case[1])
    assert(text == "Updated " .. case[2] .. " ago" and state == case[3])
end
ages.ApplyLanguage("esES")
assert(ages.AuctionPriceAge(1799999999) == "Actualizado hace 1 segundo")
print("GuildStock: auction search observations, restrictions, persistence and age checks OK")
