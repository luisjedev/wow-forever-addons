local _, addon = ...
-- Source: https://www.wow-professions.com/forever/leatherworking-leveling-guide (Forever beta).
-- Shopping totals are step sums grouped by each step's starting skill; the page's own ranged figures differ.
local S = addon.Step

addon.guides.leatherworking = {
    name = "Leatherworking",
    skillLine = 165,
    icon = "Interface\\Icons\\Trade_LeatherWorking",
    max = 300,
    intro = "Cheapest recipe per skill range from Apprentice to Artisan. Leather is most of the cost, so Skinning helps, but everything can be bought on the Auction House. Most trainers have a Leatherworking Supply vendor nearby for thread, dye and salt.",
    tiers = {
        { name = "Apprentice", from = 1, to = 55, requires = "No level requirement.", steps = {
            S(1, 30, 35, "Light Leather", { { 105, "Ruined Leather Scraps" } }),
            S(30, 55, 27, "Cured Light Hide", { { 27, "Light Hide" }, { 27, "Salt", "Vendor" } }, "Keep 24 hides for Light Leather Pants at 100.",
                { "Light Armor Kits to 45 (24x, 24 Light Leather), then Embossed Leather Gloves to 55 (10x, 30 Light Leather, 20 Coarse Thread)." }),
        } },
        { name = "Journeyman", from = 55, to = 130, requires = "Leatherworking 50 and level 10 (needed to train past 75).", steps = {
            S(55, 75, 21, "Embossed Leather Gloves", { { 63, "Light Leather" }, { 42, "Coarse Thread", "Vendor" } }),
            S(75, 80, 8, "Medium Leather", { { 32, "Light Leather" } }),
            S(80, 90, 10, "Cured Medium Hide", { { 10, "Medium Hide" }, { 10, "Salt", "Vendor" } }, "Keep these for Dark Leather Belts at 115."),
            S(90, 100, 19, "Fine Leather Belt", { { 114, "Light Leather" }, { 38, "Coarse Thread", "Vendor" } }, "Keep 10 belts for Dark Leather Belts at 115."),
            S(100, 115, 24, "Light Leather Pants", { { 240, "Light Leather" }, { 24, "Cured Light Hide" }, { 24, "Fine Thread", "Vendor" } }),
            S(115, 125, 10, "Dark Leather Belt", { { 10, "Fine Leather Belt" }, { 10, "Cured Medium Hide" }, { 20, "Fine Thread", "Vendor" }, { 10, "Gray Dye", "Vendor" } }),
            S(125, 130, 7, "Heavy Leather", { { 35, "Medium Leather" } }),
        } },
        { name = "Expert", from = 130, to = 205, requires = "Leatherworking 125 and level 20; costs 50 silver (needed to train past 150).", steps = {
            S(130, 143, 30, "Cured Heavy Hide", { { 30, "Heavy Hide" }, { 90, "Salt", "Vendor" } }, "Keep 10 for Barbaric Shoulders at 155 and 20 for Guardian Gloves at 165."),
            S(143, 155, 17, "Hillman's Leather Gloves", { { 238, "Medium Leather" }, { 68, "Fine Thread", "Vendor" } }),
            S(155, 165, 10, "Barbaric Shoulders", { { 80, "Heavy Leather" }, { 10, "Cured Heavy Hide" }, { 20, "Fine Thread", "Vendor" } }),
            S(165, 185, 20, "Guardian Gloves", { { 80, "Heavy Leather" }, { 20, "Cured Heavy Hide" }, { 20, "Silken Thread", "Vendor" } }),
            S(185, 205, 22, "Nightscape Headband", { { 110, "Thick Leather" }, { 44, "Silken Thread", "Vendor" } }),
        } },
        { name = "Artisan", from = 205, to = 300, requires = "Leatherworking 200 and level 35 (needed to train past 225).", steps = {
            S(205, 235, 36, "Nightscape Pants", { { 504, "Thick Leather" }, { 144, "Silken Thread", "Vendor" } }, "Only the Artisan trainers teach it. Better vendor price than Nightscape Boots."),
            S(235, 265, 36, "Wicked Leather Gauntlets", { { 288, "Rugged Leather" }, { 36, "Black Dye", "Vendor" }, { 36, "Rune Thread", "Vendor" } },
                "Pattern sold by Werg Thickblade (Tirisfal Glades) or Leonard Porter (Western Plaguelands).",
                { "36x Blue Suede Shoes - 288 Rugged Leather, 36 Blue Dye, 36 Rune Thread. Better vendor price; use it if the pattern costs less than about 13 gold more." }),
            S(265, 300, 53, "Runic Leather Headband", { { 742, "Rugged Leather" }, { 530, "Runecloth" }, { 53, "Rune Thread", "Vendor" } },
                "Pattern sold by Jase Farlane, Light's Hope Chapel.",
                { "From 275: 27x Blue Suede Bracers - 270 Rugged Leather, 27 Blue Dye, 27 Rune Thread.",
                  "From 280: 20x Blue Suede Hat - 320 Rugged Leather, 80 Blue Dye, 20 Rune Thread. Needs a Sewing Machine placed by a 300 Leatherworker." }),
        } },
    },
    shopping = {
        { range = "1-150", from = 1, to = 150, items = {
            { 105, "Ruined Leather Scraps" }, { 27, "Light Hide" }, { 449, "Light Leather" }, { 273, "Medium Leather" }, { 10, "Medium Hide" },
            { 30, "Heavy Hide" }, { 127, "Salt", "Vendor" }, { 80, "Coarse Thread", "Vendor" }, { 112, "Fine Thread", "Vendor" }, { 10, "Gray Dye", "Vendor" } } },
        { range = "150-225", from = 150, to = 225, items = {
            { 160, "Heavy Leather" }, { 20, "Fine Thread", "Vendor" }, { 208, "Silken Thread", "Vendor" }, { 614, "Thick Leather" } } },
        { range = "225-300", from = 225, to = 300, items = {
            { 1030, "Rugged Leather" }, { 36, "Black Dye", "Vendor" }, { 89, "Rune Thread", "Vendor" }, { 530, "Runecloth" } } },
    },
    trainers = {
        { title = "Apprentice", groups = {
            { "Horde", { { "Kamari", "Orgrimmar, the Drag; closest for Durotar" }, { "Dan Golthas", "Undercity" }, { "Mak", "Thunder Bluff" },
                { "Chaw Stronghide", "Bloodhoof Village, Mulgore" }, { "Shelene Rhobart", "Road junction south-east of Brill, Tirisfal Glades" } } },
            { "Alliance", { { "Randal Worth", "Stormwind City" }, { "Gretta Finespindle", "Ironforge, Great Forge; closest for Dun Morogh" }, { "Darianna", "Darnassus" },
                { "Adele Fielder", "Small house by Crystal Lake, north-east of Goldshire, Elwynn Forest" }, { "Nadyia Maneweaver", "Small house near the road to Darnassus, Teldrassil" } } },
            { "Skyborne", { { "Emerii Tallgust", "Valanaar, Zephras Isle" }, { "Indari Sunseam", "Shen'dar Village, Zephras Isle" } } },
        } },
        { title = "Journeyman", groups = {
            { "Horde", { { "Karolek", "Orgrimmar" }, { "Arthur Moore", "Undercity" }, { "Tarn", "Thunder Bluff" } } },
            { "Alliance", { { "Simon Tanner", "Stormwind City" }, { "Fimble Finespindle", "Ironforge" }, { "Faldron", "Darnassus" } } },
        } },
        { title = "Expert and Artisan", groups = {
            { "Expert (130-205)", { { "Una", "Thunder Bluff (Horde)" }, { "Telonis", "Darnassus (Alliance)" } } },
            { "Artisan (205-300)", { { "Hahrana Ironhide", "Camp Mojache, Feralas (Horde)" }, { "Drakk Stonehand", "Aerie Peak, The Hinterlands (Alliance)" } } },
        } },
    },
    -- How each rank is learned (Extras). Pins: Classic map IDs, approximate town-level spots.
    ranks = (function()
        local R = addon.Rank
        return {
            R("Apprentice (1-75)", "Trainer", "Any Leatherworking trainer, no level requirement (see Trainers)."),
            R("Journeyman (75-150)", "Trainer", "A capital-city trainer: Leatherworking 50 and level 10."),
            R("Expert (150-225)", "Trainer", "Una (Thunder Bluff, Horde) or Telonis (Darnassus, Alliance): Leatherworking 125, level 20, 50 silver."),
            R("Artisan (225-300)", "Trainer", "Hahrana Ironhide (Camp Mojache, Feralas, Horde) or Drakk Stonehand (Aerie Peak, The Hinterlands, Alliance): Leatherworking 200, level 35.",
                { 1444, 74.5, 43 }, { 1425, 13.5, 43.5 }),
        }
    end)(),
    extras = {
        { title = "Specializations", notes = { "At Leatherworking 225 and level 40 you can choose one specialization. Each unlocks its own patterns." }, rows = {
            { "Dragonscale", nil, "Mail gear." },
            { "Elemental", nil, "Elemental resistance and agility leather gear." },
            { "Tribal", nil, "Intellect and agility leather gear, and the Devilsaur Armor set." },
        } },
        { title = "Notes", notes = {
            "No supply vendor near the Elwynn Forest and Tirisfal Glades trainers: buy Salt and Coarse Thread from Tharynn Bouden (Goldshire) or Abigail Shiel (Brill).",
            "You cannot place a Sewing Machine yourself before 300; a Leatherworker at 300 has to place it.",
            "Counts are estimates: yellow and green recipes do not always give a point.",
            "This guide is based on the Forever beta; higher levels are untested on live.",
            "Content from wow-professions.com. See the full guide there.",
        } },
    },
}
