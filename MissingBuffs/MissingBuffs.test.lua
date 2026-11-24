local addon = assert(loadfile("MissingBuffs/MissingBuffs.lua"))()
local function keys(state) return table.concat(addon.Missing(state), ",") end
assert(keys({}) == "wellFed")
assert(keys({ canRest = true, knowsMinerals = true }) == "wellFed,rested,minerals")
assert(keys({ wellFed = true, canRest = true, rested = true, knowsMinerals = true, minerals = true }) == "")
assert(keys({ wellFed = true, canRest = false, knowsMinerals = true }) == "minerals")
print("MissingBuffs ok")
