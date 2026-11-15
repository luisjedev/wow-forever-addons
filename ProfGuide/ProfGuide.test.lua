-- Run from the repository root: luajit ProfGuide/ProfGuide.test.lua
GetLocale = function() return "enUS" end
local addon = {}
for _, file in ipairs({ "Locales", "Data/Blacksmithing", "Pages" }) do
    assert(loadfile("ProfGuide/" .. file .. ".lua"))("ProfGuide", addon)
end
local guide = addon.guides.blacksmithing

-- Steps are contiguous from 1 to 300 and each tier ends where the next begins.
local expected = 1
for _, tier in ipairs(guide.tiers) do
    assert(tier.from == expected, "tier gap before " .. tier.name)
    for _, step in ipairs(tier.steps) do
        assert(step.from == expected and step.to > step.from, "step gap at " .. step.from)
        expected = step.to
    end
    assert(expected == tier.to, tier.name .. " tier end")
end
assert(expected == 300)

-- Shopping totals equal the sum of the matching step materials (Thorium adds the 140 quest bars).
for _, list in ipairs(guide.shopping) do
    local sums = {}
    for _, tier in ipairs(guide.tiers) do
        for _, step in ipairs(tier.steps) do
            if step.from >= list.from and step.to <= list.to then
                for _, mat in ipairs(step.mats) do sums[mat[2]] = (sums[mat[2]] or 0) + mat[1] end
            end
        end
    end
    sums["Thorium Bar"] = sums["Thorium Bar"] and sums["Thorium Bar"] + 140
    for _, item in ipairs(list.items) do
        assert(sums[item[2]] == item[1], list.range .. " " .. item[2] .. ": " .. tostring(sums[item[2]]) .. " vs " .. item[1])
    end
end

-- Skill state and tier lookup.
local step = { from = 75, to = 80 }
assert(addon.StepState(step, 74) == "todo" and addon.StepState(step, 75) == "current")
assert(addon.StepState(step, 79) == "current" and addon.StepState(step, 80) == "done")
assert(addon.StepState(step, nil) == "todo")
assert(addon.TierForSkill(guide, 1) == 1 and addon.TierForSkill(guide, 75) == 2)
assert(addon.TierForSkill(guide, 214) == 3 and addon.TierForSkill(guide, 300) == 4 and addon.TierForSkill(guide, nil) == nil)

-- Every tab builds pages whose blocks have the fields the window reads.
local counts = { leveling = 4, shopping = 3, trainers = 3, extras = 3 }
for _, tab in ipairs(addon.tabs) do
    local pages = addon.BuildPages(guide, tab.key)
    assert(#pages == counts[tab.key] and #pages <= 6, tab.key .. " page count")
    for _, page in ipairs(pages) do
        assert(type(page.title) == "string" and #page.blocks > 0)
        for _, block in ipairs(page.blocks) do
            assert(block.kind == "heading" and block.title or block.kind == "note" and block.body
                or (block.kind == "step" or block.kind == "row") and block.title)
        end
    end
end
local first = addon.BuildPages(guide, "leveling")[2].blocks[2]
assert(first.title == "5x Silver Rod" and first.badge == "75-80" and first.body:find("5x Silver Bar, 10x Rough Grinding Stone", 1, true))

-- Skill reading: matches by skill line, ignores bad or restricted values.
GetProfessions = function() return 1, 2 end
GetProfessionInfo = function(index) return "n", "i", index == 2 and 52 or 10, 75, 0, 0, index == 2 and 164 or 186 end
assert(addon.ReadSkill(164) == 52 and addon.ReadSkill(999) == nil)
canaccessvalue = function() return false end
assert(addon.ReadSkill(164) == nil)
canaccessvalue = nil
GetProfessions = function() error("boom") end
assert(addon.ReadSkill(164) == nil)
GetProfessions = nil
assert(addon.ReadSkill(164) == nil)

-- Spanish chrome keeps a translation for every key the window uses.
GetLocale = function() return "esES" end
local es = {}
assert(loadfile("ProfGuide/Locales.lua"))("ProfGuide", es)
for _, key in ipairs({ "Leveling", "Shopping List", "Trainers", "Extras", "Previous", "Next", "Page %d / %d", "Materials:",
    "Alternative:", "Now", "Done", "Not learned", "Left-click: Open / close", "Drag: Move" }) do
    assert(rawget(es.L, key), "missing esES " .. key)
end
-- Window smoke test with permissive frame stubs: open, switch tabs, page through everything.
local frames = {}
local frameMethods = setmetatable({}, { __index = function() return function() return 20 end end })
local function newFrame()
    local f = setmetatable({ scripts = {}, events = {}, shown = true, texts = {} }, { __index = frameMethods })
    frames[#frames + 1] = f
    return f
end
function frameMethods:SetScript(name, callback) self.scripts[name] = callback end
function frameMethods:GetScript(name) return self.scripts[name] end
function frameMethods:RegisterEvent(name) self.events[name] = true end
function frameMethods:SetText(text) self.text = text end
function frameMethods:SetShown(shown) self.shown = shown; local cb = self.scripts[shown and "OnShow" or "OnHide"]; if cb then cb(self) end end
function frameMethods:IsShown() return self.shown end
function frameMethods:SetEnabled(enabled) self.enabled = enabled end
function frameMethods:GetPoint() return "CENTER", nil, "CENTER", 0, 0 end
function frameMethods:Hide() self:SetShown(false) end
function frameMethods:Show() self:SetShown(true) end
frameMethods.CreateTexture, frameMethods.CreateFontString = newFrame, newFrame
GetLocale = function() return "enUS" end
Minimap, UIParent, GameTooltip = newFrame(), newFrame(), newFrame()
UISpecialFrames, SlashCmdList = {}, {}
CreateFrame = function() local f = newFrame(); f.ScrollBar = newFrame(); return f end
GetProfessions = function() return 1 end
GetProfessionInfo = function() return "Blacksmithing", "i", 100, 150, 0, 0, 164 end
ProfGuideDB = { tab = "shopping", pages = { shopping = 2, leveling = "bad", bogus = 9 } }
local ui = {}
for _, file in ipairs({ "Locales", "Data/Blacksmithing", "Pages", "ProfGuide" }) do
    assert(loadfile("ProfGuide/" .. file .. ".lua"))("ProfGuide", ui)
end
for _, f in ipairs(frames) do if f.events.PLAYER_LOGIN then f.scripts.OnEvent(f, "PLAYER_LOGIN") end end
assert(ProfGuideDB.pages.shopping == 2 and ProfGuideDB.pages.leveling == nil, "keeps valid saved page, drops invalid")
SlashCmdList.PROFGUIDE()
local window
for _, f in ipairs(frames) do if f.scripts.OnShow and f.shown then window = f end end
assert(window and window.shown, "slash opens window")
local function click(button) button.scripts.OnClick(button) end
local tabs = {}
for _, f in ipairs(frames) do if f.key then tabs[f.key] = f end end
for _, key in ipairs({ "leveling", "shopping", "trainers", "extras" }) do
    click(tabs[key])
    assert(ProfGuideDB.tab == key)
    for _, f in ipairs(frames) do
        if f.text == "Next" and f.enabled ~= false then
            for _ = 1, 5 do if f.enabled ~= false then click(f) end end
        end
    end
end
SlashCmdList.PROFGUIDE()
assert(not window.shown, "slash toggles window closed")
print("ProfGuide data and page logic: OK")
