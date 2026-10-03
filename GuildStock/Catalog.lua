local _, addon = ...
local L = addon.L
addon.itemData = {}
addon.professions = {
    { "Alchemy", "Trade_Alchemy" }, { "Blacksmithing", "Trade_BlackSmithing" },
    { "Engineering", "Trade_Engineering" }, { "Tailoring", "Trade_Tailoring" },
    { "Leatherworking", "Trade_LeatherWorking" }, { "Enchanting", "Trade_Engraving" },
    { "Cooking", "INV_Misc_Food_15" }, { "FirstAid", "Spell_Holy_SealOfSacrifice" },
    { "Fishing", "Trade_Fishing" },
    { "Mining", "Trade_Mining" }, { "Herbalism", "Trade_Herbalism" }, { "Skinning", "INV_Misc_Pelt_Wolf_01" },
}

local function Table(value) return addon.Accessible(value) and type(value) == "table" end
local function ProfessionKey(value)
    if not addon.Integer(value, 0, 100) then return end
    for _, profession in ipairs(addon.professions) do
        if Enum and Enum.Profession and Enum.Profession[profession[1]] == value then return profession[1] end
    end
end

function addon.LearnedProfessions()
    if type(GetProfessions) ~= "function" or type(GetProfessionInfo) ~= "function" then return end
    local indices = { pcall(GetProfessions) }
    if not indices[1] then return end
    local learned, seen = {}, {}
    -- Match Forever's profession book: two primaries, Cooking, Fishing, First Aid.
    -- pcall adds one slot; optional profession returns can contain nil holes.
    for _, slot in ipairs({2, 3, 6, 5, 4}) do
        local index = indices[slot]
        if not addon.Accessible(index) then return end
        if index ~= nil then
            if not addon.Integer(index, 1, 1000) then return end
            local values = { pcall(GetProfessionInfo, index) }
            local skillLine = values[8]
            if not values[1] or not addon.Integer(skillLine, 1, 2147483647) then return end
            local info = addon.Read(C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID, skillLine)
            if not Table(info) or not addon.Integer(info.profession, 0, 100) then return end
            local key = ProfessionKey(info.profession)
            if key and not seen[key] then
                learned[#learned + 1], seen[key] = key, true
            end
        end
    end
    return learned
end

function addon.ItemData(id)
    if addon.itemData[id] == nil then
        addon.itemData[id] = false -- one request until GET_ITEM_INFO_RECEIVED succeeds
        if C_Item and C_Item.GetItemInfo then
            local values = { pcall(C_Item.GetItemInfo, id) }
            if values[1] and addon.Accessible(values[2]) and type(values[2]) == "string" then
                local data = { name = values[2]:gsub("|", "||") }
                if addon.Accessible(values[11]) then data.icon = values[11] end
                if addon.Accessible(values[18]) then data.reagent = values[18] == true end
                addon.itemData[id] = data
            end
        end
    end
    return addon.itemData[id] or { name = L["Item"] .. " #" .. id }
end

local runtimeCatalog = {}
local seededCatalog
local sortedMaterials, sortedCatalog, filteredMaterials = nil, nil, {}
local filterSnapshot, filterFavorites
function addon.InvalidateMaterials()
    sortedMaterials, filteredMaterials = nil, {}
end

function addon.Catalog()
    if addon.db.catalog == nil then addon.db.catalog = {} end
    local catalog = type(addon.db.catalog) == "table" and addon.db.catalog or runtimeCatalog
    if seededCatalog ~= catalog then
        for id, uses in pairs(addon.catalogSeed or {}) do
            if catalog[id] == nil then catalog[id] = {} end
            if type(catalog[id]) == "table" then
                for profession in pairs(uses) do
                    if catalog[id][profession] == nil then catalog[id][profession] = true end
                end
            end
        end
        seededCatalog = catalog
        addon.InvalidateMaterials()
    end
    if addon.snapshot then
        for id in pairs(addon.snapshot.items) do
            if addon.ItemData(id).reagent and catalog[id] == nil then
                catalog[id] = {}
                addon.InvalidateMaterials()
            end
        end
    end
    return catalog
end

function addon.DiscoverRecipes()
    if not addon.db or InCombatLockdown() then return end
    local api = C_TradeSkillUI
    local recipes = addon.Read(api and api.GetAllRecipeIDs)
    if not Table(recipes) then return end
    local catalog = addon.Catalog()
    for _, id in ipairs(recipes) do
        if addon.Integer(id, 1, 2147483647) then
            local info = addon.Read(api.GetProfessionInfoByRecipeID, id)
            local key = Table(info) and ProfessionKey(info.profession)
            local schematic = key and addon.Read(api.GetRecipeSchematic, id, false)
            if Table(schematic) and Table(schematic.reagentSlotSchematics) then
                for _, slot in ipairs(schematic.reagentSlotSchematics) do
                    if Table(slot) and Table(slot.reagents) then
                        for _, reagent in ipairs(slot.reagents) do
                            if Table(reagent) and addon.Integer(reagent.itemID, 1, 2147483647) then
                                local itemID = reagent.itemID
                                if catalog[itemID] == nil then catalog[itemID] = {} end
                                if type(catalog[itemID]) == "table" and catalog[itemID][key] ~= true then
                                    catalog[itemID][key] = true
                                    addon.InvalidateMaterials()
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Lua 5.1's lower only folds ASCII. Cover the Latin/Cyrillic alphabets in our locales.
local lowerLetters = {
    ["À"] = "à", ["Á"] = "á", ["Â"] = "â", ["Ã"] = "ã", ["Ä"] = "ä", ["Å"] = "å",
    ["Ç"] = "ç", ["È"] = "è", ["É"] = "é", ["Ê"] = "ê", ["Ë"] = "ë", ["Ì"] = "ì",
    ["Í"] = "í", ["Î"] = "î", ["Ï"] = "ï", ["Ñ"] = "ñ", ["Ò"] = "ò", ["Ó"] = "ó",
    ["Ô"] = "ô", ["Õ"] = "õ", ["Ö"] = "ö", ["Ù"] = "ù", ["Ú"] = "ú", ["Û"] = "û",
    ["Ü"] = "ü", ["Ý"] = "ý", ["Ÿ"] = "ÿ", ["Æ"] = "æ", ["Œ"] = "œ", ["ẞ"] = "ß",
    ["А"] = "а", ["Б"] = "б", ["В"] = "в", ["Г"] = "г", ["Д"] = "д", ["Е"] = "е", ["Ё"] = "ё",
    ["Ж"] = "ж", ["З"] = "з", ["И"] = "и", ["Й"] = "й", ["К"] = "к", ["Л"] = "л", ["М"] = "м",
    ["Н"] = "н", ["О"] = "о", ["П"] = "п", ["Р"] = "р", ["С"] = "с", ["Т"] = "т", ["У"] = "у",
    ["Ф"] = "ф", ["Х"] = "х", ["Ц"] = "ц", ["Ч"] = "ч", ["Ш"] = "ш", ["Щ"] = "щ", ["Ъ"] = "ъ",
    ["Ы"] = "ы", ["Ь"] = "ь", ["Э"] = "э", ["Ю"] = "ю", ["Я"] = "я",
}
local function SearchText(value)
    return (value:lower():gsub("[\194-\244][\128-\191]+", lowerLetters))
end
local function ItemSearchText(id, nativeName)
    local names = {nativeName}
    for _, localeNames in pairs(addon.itemNames) do
        if localeNames[id] then names[#names + 1] = localeNames[id] end
    end
    return SearchText(table.concat(names, "\n"))
end

function addon.Materials(view, profession, search, inventory)
    local catalog = addon.Catalog()
    if sortedCatalog ~= catalog then addon.InvalidateMaterials(); sortedCatalog = catalog end
    if not sortedMaterials then
        sortedMaterials = {}
        for id, professions in pairs(catalog) do
            if addon.Integer(id, 1, 2147483647) and type(professions) == "table" then
                local data = addon.ItemData(id)
                sortedMaterials[#sortedMaterials + 1] = {id = id, name = data.name, icon = data.icon, search = ItemSearchText(id, data.name)}
            end
        end
        table.sort(sortedMaterials, function(a, b) return a.name == b.name and a.id < b.id or a.name < b.name end)
    end
    if filterSnapshot ~= addon.snapshot or filterFavorites ~= addon.db.favorites then
        filteredMaterials = {}
        filterSnapshot, filterFavorites = addon.snapshot, addon.db.favorites
    end
    local favorites = type(addon.db.favorites) == "table" and addon.db.favorites or {}
    search = SearchText(search or "")
    -- Keep only the last query per navigation filter, not an unbounded search history.
    local key = (view or "all") .. ":" .. (profession or "all") .. (inventory and ":bags" or "")
    local cached = filteredMaterials[key]
    if cached and cached.search == search then return cached.entries end
    local result = {}
    for _, data in ipairs(sortedMaterials) do
        local id = data.id
        local own = addon.snapshot and addon.snapshot.items[id]
        if (not profession or catalog[id][profession] == true)
            and (view ~= "favorites" or favorites[id] == true)
            and (not inventory or own) and data.search:find(search, 1, true) then
            result[#result + 1] = {id = id, name = data.name, icon = data.icon, count = own and own.count}
        end
    end
    filteredMaterials[key] = {search = search, entries = result}
    return result
end

function addon.HiddenItems()
    local result = {}
    local hidden = type(addon.db.hiddenItems) == "table" and addon.db.hiddenItems or {}
    for id, value in pairs(hidden) do
        if addon.Integer(id, 1, 2147483647) and value == true then
            local data = addon.ItemData(id)
            result[#result + 1] = {id = id, name = data.name, icon = data.icon}
        end
    end
    table.sort(result, function(a, b) return a.name == b.name and a.id < b.id or a.name < b.name end)
    return result
end

function addon.ToggleFavorite(id)
    if addon.db.favorites == nil then addon.db.favorites = {} end
    if type(addon.db.favorites) ~= "table" then return end
    addon.db.favorites[id] = not addon.db.favorites[id] or nil
    filteredMaterials = {}
end

function addon.CharacterItems(character, search)
    local result = {}
    if not character then return result end
    search = SearchText(search or "")
    for id, item in pairs(character.snapshot.items) do
        local data = addon.ItemData(id)
        if ItemSearchText(id, data.name):find(search, 1, true) then
            result[#result + 1] = {id = id, name = data.name, icon = data.icon, count = item.count}
        end
    end
    table.sort(result, function(a, b) return a.name == b.name and a.id < b.id or a.name < b.name end)
    return result
end

local events = CreateFrame("Frame")
events:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
events:RegisterEvent("TRADE_SKILL_SHOW")
events:SetScript("OnEvent", function()
    addon.DiscoverRecipes()
    if addon.Refresh then addon.Refresh() end
end)
