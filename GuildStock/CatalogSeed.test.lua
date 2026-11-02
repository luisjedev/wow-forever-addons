-- Run from the repository root. Synthetic saved data only; never reads a client profile.
GetLocale = function() return "enUS" end
time = function() return 100 end
InCombatLockdown = function() return false end
CreateFrame = function()
    return {RegisterEvent = function() end, SetScript = function() end}
end
SlashCmdList = {}
local function Load(saved)
    GuildStockDB = saved
    local addon = {}
    -- Follow manifest order, omitting the independent transport and native UI modules.
    for line in io.lines("GuildStock/GuildStock.toc") do
        if line:match("%.lua$") and line ~= "Probe.lua" and line ~= "UI.lua" then
            assert(loadfile("GuildStock/" .. line))("GuildStock", addon)
        end
    end
    addon.Initialize()
    return addon
end
local addon = Load(nil)
local seed, count, associations, professions = addon.catalogSeed, 0, 0, {}
assert(type(seed) == "table", "manifest must load the common catalog")
local known = {}
for _, profession in ipairs(addon.professions) do known[profession[1]] = true end
for id, uses in pairs(seed) do
    assert(addon.Integer(id, 1, 2147483647))
    count = count + 1
    for profession, value in pairs(uses) do
        assert(known[profession] and value == true, "seed must contain only public profession associations")
        associations = associations + 1
        professions[profession] = true
    end
end
local professionCount = 0
for _ in pairs(professions) do professionCount = professionCount + 1 end
assert(count == 589 and associations == 1083 and professionCount == 12)
local catalog = addon.Catalog()
assert(#addon.Materials("all") == count and addon.snapshot == nil and addon.db.own == nil)
for id, uses in pairs(seed) do
    assert(catalog[id] ~= uses, "saved tables must not alias bundled data")
    for profession in pairs(uses) do assert(catalog[id][profession] == true) end
end
for _, entry in ipairs(addon.Materials("all")) do assert(entry.count == nil) end
for profession in pairs(professions) do
    assert(#addon.Materials("all", profession) > 0, "each observed profession is available without opening it")
end

local first = next(seed)
local existingUses = {CustomUse = true}
local existingCatalog = {[first] = existingUses, [2147483647] = {Cooking = true}}
local own = {observedAt = 90, items = {[first] = {count = 7, bound = 1}}}
local favorites, hidden, settings = {[first] = true}, {[first] = true}, {language = "enUS", scale = 0.9}
local saved = {version = 1, catalog = existingCatalog, own = own, favorites = favorites,
    hiddenItems = hidden, settings = settings}
addon = Load(saved)
assert(addon.Catalog() == existingCatalog and existingCatalog[first] == existingUses)
assert(existingUses.CustomUse and existingCatalog[2147483647].Cooking)
assert(addon.db == saved and saved.own == own and addon.snapshot == own)
assert(saved.favorites == favorites and saved.hiddenItems == hidden and saved.settings == settings)
assert(#addon.Materials("all") == count + 1)
local favorite = addon.Materials("favorites")[1]
assert(favorite.id == first and favorite.count == 7)
assert(addon.IsItemHidden(first) and not addon.ShareableSnapshot().items[first])
local usesBefore = existingCatalog[first]
addon = Load(saved) -- A reload merges idempotently, retaining the same records.
assert(addon.Catalog()[first] == usesBefore and #addon.Materials("all") == count + 1)
assert(not addon.catalogSeed[first].CustomUse and addon.catalogSeed[2147483647] == nil)

-- New recipe discoveries are added alongside the bundled material/profession pairs.
Enum = {Profession = {Cooking = 5}}
C_TradeSkillUI = {
    GetAllRecipeIDs = function() return {1} end,
    GetProfessionInfoByRecipeID = function() return {profession = 5} end,
    GetRecipeSchematic = function()
        return {reagentSlotSchematics = {{reagents = {{itemID = 2147483646}}}}}
    end,
}
addon.DiscoverRecipes()
assert(addon.Catalog()[2147483646].Cooking and #addon.Materials("all") == count + 2)
assert(addon.catalogSeed[2147483646] == nil)

-- Never overwrite unsupported schemas, catalog entries, or existing values.
for _, unknown in ipairs({{version = 2, catalog = {}}, {legacy = true}, "damaged"}) do
    addon = Load(unknown)
    assert(#addon.Materials("all") == count and addon.temporary and GuildStockDB == unknown)
    if type(unknown) == "table" and unknown.catalog then assert(next(unknown.catalog) == nil) end
    assert(addon.snapshot == nil and addon.ShareableSnapshot() == nil)
end
saved = {version = 1, catalog = "future-format", hiddenItems = "future-privacy"}
addon = Load(saved)
assert(#addon.Materials("all") == count and saved.catalog == "future-format")
assert(saved.hiddenItems == "future-privacy" and addon.ShareableSnapshot() == nil)
local profession = next(seed[first])
saved = {version = 1, catalog = {[first] = {[profession] = false}, [2147483645] = "unknown"}}
addon = Load(saved)
assert(addon.Catalog()[first][profession] == false and saved.catalog[2147483645] == "unknown")
saved = {version = 1, catalog = {[first] = "unknown"}}
addon = Load(saved)
assert(addon.Catalog()[first] == "unknown")
print("GuildStock seed: 589 materials, 1083 associations, 12 professions; clean install, merge and preservation OK")
