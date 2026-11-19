local _, addon = ...
-- Source: https://www.wow-professions.com/forever/herbalism-leveling-guide (Forever beta). Route maps on the page are images and are not included.
local S = addon.Step

addon.guides.herbalism = {
    name = "Herbalism",
    skillLine = 182,
    icon = "Interface\\Icons\\Spell_Nature_NatureTouchGrow",
    max = 300,
    intro = "Pick the herbs listed for each skill range in the zones given. Every starting zone has enough herbs for 1-70. Turn on Find Herbs from the Professions window: it turns off every time you die, and you cannot track herbs and minerals together.",
    tiers = {
        { name = "Apprentice", from = 1, to = 70, requires = "Any Herbalism trainer (starting-zone trainers only up to 75).", steps = {
            S(1, 15, nil, "Peacebloom, Silverleaf: Durotar / Mulgore / Tirisfal Glades", {}, "Respawn is fast, so without a mount you may just run circles.",
                { "Alliance: Elwynn Forest / Dun Morogh / Teldrassil.", "Either faction: Zephras Isle." }),
            S(15, 70, nil, "Peacebloom, Silverleaf, Earthroot: same zones", {}, "Earthroot needs Herbalism 15."),
        } },
        { name = "Journeyman", from = 70, to = 115, requires = "Journeyman Herbalism (Herbalism 50); Junior trainers do not teach it.", steps = {
            S(70, 85, nil, "Mageroyal, Briarthorn: Silverpine Forest / Loch Modan / Darkshore", {}, "Darkshore has herbs everywhere; Loch Modan is an easy route with fewer herbs."),
            S(85, 115, nil, "Mageroyal, Briarthorn, Stranglekelp: same zones", {}, "Stranglekelp needs Herbalism 85."),
        } },
        { name = "Expert", from = 115, to = 205, requires = "Expert Herbalism (Herbalism 125), needed to train past 150.", steps = {
            S(115, 125, nil, "Bruiseweed, Wild Steelbloom, Stranglekelp: Hillsbrad Foothills / Stonetalon Mountains", {}, "The Hillsbrad loop gives herbs time to respawn without a mount."),
            S(125, 150, nil, "Add Kingsblood: same zones", {}, "Kingsblood needs Herbalism 125. Stonetalon is crowded above 125 but has more Kingsblood."),
            S(150, 170, nil, "Add Liferoot: same zones", {}, "Liferoot needs Herbalism 150."),
            S(170, 185, nil, "Kingsblood, Liferoot, Fadeleaf, Goldthorn: Stranglethorn Vale / Arathi Highlands", {}, "Standard Classic routes, untested above the beta cap of 30."),
            S(185, 205, nil, "Add Khadgar's Whisker: Stranglethorn Vale / Arathi Highlands", {}, "Khadgar's Whisker needs Herbalism 185."),
        } },
        { name = "Artisan", from = 205, to = 300, requires = "Artisan Herbalism (Herbalism 200). Learn it before leaving for Tanaris or Searing Gorge.", steps = {
            S(205, 230, nil, "Purple Lotus, Firebloom: Tanaris / Searing Gorge", {}, "Neither zone has a trainer: without Artisan you would have to fly back at 225."),
            S(230, 245, nil, "Sungrass, Purple Lotus, Golden Sansam: The Hinterlands", {}),
            S(245, 270, nil, "Add Ghost Mushroom: The Hinterlands cave", {}, "Ghost Mushroom needs Herbalism 245; the cave has many."),
            S(270, 300, nil, "Sungrass, Gromsblood, Golden Sansam, Dreamfoil, Mountain Silversage, Plaguebloom: Felwood", {}),
        } },
    },
    trainers = {
        { title = "Capital cities", groups = {
            { "Horde", { { "Jandi", "Orgrimmar" }, { "Martha Alliestar", "Undercity" }, { "Komin Winterhoof", "Thunder Bluff" } } },
            { "Alliance", { { "Tannysa", "Stormwind City" }, { "Reyna Stonebranch", "Ironforge" }, { "Firodren Mooncaller", "Darnassus" } } },
        } },
        { title = "Starting zones", groups = {
            { "Horde", { { "Zor'la", "Valley of Trials, Durotar (only up to 75)" }, { "Mishiki", "Sen'jin Village, Durotar" },
                { "Garan Sunstrider", "Camp Narache, Mulgore (only up to 75)" }, { "Florence Nightshade", "Deathknell, Tirisfal Glades (only up to 75)" }, { "Faruza", "Brill, Tirisfal Glades" } } },
            { "Alliance", { { "Nancy Songflower", "Elwynn Forest (only up to 75)" }, { "Herbalist Pomeroy", "Elwynn Forest" }, { "Emrys Flintbeard", "Dun Morogh (only up to 75)" },
                { "Eleyna Duskbreeze", "Aldrassil, Shadowglen, Teldrassil (only up to 75)" }, { "Malorne Bladeleaf", "Dolanaar, Teldrassil" } } },
            { "Skyborne", { { "No trainer", "Thendal Village: pick Wild Harvest from the Harvesting Windstones quest, it teaches Herbalism." },
                { "Syriel Nightrain", "Valanaar, Zephras Isle" }, { "Halassa Fernbreeze", "Shen'dar Village, Zephras Isle" } } },
        } },
    },
    -- How each rank is learned (Extras). Pins: Classic map IDs, approximate town-level spots.
    ranks = (function()
        local R = addon.Rank
        return {
            R("Apprentice (1-75)", "Trainer", "Any Herbalism trainer (see Trainers). Skyborne: Wild Harvest, reward of the Harvesting Windstones quest."),
            R("Journeyman (75-150)", "Trainer", "Herbalism 50. Starting-area Junior trainers stop at 75: use a town or capital trainer."),
            R("Expert (150-225)", "Trainer", "Herbalism 125, from a town or capital trainer."),
            R("Artisan (225-300)", "Trainer", "Herbalism 200, from a town or capital trainer. Learn it before leaving for Tanaris or Searing Gorge."),
        }
    end)(),
    extras = {
        { title = "Skill bonuses", notes = { "Not required, but with +5 you can pick Kingsblood at 120 instead of 125." }, rows = {
            { "Enchant Gloves - Herbalism", "+2", "From an enchanter." },
            { "Enchant Gloves - Advanced Herbalism", "+5", "From an enchanter." },
            { "Herbalist's Gloves", "+5", "World drop; check the Auction House." },
            { "Goldthorn Tea", "+15", "Recipe from Henry Stern in Razorfen Downs (Cooking 175), left path to the stables." },
        } },
        { title = "Herbs by skill", rows = {
            { "1-70", nil, "Peacebloom, Silverleaf, Earthroot (15)" },
            { "70-115", nil, "Mageroyal, Briarthorn, Stranglekelp (85)" },
            { "115-170", nil, "Bruiseweed, Wild Steelbloom, Stranglekelp, Kingsblood (125), Liferoot (150)" },
            { "170-205", nil, "Kingsblood, Liferoot, Fadeleaf, Goldthorn, Khadgar's Whisker (185)" },
            { "205-270", nil, "Purple Lotus, Firebloom, Sungrass, Golden Sansam, Ghost Mushroom (245)" },
            { "270-300", nil, "Sungrass, Gromsblood, Golden Sansam, Dreamfoil, Mountain Silversage, Plaguebloom" },
        } },
        { title = "About this guide", notes = {
            "Routes were tested on the Forever beta with the level cap at 30 and without a mount. Higher routes follow standard Classic routes and are unverified.",
            "Content from wow-professions.com. See the full guide and its route maps there.",
        } },
    },
}
