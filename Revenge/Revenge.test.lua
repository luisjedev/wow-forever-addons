local addon = assert(loadfile("Revenge.lua"))()

assert(addon.CleanPart("  Luis  ") == "Luis")
assert(addon.CleanPart("Luis Jesús") == nil)
assert(addon.CleanPart("Lu|is") == nil)
assert(addon.NameKey("Luis", "Jesús") == addon.NameKey("LUIS", "Jesús"))

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

print("Revenge helpers and optional recovery: OK")
