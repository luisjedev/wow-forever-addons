-- Run from the repository root: luajit WritBoard/WritBoard.test.lua
GetLocale = function() return "enUS" end
local addon = {}
for _, file in ipairs({ "Locales", "Data", "Core" }) do assert(loadfile("WritBoard/" .. file .. ".lua"))("WritBoard", addon) end

-- Data: 150 orders, 45/60/45 by tier, each with item IDs and a known profession; pins only with a zone.
local tiers, names = { 0, 0, 0 }, {}
for _, w in ipairs(addon.writs) do
    tiers[w.tier] = tiers[w.tier] + 1
    assert(addon.PROFS[w.prof] and #w.ids >= 1 and type(w.skill) == "number" and type(w.writ) == "number", w.item)
    assert(not names[w.writ], "duplicate writ ID " .. w.item)
    names[w.writ] = true
    assert(not names[w.item], "duplicate " .. w.item)
    names[w.item] = true
    assert(not w.pin or (w.zone and #w.pin == 3), w.item)
end
assert(#addon.writs == 150 and tiers[1] == 45 and tiers[2] == 60 and tiers[3] == 45, "writ counts")

-- Writ names in bag links map to the requested item; other items are ignored.
assert(addon.RequestedItem("Craftsman's Writ: Rough Bronze Leggings") == "Rough Bronze Leggings")
assert(addon.RequestedItem("Rough Bronze Leggings") == nil and addon.RequestedItem(nil) == nil)
local owned = addon.CountWrits({
    { link = "|cff1eff00|Hitem:1::::|h[Craftsman's Writ: Rough Bronze Leggings]|h|r", count = 1 },
    { link = "|Hitem:2|h[Craftsman's Writ: Rough Bronze Leggings]|h", count = 2 },
    { link = "|Hitem:3|h[Craftsman's Writ: Some New Order]|h" },
    { link = "|Hitem:2865|h[Rough Bronze Leggings]|h", count = 5 },
    { id = 264011, link = "|Hitem:264011|h[Craftsman's Writ: Elixir of Ogre's Strength]|h" },
    {},
})
assert(owned["Rough Bronze Leggings"] == 3 and owned["Some New Order"] == 1)
-- The in-game writ name differs from the data's item name here; the item ID still matches it.
assert(owned["Elixir of Ogre Strength"] == 1 and not owned["Elixir of Ogre's Strength"])

-- Filters: all lists every writ; bags lists held ones, including writs missing from the data.
assert(#addon.Rows("all", owned) == 150)
local bags = addon.Rows("bags", owned)
assert(#bags == 3 and bags[3].item == "Some New Order")

-- Price: cheapest of the item IDs times the quantity asked; nil without a price.
local prices = { [2865] = 900, [3853] = 5000, [217281] = 4000 }
local lookup = function(id) return prices[id] end
local function writ(item) for _, w in ipairs(addon.writs) do if w.item == item then return w end end end
assert(addon.Price(writ("Rough Bronze Leggings"), lookup) == 900)
assert(addon.Price(writ("Moonsteel Broadsword"), lookup) == 4000)
assert(addon.Price(writ("Elixir of Wisdom"), lookup) == nil)
prices[writ("Crafted Solid Shot").ids[1]] = 3
assert(addon.Price(writ("Crafted Solid Shot"), lookup) == 600)

-- Writ price and total: nil until both the writ and the item have a price.
local leggings = writ("Rough Bronze Leggings")
assert(addon.WritPrice(leggings, lookup) == nil and addon.Total(leggings, lookup) == nil)
prices[leggings.writ] = 100
assert(addon.WritPrice(leggings, lookup) == 100 and addon.Total(leggings, lookup) == 1000)

-- Summary of held writs: 4 Journeyman = 300 rep, 2700 copper for the leggings; two writs have no item price.
local count, rep, cost, unpriced = addon.Summary(owned, lookup)
assert(count == 5 and rep == 300 and cost == 2700 and unpriced == 2, table.concat({ count, rep, cost, unpriced }, ","))
print("WritBoard ok")

-- Grouping without prices: zone headers, highest-reputation zones first, unknown zone last, writs by reputation inside.
local grouped = addon.Grouped(addon.Rows("all", {}), function() return nil end)
assert(#grouped > 150 and grouped[1].ids == nil and grouped[#grouped].ids ~= nil)
local zone, last, seenUnknown, headers = nil, nil, false, 0
for _, e in ipairs(grouped) do
    if e.ids == nil then
        headers = headers + 1
        assert(not seenUnknown, "unknown zone is last")
        seenUnknown = e.zone == false
        zone, last = e.zone, 9
    else
        assert((e.zone or false) == zone and e.tier <= last, e.item)
        last = e.tier
    end
end
assert(seenUnknown and grouped[1].zone and grouped[2].tier == 3, "artisan zones first")
print("WritBoard grouping ok")

-- Inside a zone, the cheapest total goes first and writs without a total go last.
local stonetalon = {}
for _, w in ipairs(addon.writs) do if w.zone == "Stonetalon Mountains" then stonetalon[#stonetalon + 1] = w end end
local totals = { [writ("Heavy Quiver").writ] = 50, [writ("Heavy Quiver").ids[1]] = 50, [writ("Red Woolen Boots").writ] = 10, [writ("Red Woolen Boots").ids[1]] = 20 }
local sorted = addon.Grouped(stonetalon, function(id) return totals[id] end)
assert(sorted[1].zone == "Stonetalon Mountains" and sorted[2].item == "Red Woolen Boots" and sorted[3].item == "Heavy Quiver", "price order")
print("WritBoard price order ok")
