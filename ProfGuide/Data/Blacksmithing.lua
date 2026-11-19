local _, addon = ...
-- Source: https://www.wow-professions.com/forever/blacksmithing-leveling-guide (Forever beta).
-- The 270-300 range comes from game-file data upstream and is untested; shopping totals are estimates.
local S = addon.Step

addon.guides.blacksmithing = {
    name = "Blacksmithing",
    skillLine = 164,
    icon = "Interface\\Icons\\Trade_BlackSmithing",
    max = 300,
    intro = "Level alongside Mining. Buy a Blacksmith Hammer (item 5956) when you learn the profession: most recipes need it, and it costs a few copper.",
    tiers = {
        { name = "Apprentice", from = 1, to = 75, requires = "No level requirement. Every capital except Darnassus has a trainer.", steps = {
            S(1, 25, 30, "Rough Sharpening Stone", { { 30, "Rough Stone" } }),
            S(25, 50, 30, "Rough Grinding Stone", { { 60, "Rough Stone" } }, "Keep 10 of them for the Silver Rods at 75."),
            S(50, 75, 36, "Coarse Grinding Stone", { { 72, "Coarse Stone" } },
                "Make all 36: you need them for the Patterned Bronze Bracers at 95 and 112. If you are not at 75 after these, make a few more."),
        } },
        { name = "Journeyman", from = 75, to = 150, requires = "Requires Blacksmithing 50 and character level 10.", steps = {
            S(75, 80, 5, "Silver Rod", { { 5, "Silver Bar" }, { 10, "Rough Grinding Stone" } },
                "A Blacksmith Hammer is needed from here on.",
                { "If one Silver Bar costs more than 10 Copper Bar, make 5x Runed Copper Belt instead (10 Copper Bar each)." }),
            S(80, 95, 18, "Runed Copper Belt", { { 180, "Copper Bar" } }),
            S(95, 100, 5, "Patterned Bronze Bracers", { { 25, "Bronze Bar" }, { 10, "Coarse Grinding Stone" } },
                "Use 10 of the Coarse Grinding Stones from the 50-75 step; keep 26 for 112."),
            S(100, 112, 20, "Heavy Grinding Stone", { { 60, "Heavy Stone" } }, "Keep all 20 for Golden Scale Bracers at 180."),
            S(112, 125, 13, "Patterned Bronze Bracers", { { 65, "Bronze Bar" }, { 26, "Coarse Grinding Stone" } }),
            S(125, 140, 24, "Bronze Shortsword", { { 120, "Bronze Bar" }, { 96, "Weak Flux" }, { 48, "Medium Leather" } },
                "Recommended over the bracers: they sell to vendors for more than twice as much.",
                { "If you disenchant greens: 24x Patterned Bronze Bracers - 120 Bronze Bar, 48 Coarse Grinding Stone." }),
            S(140, 150, 10, "Bronze Warhammer", { { 80, "Bronze Bar" }, { 10, "Strong Flux" }, { 10, "Medium Leather" } },
                "Weak and Strong Flux come from the Blacksmithing Supply vendor next to the trainer in every capital."),
        } },
        { name = "Expert", from = 150, to = 215, requires = "Requires Blacksmithing 125 and character level 20. Costs 50 silver.", steps = {
            S(150, 175, 30, "Green Iron Bracers", { { 180, "Iron Bar" }, { 30, "Green Dye" } },
                "Green Dye is sold by Tamar (Orgrimmar) and Bombus Finespindle (Ironforge)."),
            S(175, 180, 8, "Solid Grinding Stone", { { 32, "Solid Stone" } }, "Keep all: 6 are needed for Heavy Mithril Axe at 210."),
            S(180, 195, 20, "Golden Scale Bracers", { { 100, "Steel Bar" }, { 20, "Heavy Grinding Stone" }, { 60, "Heavy Stone" } },
                "You need 40 Heavy Grinding Stones: use the 20 from the 100-112 step and make 20 more (60 Heavy Stone). Alliance players should keep 6 Golden Scale Bracers in case they choose Armorsmithing.",
                { "With Mining 165 you can smelt Steel Bar yourself from Iron Bar and Coal. Coal is sold by the Blacksmithing Supply vendor." }),
            S(195, 210, 17, "Mithril Plate Pants", { { 204, "Mithril Bar" } },
                "Recommended over Heavy Mithril Gauntlets (vendor value is more than three times as high)."),
            S(210, 215, 6, "Heavy Mithril Axe",
                { { 72, "Mithril Bar" }, { 12, "Citrine" }, { 6, "Solid Grinding Stone" }, { 24, "Heavy Leather" } },
                "Keep 2 in case you choose Weaponsmithing."),
        } },
        { name = "Artisan", from = 215, to = 300, requires = "Requires Blacksmithing 200 and character level 35.", steps = {
            S(215, 225, 10, "Heavy Mithril Breastplate", { { 160, "Mithril Bar" } }, "Keep 2 for Armorsmithing.",
                { "Plans: Mithril Spurs (item 7989) is a world drop, found on the Auction House. With it, make 10x Mithril Spurs - 40 Mithril Bar, 30 Solid Grinding Stone (120 Solid Stone)." }),
            S(225, 230, 5, "Dense Sharpening Stone", { { 5, "Dense Stone" } }),
            S(230, 240, 16, "Heavy Mithril Boots", { { 224, "Mithril Bar" }, { 64, "Thick Leather" } }, "Keep 2 for Armorsmithing.",
                { "With the Mithril Spurs plans: 16x Mithril Spurs - 64 Mithril Bar, 48 Solid Grinding Stone (192 Solid Stone)." }),
            S(240, 245, 5, "Imperial Plate Belt", { { 110, "Thorium Bar" }, { 30, "Rugged Leather" }, { 5, "Aquamarine" } },
                "Recipe from the Imperial Plate Belt quest (7653) in Tanaris, from Derotain Mudsipper. The quest needs level 50 and 20 Thorium Bar. He also has the next three recipes, so bring at least 250 Thorium Bar for 5 belts and all 4 recipes.",
                { "World-drop plans let you start at 240 instead (240-255 each): 27x Dazzling Mithril Rapier - 378 Mithril Bar, 27 Aquamarine, 54 Lesser Moonstone, 54 Moss Agate, 27 Solid Grinding Stone, 54 Mageweave Cloth.",
                  "20x Runed Mithril Hammer - 360 Mithril Bar, 40 Core of Earth, 20 Solid Grinding Stone, 80 Thick Leather.",
                  "17x Thorium Bracers - 204 Thorium Bar, 68 Blue Power Crystal." }),
            S(245, 270, 27, "Imperial Plate Bracers", { { 540, "Thorium Bar" }, { 27, "Star Ruby" } },
                "Recipe from the Imperial Plate Bracer quest (7655), which needs 20 Thorium Bar."),
            S(270, 290, 20, "Imperial Plate Boots", { { 680, "Thorium Bar" }, { 20, "Star Ruby" }, { 20, "Aquamarine" } },
                "Recipe from the Imperial Plate Boots quest (7654), which needs 40 Thorium Bar. Untested on the beta: this range relies on game-file data."),
            S(290, 300, 10, "Imperial Plate Leggings", { { 440, "Thorium Bar" }, { 20, "Star Ruby" } },
                "Recipe from the Imperial Plate Leggings quest (7658), which needs 60 Thorium Bar. More recipes may exist, but these are the only ones found for 270-300."),
        } },
    },
    -- Estimates: yellow recipes may need a few more or fewer. vendor = sold by a vendor.
    shopping = {
        { range = "1-150", from = 1, to = 150, items = {
            { 90, "Rough Stone" }, { 180, "Copper Bar" }, { 5, "Silver Bar" }, { 72, "Coarse Stone" }, { 290, "Bronze Bar" },
            { 60, "Heavy Stone" }, { 58, "Medium Leather" }, { 96, "Weak Flux", "Vendor" }, { 10, "Strong Flux", "Vendor" } } },
        { range = "150-225", from = 150, to = 225, items = {
            { 180, "Iron Bar" }, { 30, "Green Dye", "Vendor" }, { 32, "Solid Stone" },
            { 100, "Steel Bar", "Or 100 Iron Bar + 100 Coal if you have Mining 165." }, { 60, "Heavy Stone" },
            { 436, "Mithril Bar" }, { 24, "Heavy Leather" }, { 12, "Citrine" } } },
        { range = "225-300", from = 225, to = 300, items = {
            { 5, "Dense Stone" }, { 224, "Mithril Bar" }, { 64, "Thick Leather" },
            { 1910, "Thorium Bar", "Includes the 140 needed for the four Imperial Plate quests." },
            { 30, "Rugged Leather" }, { 67, "Star Ruby" }, { 25, "Aquamarine" } } },
    },
    -- NPC name -> { uiMapID, x, y } in percent. Approximate town-level spots, not exact NPC positions.
    -- Skipped: NPCs whose spot is unknown or that appear in two places (Thrag Stonehoof, Daeann Steelwind, ...).
    pins = (function()
        local orgrimmar, stormwind, ironforge = { 1637, 80, 32 }, { 1453, 63.5, 37.5 }, { 1455, 50.5, 42.5 }
        local razorHill, goldshire, kharanos, auberdine = { 1411, 52.5, 43 }, { 1429, 41, 66 }, { 1426, 46, 52 }, { 1439, 37, 41 }
        return {
            ["Ug'thok"] = orgrimmar, ["Sumi"] = orgrimmar, ["Snarl"] = orgrimmar, ["Saru Steelfury"] = orgrimmar,
            ["Dane Lindgren"] = stormwind, ["Kaita Deepforge"] = stormwind, ["Therum Deepforge"] = stormwind,
            ["Groum Stonebeard"] = ironforge, ["Thurgrum Deepforge"] = ironforge, ["Rotgath Stonebeard"] = ironforge,
            ["Bengus Deepforge"] = ironforge, ["Dwukk"] = razorHill, ["Flakk"] = razorHill,
            ["Smith Argus"] = goldshire, ["Tharynn Bouden"] = goldshire, ["Tognus Flintfire"] = kharanos,
            ["Thrawn Boltar"] = kharanos, ["Delfrum Flintbeard"] = auberdine, ["Elisa Steelhand"] = auberdine,
            ["Brikk Keencraft"] = { 1434, 27, 77 },
        }
    end)(),
    trainers = {
        { title = "Apprentice (1-75)", groups = {
            { "Capital cities - Horde", {
                { "Ug'thok", "Orgrimmar" }, { "Basil Frye", "Undercity" }, { "Thrag Stonehoof", "Thunder Bluff" } } },
            { "Capital cities - Alliance", {
                { "Dane Lindgren", "Stormwind City" }, { "Groum Stonebeard", "Ironforge" },
                { "No trainer", "Darnassus has none: see Teldrassil below." } } },
            { "Starting zones - Horde", {
                { "Dwukk", "Durotar (Orc, Troll): the forge in Razor Hill." },
                { "Thrag Stonehoof", "Mulgore (Tauren): no trainer in Mulgore, use the lower rise in Thunder Bluff." },
                { "Angus Hammerhand", "Tirisfal Glades (Undead): Bandarion Keep. Nobody nearby sells a Blacksmith Hammer, buy one first." },
                { "Daeann Steelwind", "Zephras Isle (Skyborne): Valanaar. Or Aedi Thriceforged in Shen'dar Village." } } },
            { "Starting zones - Alliance", {
                { "Smith Argus", "Elwynn Forest (Human): Goldshire, across from the inn." },
                { "Tognus Flintfire", "Dun Morogh (Dwarf, Gnome): Kharanos, across from the Thunderbrew Distillery." },
                { "Delfrum Flintbeard", "Teldrassil (Night Elf): none in Teldrassil or Darnassus, the closest is Auberdine, Darkshore." },
                { "Daeann Steelwind", "Zephras Isle (Skyborne): Valanaar. Or Aedi Thriceforged in Shen'dar Village." } } },
        } },
        { title = "Blacksmith Hammer vendors (item 5956)", groups = {
            { "Horde", {
                { "Sumi", "Orgrimmar: next to the trainer." }, { "Samuel Van Brunt", "Undercity: next to the trainer." },
                { "Taur Stonehoof", "Thunder Bluff: next to the trainer." }, { "Flakk", "Durotar: Razor Hill." },
                { "Walter Mason", "Tirisfal Glades: Deathknell. Or Abigail Shiel in Brill." },
                { "Halavuul Cragwind", "Zephras Isle: the Mining trainer in Valanaar. Or Aedi Thriceforged in Shen'dar Village." } } },
            { "Alliance", {
                { "Kaita Deepforge", "Stormwind City: next to the trainer." }, { "Thurgrum Deepforge", "Ironforge: next to the trainer." },
                { "Tharynn Bouden", "Elwynn Forest: Goldshire." }, { "Thrawn Boltar", "Dun Morogh: next to the trainer." },
                { "Elisa Steelhand", "Darkshore: Auberdine, next to the trainer." },
                { "Halavuul Cragwind", "Zephras Isle: same as the Horde entry." } } },
        } },
        { title = "Journeyman, Expert and Artisan", groups = {
            { "Journeyman (75-150) - Horde", {
                { "Snarl", "Orgrimmar" }, { "James Van Brunt", "Undercity" }, { "Karn Stonehoof", "Thunder Bluff" },
                { "Angus Hammerhand", "Tirisfal Glades: Bandarion Keep." }, { "Daeann Steelwind", "Zephras Isle: Valanaar." } } },
            { "Journeyman (75-150) - Alliance", {
                { "Therum Deepforge", "Stormwind City" }, { "Rotgath Stonebeard", "Ironforge" },
                { "Daeann Steelwind", "Zephras Isle: Valanaar." } } },
            { "Expert (150-215) - 50 silver", {
                { "Saru Steelfury", "Orgrimmar (Horde)" }, { "Bengus Deepforge", "Ironforge (Alliance)" } } },
            { "Artisan (215-300)", {
                { "Brikk Keencraft", "Booty Bay, Stranglethorn Vale (both factions)" } } },
        } },
    },
    -- How each rank is learned (Extras). Pins: Classic map IDs, approximate town-level spots.
    ranks = (function()
        local R = addon.Rank
        return {
            R("Apprentice (1-75)", "Trainer", "Any Blacksmithing trainer, no level requirement (see Trainers)."),
            R("Journeyman (75-150)", "Trainer", "A capital-city trainer: Blacksmithing 50 and level 10."),
            R("Expert (150-225)", "Trainer", "Saru Steelfury (Orgrimmar, Horde) or Bengus Deepforge (Ironforge, Alliance): Blacksmithing 125, level 20, 50 silver.",
                { 1637, 80, 32 }, { 1455, 50.5, 42.5 }),
            R("Artisan (225-300)", "Trainer", "Brikk Keencraft, Booty Bay, Stranglethorn Vale (both factions): Blacksmithing 200, level 35.", { 1434, 27, 77 }),
        }
    end)(),
    extras = {
        { title = "Specializations", notes = { "At Blacksmithing 200 and character level 40 you can choose Armorsmithing or Weaponsmithing. It is optional and can be done later. Keep the pieces the leveling steps mention (Golden Scale Bracers, Heavy Mithril Breastplate and Boots for Armorsmithing, Heavy Mithril Axe for Weaponsmithing) in case you choose one." } },
        { title = "Imperial Plate quests", notes = { "Thorium Bar needed in total: 140 (included in the shopping list)." }, rows = {
            { "Imperial Plate Belt", "Quest 7653", "Level 50 - 20 Thorium Bar. Derotain Mudsipper, Tanaris. Unlocks the belt (240-245) and he has the next three recipes." },
            { "Imperial Plate Bracers", "Quest 7655", "20 Thorium Bar. Unlocks the bracers (245-270)." },
            { "Imperial Plate Boots", "Quest 7654", "40 Thorium Bar. Unlocks the boots (270-290)." },
            { "Imperial Plate Leggings", "Quest 7658", "60 Thorium Bar. Unlocks the leggings (290-300)." },
        } },
        { title = "About this guide", notes = {
            "This guide is based on the Forever beta.",
            "In Classic these quests need Blacksmithing 265. Forever lowered the belt to 240; the author assumes the quests were lowered too, but this is untested.",
            "The 270-300 section relies on game-file data because the author could not level that far on the beta. There may be recipes not yet discovered.",
            "Material totals are estimates: yellow recipes may need a few more or fewer.",
            "Content from wow-professions.com. See the full guide, the specialization guides and the trainer list there.",
        } },
    },
}
