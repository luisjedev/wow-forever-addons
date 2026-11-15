local _, addon = ...
local L = addon.L

addon.tabs = {
    { key = "leveling", label = L["Leveling"] },
    { key = "shopping", label = L["Shopping List"] },
    { key = "trainers", label = L["Trainers"] },
    { key = "extras", label = L["Extras"] },
}

-- Current skill in the guide's profession, or nil when unknown or not learned.
function addon.ReadSkill(skillLine)
    if type(GetProfessions) ~= "function" or type(GetProfessionInfo) ~= "function" then return end
    local ok, a, b, c, d, e = pcall(GetProfessions)
    if not ok then return end
    local indices = { a, b, c, d, e }
    for i = 1, 5 do
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
    local lines = { "|cffffd100" .. L["Materials:"] .. "|r " .. MaterialText(step.mats) }
    if step.note then lines[#lines + 1] = step.note end
    for _, alt in ipairs(step.alts or {}) do
        lines[#lines + 1] = "|cff66ccff" .. L["Alternative:"] .. "|r " .. alt
    end
    return { kind = "step", badge = step.from .. "-" .. step.to, title = step.count .. "x " .. step.item,
        body = table.concat(lines, "\n"), step = step }
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
                blocks[#blocks + 1] = { kind = "row", title = npc[1], body = npc[2] }
            end
        end
        pages[i] = { title = page.title, blocks = blocks }
    end
    return pages
end

local function Extras(guide)
    local quests = { { kind = "note", body = "Thorium Bar needed in total: 140 (included in the shopping list)." } }
    for _, quest in ipairs(guide.quests) do
        quests[#quests + 1] = { kind = "row", badge = quest[2], title = quest[1], body = quest[3] }
    end
    local notes = {}
    for i, text in ipairs(guide.notes) do notes[i] = { kind = "note", body = text } end
    return {
        { title = "Specializations", blocks = { { kind = "note", body = guide.specializations } } },
        { title = "Imperial Plate quests", blocks = quests },
        { title = "About this guide", blocks = notes },
    }
end

local builders = { leveling = Leveling, shopping = Shopping, trainers = Trainers, extras = Extras }

function addon.BuildPages(guide, key)
    return builders[key](guide)
end
