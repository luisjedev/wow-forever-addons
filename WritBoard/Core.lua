local _, addon = ...
-- Pure logic, no frames: the window (WritBoard.lua) and the tests use it.

addon.REP = { 75, 125, 200 } -- Azeroth Commerce Authority reputation per delivery, by tier
addon.TIERS = { "Journeyman", "Expert", "Artisan" }
addon.PROFS = { [171] = "Alchemy", [164] = "Blacksmithing", [202] = "Engineering", [165] = "Leatherworking", [197] = "Tailoring" }

-- Classic uiMapIDs of the delivery zones, for the map column. Riverglades (new in Forever) has no known ID yet.
addon.ZONE_MAPS = {
    ["Alterac Mountains"] = 1416, ["Arathi Highlands"] = 1417, ["Badlands"] = 1418, ["Blasted Lands"] = 1419,
    ["Western Plaguelands"] = 1422, ["Eastern Plaguelands"] = 1423, ["Hillsbrad Foothills"] = 1424, ["The Hinterlands"] = 1425,
    ["Searing Gorge"] = 1427, ["Burning Steppes"] = 1428, ["Deadwind Pass"] = 1430, ["Duskwood"] = 1431,
    ["Stranglethorn Vale"] = 1434, ["Swamp of Sorrows"] = 1435, ["Wetlands"] = 1437, ["Ashenvale"] = 1440,
    ["Thousand Needles"] = 1441, ["Stonetalon Mountains"] = 1442, ["Desolace"] = 1443, ["Feralas"] = 1444,
    ["Dustwallow Marsh"] = 1445, ["Tanaris"] = 1446, ["Azshara"] = 1447, ["Felwood"] = 1448, ["Un'Goro Crater"] = 1449,
    ["Moonglade"] = 1450, ["Silithus"] = 1451, ["Winterspring"] = 1452,
}

local PREFIX = "Craftsman's Writ: "

-- shortcut: matches the English writ name only; other client languages need their own prefix here.
function addon.RequestedItem(name)
    if type(name) ~= "string" or name:sub(1, #PREFIX) ~= PREFIX then return nil end
    return name:sub(#PREFIX + 1)
end

-- stacks: { { id = itemID, link = itemHyperlink, count = n }, ... } -> { [requested item name] = writs held }
-- Known writs match by item ID (any client language); others by their English name.
function addon.CountWrits(stacks)
    local byID, owned = {}, {}
    for _, writ in ipairs(addon.writs) do byID[writ.writ] = writ.item end
    for _, stack in ipairs(stacks) do
        local item = byID[stack.id] or addon.RequestedItem(type(stack.link) == "string" and stack.link:match("%[(.-)%]"))
        if item then owned[item] = (owned[item] or 0) + (stack.count or 1) end
    end
    return owned
end

-- Zone key for the zone selector: the zone name, or "" when the recipient is unknown.
function addon.ZoneKey(writ) return writ.zone or "" end

-- Every zone key in the data, alphabetical, with the unknown zone ("") last.
function addon.ZoneKeys()
    local seen, keys = {}, {}
    for _, writ in ipairs(addon.writs) do
        local key = addon.ZoneKey(writ)
        if not seen[key] then seen[key] = true; keys[#keys + 1] = key end
    end
    table.sort(keys, function(a, b) if (a == "") ~= (b == "") then return b == "" end return a < b end)
    return keys
end

-- The writs to list. filter "bags" keeps the ones held, plus held writs missing from Data.lua.
-- zones: { [zone key] = true } keeps only those zones; nil or empty keeps every zone.
function addon.Rows(filter, owned, zones)
    local all = not zones or next(zones) == nil
    local rows, known = {}, {}
    for _, writ in ipairs(addon.writs) do
        known[writ.item] = true
        if (filter ~= "bags" or owned[writ.item]) and (all or zones[addon.ZoneKey(writ)]) then rows[#rows + 1] = writ end
    end
    if filter == "bags" and (all or zones[""]) then
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

-- Auction price of the writ itself; nil when unknown.
function addon.WritPrice(writ, lookup)
    local price = writ.writ and lookup(writ.writ)
    return type(price) == "number" and price > 0 and price or nil
end

-- Writ plus the items it asks for; nil unless both prices are known.
function addon.Total(writ, lookup)
    local item, paper = addon.Price(writ, lookup), addon.WritPrice(writ, lookup)
    return item and paper and item + paper
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

-- One trip to a zone, priced like gold: a zone with several writs shares it, so it wins over a lone cheap writ.
-- shortcut: fixed at 50 silver for every zone; make it a setting if players want to weigh travel differently.
addon.TRAVEL = 5000

-- A zone's value: copper per reputation point for doing all its priced writs, plus one trip. Lower is better.
function addon.ZoneScore(cost, rep)
    return rep > 0 and (cost + addon.TRAVEL) / rep or nil
end

-- Groups writs by recipient zone. Zones go from the best score (ZoneScore) to the worst, then zones without
-- prices, and the unknown zone last. Inside a zone: cheapest total first, unpriced last, then by reputation.
-- Returns headers { zone = name or false, count, cost, rep, score } followed by their writs.
function addon.Grouped(list, lookup)
    local zones, order = {}, {}
    for _, writ in ipairs(list) do
        local zone = writ.zone or false
        if not zones[zone] then
            zones[zone] = { zone = zone, count = 0, cost = 0, rep = 0, best = 0, writs = {} }
            order[#order + 1] = zones[zone]
        end
        table.insert(zones[zone].writs, writ)
    end
    local total = {}
    for _, writ in ipairs(list) do total[writ] = addon.Total(writ, lookup) or math.huge end
    local function ByPrice(a, b)
        if total[a] ~= total[b] then return total[a] < total[b] end
        if (a.tier or 0) ~= (b.tier or 0) then return (a.tier or 0) > (b.tier or 0) end
        return a.item < b.item
    end
    for _, group in ipairs(order) do
        for _, writ in ipairs(group.writs) do
            group.best = math.max(group.best, writ.tier or 0)
            if total[writ] < math.huge then
                group.count = group.count + 1
                group.cost = group.cost + total[writ]
                group.rep = group.rep + addon.REP[writ.tier]
            end
        end
        group.score = addon.ZoneScore(group.cost, group.rep)
        table.sort(group.writs, ByPrice)
    end
    table.sort(order, function(a, b)
        if (a.zone == false) ~= (b.zone == false) then return b.zone == false end
        if (a.score ~= nil) ~= (b.score ~= nil) then return a.score ~= nil end
        if a.score and a.score ~= b.score then return a.score < b.score end
        if a.best ~= b.best then return a.best > b.best end
        return tostring(a.zone) < tostring(b.zone)
    end)
    local entries = {}
    for _, group in ipairs(order) do
        entries[#entries + 1] = group
        for _, writ in ipairs(group.writs) do entries[#entries + 1] = writ end
        group.writs = nil
    end
    return entries
end
