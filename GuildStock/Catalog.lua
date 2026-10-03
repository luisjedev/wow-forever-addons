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
function addon.Catalog()
    if addon.db.catalog == nil then addon.db.catalog = {} end
    local catalog = type(addon.db.catalog) == "table" and addon.db.catalog or runtimeCatalog
    if addon.snapshot then
        for id in pairs(addon.snapshot.items) do
            if addon.ItemData(id).reagent and catalog[id] == nil then catalog[id] = {} end
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
                                if type(catalog[itemID]) == "table" then catalog[itemID][key] = true end
                            end
                        end
                    end
                end
            end
        end
    end
end

function addon.Materials(view, profession, search, inventory)
    local result = {}
    local favorites = type(addon.db.favorites) == "table" and addon.db.favorites or {}
    search = (search or ""):lower()
    for id, professions in pairs(addon.Catalog()) do
        if addon.Integer(id, 1, 2147483647) and type(professions) == "table" then
            local own = addon.snapshot and addon.snapshot.items[id]
            local data = addon.ItemData(id)
            if (not profession or professions[profession] == true)
                and (view ~= "favorites" or favorites[id] == true)
                and (not inventory or own) and data.name:lower():find(search, 1, true) then
                result[#result + 1] = { id = id, name = data.name, icon = data.icon, count = own and own.count }
            end
        end
    end
    table.sort(result, function(a, b) return a.name == b.name and a.id < b.id or a.name < b.name end)
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
end

function addon.CharacterItems(character, search)
    local result = {}
    if not character then return result end
    search = (search or ""):lower()
    for id, item in pairs(character.snapshot.items) do
        local data = addon.ItemData(id)
        if data.name:lower():find(search, 1, true) then
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
