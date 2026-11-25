-- Run from the repository root: luajit WritBoard/WritBoard.test.lua
GetLocale = function() return "enUS" end
local addon = {}
for _, file in ipairs({ "Locales", "Data", "Core" }) do assert(loadfile("WritBoard/" .. file .. ".lua"))("WritBoard", addon) end

-- Data: 150 orders, 45/60/45 by tier, each with item IDs and a known profession; pins only with a zone.
local tiers, names = { 0, 0, 0 }, {}
for _, w in ipairs(addon.writs) do
    tiers[w.tier] = tiers[w.tier] + 1
    assert(addon.PROFS[w.prof] and #w.ids >= 1 and type(w.skill) == "number", w.item)
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
    {},
})
assert(owned["Rough Bronze Leggings"] == 3 and owned["Some New Order"] == 1)

-- Filters: all lists every writ; bags lists held ones, including writs missing from the data.
assert(#addon.Rows("all", owned) == 150)
local bags = addon.Rows("bags", owned)
assert(#bags == 2 and bags[1].item == "Rough Bronze Leggings" and bags[2].item == "Some New Order")

-- Price: cheapest of the item IDs times the quantity asked; nil without a price.
local prices = { [2865] = 900, [3853] = 5000, [217281] = 4000 }
local lookup = function(id) return prices[id] end
local function writ(item) for _, w in ipairs(addon.writs) do if w.item == item then return w end end end
assert(addon.Price(writ("Rough Bronze Leggings"), lookup) == 900)
assert(addon.Price(writ("Moonsteel Broadsword"), lookup) == 4000)
assert(addon.Price(writ("Elixir of Wisdom"), lookup) == nil)
prices[writ("Crafted Solid Shot").ids[1]] = 3
assert(addon.Price(writ("Crafted Solid Shot"), lookup) == 600)

-- Summary of held writs: 3 Journeyman = 225 rep, 2700 copper; the unknown writ has no price.
local count, rep, cost, unpriced = addon.Summary(owned, lookup)
assert(count == 4 and rep == 225 and cost == 2700 and unpriced == 1, table.concat({ count, rep, cost, unpriced }, ","))
print("WritBoard ok")
