local _, addon = ...
-- Pure logic, no frames: the window (WritBoard.lua) and the tests use it.

addon.REP = { 75, 125, 200 } -- Azeroth Commerce Authority reputation per delivery, by tier
addon.TIERS = { "Journeyman", "Expert", "Artisan" }
addon.PROFS = { [171] = "Alchemy", [164] = "Blacksmithing", [202] = "Engineering", [165] = "Leatherworking", [197] = "Tailoring" }

local PREFIX = "Craftsman's Writ: "

-- shortcut: matches the English writ name only; other client languages need their own prefix here.
function addon.RequestedItem(name)
    if type(name) ~= "string" or name:sub(1, #PREFIX) ~= PREFIX then return nil end
    return name:sub(#PREFIX + 1)
end

-- stacks: { { link = itemHyperlink, count = n }, ... } -> { [requested item name] = writs held }
function addon.CountWrits(stacks)
    local owned = {}
    for _, stack in ipairs(stacks) do
        local item = addon.RequestedItem(type(stack.link) == "string" and stack.link:match("%[(.-)%]"))
        if item then owned[item] = (owned[item] or 0) + (stack.count or 1) end
    end
    return owned
end

-- The writs to list. filter "bags" keeps the ones held, plus held writs missing from Data.lua.
function addon.Rows(filter, owned)
    local rows, known = {}, {}
    for _, writ in ipairs(addon.writs) do
        known[writ.item] = true
        if filter ~= "bags" or owned[writ.item] then rows[#rows + 1] = writ end
    end
    if filter == "bags" then
        for item in pairs(owned) do
            if not known[item] then rows[#rows + 1] = { item = item, ids = {} } end
        end
    end
    return rows
end

-- Cheapest known unit price among the writ's item IDs, times the quantity asked; nil when none is known.
function addon.Price(writ, lookup)
    local best
    for _, id in ipairs(writ.ids) do
        local price = lookup(id)
        if type(price) == "number" and price > 0 and (not best or price < best) then best = price end
    end
    return best and best * (writ.qty or 1)
end

-- Totals for the held writs: count, reputation, cost of the known prices, and how many lack a price.
function addon.Summary(owned, lookup)
    local count, rep, cost, unpriced = 0, 0, 0, 0
    for _, writ in ipairs(addon.Rows("bags", owned)) do
        local held = owned[writ.item]
        count = count + held
        rep = rep + (writ.tier and addon.REP[writ.tier] or 0) * held
        local price = addon.Price(writ, lookup)
        if price then cost = cost + price * held else unpriced = unpriced + held end
    end
    return count, rep, cost, unpriced
end

-- Groups writs by recipient zone: zones with the highest reputation first (then by name, unknown zone last),
-- writs inside a zone from most to least reputation. Returns entries: { zone = name } headers and writs.
function addon.Grouped(list)
    local zones, order = {}, {}
    for _, writ in ipairs(list) do
        local zone = writ.zone or false
        if not zones[zone] then zones[zone] = {}; order[#order + 1] = zone end
        table.insert(zones[zone], writ)
    end
    local function Best(zone) return zones[zone][1].tier or 0 end
    local function ByRep(a, b)
        if (a.tier or 0) ~= (b.tier or 0) then return (a.tier or 0) > (b.tier or 0) end
        return a.item < b.item
    end
    for _, zone in ipairs(order) do table.sort(zones[zone], ByRep) end
    table.sort(order, function(a, b)
        if not a or not b then return b == false and a ~= false end
        if Best(a) ~= Best(b) then return Best(a) > Best(b) end
        return a < b
    end)
    local entries = {}
    for _, zone in ipairs(order) do
        entries[#entries + 1] = { zone = zone }
        for _, writ in ipairs(zones[zone]) do entries[#entries + 1] = writ end
    end
    return entries
end
