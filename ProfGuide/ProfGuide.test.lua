-- Run from the repository root: luajit ProfGuide/ProfGuide.test.lua
GetLocale = function() return "enUS" end
-- Every Data file listed in the .toc, in .toc order.
local files = {}
for line in io.lines("ProfGuide/ProfGuide.toc") do
    if line:match("%.lua$") then files[#files + 1] = line:gsub("\\", "/"):gsub("%.lua$", "") end
end
local function Load(target)
    for _, file in ipairs(files) do
        if file ~= "ProfGuide" then assert(loadfile("ProfGuide/" .. file .. ".lua"))("ProfGuide", target) end
    end
end
local addon = {}
Load(addon)
local guide = addon.guides.blacksmithing

-- Each overview tile has a guide, and every guide has a tile.
local count = 0
for _ in pairs(addon.guides) do count = count + 1 end
assert(count == #addon.guideOrder and count == 13, "guide count")

for _, key in ipairs(addon.guideOrder) do
    local g = assert(addon.guides[key], key)
    assert(type(g.name) == "string" and type(g.skillLine) == "number" and type(g.icon) == "string" and g.max == 300, key)
    -- Steps are contiguous from 1 to max and each tier ends where the next begins.
    local expected = 1
    for _, tier in ipairs(g.tiers) do
        assert(tier.from == expected, key .. ": tier gap before " .. tier.name)
        for _, step in ipairs(tier.steps) do
            assert(step.from == expected and step.to > step.from, key .. ": step gap at " .. step.from)
            assert(type(step.item) == "string" and type(step.mats) == "table", key .. ": step " .. step.from)
            expected = step.to
        end
        assert(expected == tier.to, key .. ": " .. tier.name .. " tier end")
    end
    assert(expected == g.max, key .. " ends at max")
    -- Every tab the guide offers builds 1-6 pages whose blocks have the fields the window reads.
    for _, tab in ipairs(addon.TabsFor(g)) do
        local pages = tab.key == "recipes" and { { title = "", blocks = { { kind = "note", body = "" } } } }
            or addon.BuildPages(g, tab.key)
        assert(#pages >= 1 and #pages <= 6, key .. " " .. tab.key .. " page count")
        for _, page in ipairs(pages) do
            assert(type(page.title) == "string" and #page.blocks > 0, key .. " " .. tab.key .. " empty page")
            for _, block in ipairs(page.blocks) do
                assert(block.kind == "heading" and block.title or block.kind == "note" and block.body
                    or (block.kind == "step" or block.kind == "row") and type(block.title) == "string", key .. " " .. tab.key .. " block")
            end
        end
    end
end
assert(#addon.TabsFor(addon.guides.mining) == 3 and #addon.TabsFor(guide) == 5, "gathering guides have no shopping or recipes tab")
-- Every profession with vendor recipes is a guide that offers the Recipes tab; the others do not.
local withRecipes = 0
for _, key in ipairs(addon.guideOrder) do
    local g, offers = addon.guides[key], false
    for _, tab in ipairs(addon.TabsFor(g)) do offers = offers or tab.key == "recipes" end
    assert(offers == (addon.recipes[g.skillLine] ~= nil), key .. " recipes tab")
    if offers then withRecipes = withRecipes + 1 end
end
assert(withRecipes == 7, "recipes tab in 7 guides")
local gather = addon.BuildPages(addon.guides.mining, "leveling")[1].blocks[3]
assert(gather.title:find("^Copper Vein") and not gather.body:find("Materials", 1, true), "gathering step has no count or materials")

-- Recipe sources: highlighted in the note, map pin only for the player's faction.
local manual = addon.guides.firstaid.tiers[3].steps[2]
UnitFactionGroup = function() return "Alliance" end
assert(addon.SourcePin(manual.source)[1] == 1417 and addon.SourcePin(addon.guides.firstaid.tiers[4].steps[4].source) == nil, "faction vendor pin")
UnitFactionGroup = function() return "Skyborne" end
assert(addon.SourcePin(manual.source) == nil, "no pin without a faction vendor")
UnitFactionGroup = nil
local manualBlock = addon.BuildPages(addon.guides.firstaid, "leveling")[3].blocks[3]
assert(manualBlock.source == manual.source and manualBlock.body:find("|cff66ccffManual: Heavy Silk Bandage|r", 1, true), "highlights the recipe")
-- Extras open on how each rank is learned, with a map pin for the player's faction.
UnitFactionGroup = function() return "Horde" end
local ranks = addon.BuildPages(addon.guides.cooking, "extras")[1]
assert(ranks.title == "Learning each rank" and #ranks.blocks == 4 and ranks.blocks[3].badge == "Item", "rank page")
assert(ranks.blocks[1].pin == nil and ranks.blocks[3].pin[1] == 1443 and ranks.blocks[4].pin[1] == 1446, "rank pins per faction")
UnitFactionGroup = nil
for _, key in ipairs(addon.guideOrder) do
    for _, rank in ipairs(addon.guides[key].ranks or {}) do
        for _, pin in pairs(rank.pins or {}) do assert(#pin == 3 and pin[2] > 0 and pin[2] < 100 and pin[3] > 0 and pin[3] < 100, key .. " pin") end
    end
end
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

local counts = { leveling = 4, shopping = 3, trainers = 3, extras = 4 }
for key, count in pairs(counts) do assert(#addon.BuildPages(guide, key) == count, key .. " page count") end
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
for _, file in ipairs({ "ProfGuide", "Pages", "WritsPanel" }) do
    local source = assert(io.open("ProfGuide/" .. file .. ".lua")):read("*a")
    for key in source:gmatch('L%["(.-)"%]') do assert(rawget(es.L, key), "missing esES " .. key) end
end
for _, list in ipairs({ addon.PROFS, addon.TIERS, addon.STANDINGS }) do
    for _, key in pairs(list) do assert(rawget(es.L, key), "missing esES " .. key) end
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
function frameMethods:GetNormalTexture() return newFrame() end
frameMethods.CreateTexture, frameMethods.CreateFontString = newFrame, newFrame
GetLocale = function() return "enUS" end
Minimap, UIParent, GameTooltip = newFrame(), newFrame(), newFrame()
UISpecialFrames, SlashCmdList = {}, {}
CreateFrame = function() local f = newFrame(); f.ScrollBar = newFrame(); return f end
GetProfessions = function() return 1 end
C_Item = { GetItemCount = function() return 0 end, GetItemIconByID = function() return 1 end, GetItemNameByID = function() return "Item" end,
    GetItemInfoInstant = function(id) return id, "Armor", "Plate", "INVTYPE_CHEST", 1, 4, 4 end }
GetMoneyString = function(copper) return copper .. "c" end
UnitFactionGroup = function() return "Horde" end
GetProfessionInfo = function() return "Blacksmithing", "i", 100, 150, 0, 0, 164 end
-- Old flat Blacksmithing pages migrate; invalid entries are dropped.
ProfGuideDB = { tab = "shopping", pages = { shopping = 2, leveling = "bad", bogus = 9, alchemy = { extras = 2, trainers = 0 } },
    writs = { filter = "bogus", zones = { Wetlands = true, Nowhere = true } } }
local ui = {}
Load(ui)
assert(loadfile("ProfGuide/ProfGuide.lua"))("ProfGuide", ui)
for _, f in ipairs(frames) do if f.events.PLAYER_LOGIN then f.scripts.OnEvent(f, "PLAYER_LOGIN") end end
local saved = ProfGuideDB.pages
assert(saved.blacksmithing.shopping == 2 and saved.blacksmithing.leveling == nil and saved.shopping == nil, "migrates flat pages")
assert(saved.alchemy.extras == 2 and saved.alchemy.trainers == nil and saved.bogus == nil, "keeps valid saved pages, drops invalid")
SlashCmdList.PROFGUIDE()
local window
for _, f in ipairs(frames) do if f.scripts.OnShow and f.shown then window = f end end
assert(window and window.shown, "slash opens window")
local function click(button) button.scripts.OnClick(button) end
local tabs, tiles, back = {}, {}
for _, f in ipairs(frames) do
    if f.key and ui.guides[f.key] then tiles[f.key] = f elseif f.key then tabs[f.key] = f end
    if f.text == "Back" then back = f end
end
assert(tiles.alchemy.shown and not tabs.leveling.shown, "opens on the overview")
for _, key in ipairs(ui.guideOrder) do
    click(tiles[key])
    assert(not tiles[key].shown and back.shown, key .. " opens its guide")
    for _, tab in ipairs(ui.TabsFor(ui.guides[key])) do
        click(tabs[tab.key])
        assert(ProfGuideDB.tab == tab.key)
        for _, f in ipairs(frames) do
            if f.text == "Next" and f.enabled ~= false then
                for _ = 1, 5 do if f.enabled ~= false then click(f) end end
            end
        end
    end
    click(back)
    assert(tiles[key].shown and not back.shown, "back returns to the overview")
end
click(tiles.mining)
assert(not tabs.shopping.shown and tabs.trainers.shown, "mining hides the shopping tab")
-- Skill 100 Blacksmithing opens on the Journeyman tier.
click(back); click(tiles.blacksmithing)
assert(ProfGuideDB.tab == "leveling" and saved.blacksmithing.leveling == 2, "jumps to current tier")
-- Writs view: header button, its three filters, Back returns to the guide it was opened from.
local writs, filters = nil, {}
for _, f in ipairs(frames) do
    if f.text == "Writs" then writs = f end
    if f.text == "All" or f.text == "In bags" or f.text == "Vendor items" then filters[f.text] = f end
end
local writDB = ProfGuideDB.writs
assert(writDB.filter == "bogus" and writDB.zones.Wetlands and not writDB.zones.Nowhere, "valid writ zones load, unknown dropped")
click(writs)
assert(writs.enabled == false and back.shown and not tabs.leveling.shown, "writs view replaces the guide")
for _, key in ipairs({ "In bags", "Vendor items", "All" }) do click(filters[key]) end
assert(writDB.filter == "all", "writ filter saved")
click(back)
assert(tabs.leveling.shown and writs.enabled, "back returns to the guide")
SlashCmdList.PROFGUIDEWRITS()
assert(window.shown and writs.enabled == false, "/writs opens the writs view")
click(back); click(back)
assert(tiles.alchemy.shown and not back.shown, "back to the overview")
SlashCmdList.PROFGUIDE()
assert(not window.shown, "slash toggles window closed")
print("ProfGuide data and page logic: OK")
