local addon = assert(loadfile("Revenge.lua"))()

assert(addon.CleanPart("  Test  ") == "Test")
assert(addon.CleanPart("Test Éxample") == nil)
assert(addon.CleanPart("Te|st") == nil)
assert(addon.NameKey("Test", "Éxample") == addon.NameKey("TEST", "Éxample"))

local characterDB = { revision = 2 }
local backupDB = { revision = 3 }
assert(addon.SelectNewestDB(characterDB, backupDB) == backupDB)
assert(addon.SelectNewestDB(characterDB, { revision = 1 }) == characterDB)
assert(addon.SelectNewestDB(nil, backupDB) == backupDB)

local recovery = { key = "test-character", revision = 12, enemies = { example = { firstName = "Test" } } }
local emptyDB = { revision = 0, enemies = {} }
addon.ApplyLocalRecovery(emptyDB, "test-character", nil)
assert(next(emptyDB.enemies) == nil and emptyDB.revision == 0)
addon.ApplyLocalRecovery(emptyDB, "other-character", recovery)
assert(next(emptyDB.enemies) == nil and emptyDB.revision == 0)
addon.ApplyLocalRecovery(emptyDB, "test-character", recovery)
assert(emptyDB.enemies.example == recovery.enemies.example and emptyDB.revision == 12)
local populatedDB = { revision = 1, enemies = { existing = {} } }
addon.ApplyLocalRecovery(populatedDB, "test-character", recovery)
assert(populatedDB.enemies.example == nil and populatedDB.revision == 1)
local newerDB = { revision = 13, enemies = {} }
addon.ApplyLocalRecovery(newerDB, "test-character", recovery)
assert(next(newerDB.enemies) == nil and newerDB.revision == 13)

local sourceFile = assert(io.open("Revenge.lua", "r"))
local source = sourceFile:read("*a")
sourceFile:close()
local keys = {}
for key in source:gmatch('L%["(.-)"%]') do keys[key] = true end
assert(keys["Add"] and keys["Saved enemies: %d"])
local loadLocales = assert(loadfile("Locales.lua"))
local spanish
for _, locale in ipairs({"esES", "esMX", "frFR", "deDE", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW", "enUS", "enGB", "unknown"}) do
    GetLocale = function() return locale end
    local localized = {}
    loadLocales("Revenge", localized)
    local L = localized.L
    if locale == "esES" then spanish = L end
    for key in pairs(keys) do
        local text = L[key]
        if locale == "enUS" or locale == "enGB" or locale == "unknown" then
            assert(text == key, locale .. ": English fallback missing for " .. key)
        else
            assert(type(rawget(L, key)) == "string" and text ~= "", locale .. ": missing " .. key)
        end
        if locale == "esMX" then assert(text == spanish[key]) end
        local function placeholders(value)
            local found = {}
            for token in value:gmatch("%%.") do found[#found + 1] = token end
            return table.concat(found)
        end
        assert(placeholders(text) == placeholders(key), locale .. ": format mismatch for " .. key)
        assert(pcall(string.format, text, key:find("%%d") and 2 or "Test Example"))
    end
    assert(L["Missing translation"] == "Missing translation")
end
GetLocale = nil

print("Revenge helpers, optional recovery and locales: OK")
