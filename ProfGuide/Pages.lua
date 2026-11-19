local _, addon = ...
local L = addon.L

-- Loaded before Data/*.lua: each data file registers addon.guides[key] using addon.Step.
addon.guides = {}
-- source: where to get the step's recipe, { "Recipe name", "where line", ..., pins = { Horde = pin, Alliance = pin } }.
function addon.Step(from, to, count, item, mats, note, alts, source)
    return { from = from, to = to, count = count, item = item, mats = mats or {}, note = note, alts = alts, source = source }
end
-- How a rank (Apprentice, Journeyman, ...) is learned. horde/alliance: map pins { uiMapID, x, y }; alliance defaults to horde.
function addon.Rank(name, method, where, horde, alliance)
    return { name, method, where, pins = horde and { Horde = horde, Alliance = alliance or horde } }
end
-- Order of the tiles in the overview.
addon.guideOrder = { "alchemy", "blacksmithing", "enchanting", "engineering", "leatherworking", "tailoring",
    "mining", "herbalism", "skinning", "firstaid", "cooking", "fishing", "lockpicking" }

addon.tabs = {
    { key = "leveling", label = L["Leveling"] },
    { key = "shopping", label = L["Shopping List"] },
    { key = "trainers", label = L["Trainers"] },
    { key = "extras", label = L["Extras"] },
}

-- Current skill in the guide's profession, or nil when unknown or not learned.
function addon.ReadSkill(skillLine)
    if type(GetProfessions) ~= "function" or type(GetProfessionInfo) ~= "function" then return end
    local ok, a, b, c, d, e, f = pcall(GetProfessions)
    if not ok then return end
    local indices = { a, b, c, d, e, f }
    for i = 1, 6 do
        if type(indices[i]) == "number" then
            local success, _, _, skill, _, _, _, line = pcall(GetProfessionInfo, indices[i])
            if success and line == skillLine and type(skill) == "number"
                and (not canaccessvalue or canaccessvalue(skill)) then
                return skill
            end
        end
    end
end

function addon.TierForSkill(guide, skill)
    if type(skill) ~= "number" then return end
    for i, tier in ipairs(guide.tiers) do
        if skill < tier.to then return i end
    end
    return #guide.tiers
end

-- "done" once the skill reaches the end of a step, "current" while inside it.
function addon.StepState(step, skill)
    if type(skill) ~= "number" then return "todo" end
    if skill >= step.to then return "done" end
    return skill >= step.from and "current" or "todo"
end

local function MaterialText(mats)
    local parts = {}
    for i, mat in ipairs(mats) do parts[i] = mat[1] .. "x " .. mat[2] end
    return table.concat(parts, ", ")
end

local function StepBlock(step)
    local lines = {}
    if #step.mats > 0 then lines[1] = "|cffffd100" .. L["Materials:"] .. "|r " .. MaterialText(step.mats) end
    local note, source = step.note, step.source
    if note and source then
        local first, last = note:find(source[1], 1, true)
        if first then note = note:sub(1, first - 1) .. "|cff66ccff" .. source[1] .. "|r" .. note:sub(last + 1) end
    end
    if note then lines[#lines + 1] = note end
    for _, alt in ipairs(step.alts or {}) do
        lines[#lines + 1] = "|cff66ccff" .. L["Alternative:"] .. "|r " .. alt
    end
    return { kind = "step", badge = step.from .. "-" .. step.to, title = step.count and (step.count .. "x " .. step.item) or step.item,
        body = #lines > 0 and table.concat(lines, "\n") or nil, step = step, source = source }
end

local function Leveling(guide)
    local pages = {}
    for i, tier in ipairs(guide.tiers) do
        local blocks = { { kind = "note", body = tier.requires } }
        if i == 1 then table.insert(blocks, 1, { kind = "note", body = guide.intro }) end
        for _, step in ipairs(tier.steps) do blocks[#blocks + 1] = StepBlock(step) end
        pages[i] = { title = tier.name .. " (" .. tier.from .. "-" .. tier.to .. ")", blocks = blocks, tier = i }
    end
    return pages
end

local function Shopping(guide)
    local pages = {}
    for i, list in ipairs(guide.shopping) do
        local blocks = { { kind = "note", body = "Estimates: yellow recipes may need a few more or fewer." } }
        for _, item in ipairs(list.items) do
            blocks[#blocks + 1] = { kind = "row", badge = item[1] .. "x", title = item[2], body = item[3] }
        end
        pages[i] = { title = list.range, blocks = blocks }
    end
    return pages
end

local function Trainers(guide)
    local pages = {}
    for i, page in ipairs(guide.trainers) do
        local blocks = {}
        for _, group in ipairs(page.groups) do
            blocks[#blocks + 1] = { kind = "heading", title = group[1] }
            for _, npc in ipairs(group[2]) do
                blocks[#blocks + 1] = { kind = "row", title = npc[1], body = npc[2], pin = guide.pins and guide.pins[npc[1]] }
            end
        end
        pages[i] = { title = page.title, blocks = blocks }
    end
    return pages
end

local function Extras(guide)
    local pages = {}
    if guide.ranks then
        local blocks = {}
        for i, rank in ipairs(guide.ranks) do
            blocks[i] = { kind = "row", title = rank[1], badge = rank[2], body = rank[3], pin = addon.SourcePin(rank) }
        end
        pages[1] = { title = "Learning each rank", blocks = blocks }
    end
    for i, page in ipairs(guide.extras) do
        local blocks = {}
        for _, text in ipairs(page.notes or {}) do blocks[#blocks + 1] = { kind = "note", body = text } end
        for _, row in ipairs(page.rows or {}) do
            blocks[#blocks + 1] = { kind = "row", title = row[1], badge = row[2], body = row[3] }
        end
        pages[#pages + 1] = { title = page.title, blocks = blocks }
    end
    return pages
end

local builders = { leveling = Leveling, shopping = Shopping, trainers = Trainers, extras = Extras }

-- Marks the NPC on the world map and opens it; false when the map API is missing.
function addon.ShowOnMap(pin)
    if type(pin) ~= "table" or not (C_Map and C_Map.SetUserWaypoint and UiMapPoint) then return false end
    return (pcall(function()
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(pin[1], pin[2] / 100, pin[3] / 100))
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
        if OpenWorldMap then OpenWorldMap(pin[1]) else ToggleWorldMap() end
    end))
end

-- Tabs that have content in this guide (gathering guides have no shopping list, for example).
-- Vendor pin for the player's faction; nil for drops, quests or factions without one.
function addon.SourcePin(source)
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    return source and source.pins and faction and source.pins[faction]
end

function addon.TabsFor(guide)
    local list = {}
    for _, tab in ipairs(addon.tabs) do
        if tab.key == "leveling" or guide[tab.key] then list[#list + 1] = tab end
    end
    return list
end

function addon.BuildPages(guide, key)
    return builders[key](guide)
end
