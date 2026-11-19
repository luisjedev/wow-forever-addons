local _, addon = ...
-- Source: https://www.wow-professions.com/forever/enchanting-leveling-guide (Forever beta). Shopping totals are estimates.
-- 70-150 follows the Strange Dust route (matches the page's shopping list); the Lesser Magic Essence route is in extras.
local S = addon.Step

addon.guides.enchanting = {
    name = "Enchanting",
    skillLine = 333,
    icon = "Interface\\Icons\\Trade_Engraving",
    max = 300,
    intro = "Enchanting 1-300 for WoW Forever (beta). Shopping counts are estimates: once a recipe turns yellow you may need a few more or fewer crafts. The 70-150 steps use the Strange Dust route; the Lesser Magic Essence route is in Extras.",
    tiers = {
        { name = "Apprentice", from = 1, to = 70, requires = "No level requirement; learn Apprentice Enchanting from a capital or starting-zone trainer.", steps = {
            S(1, 2, 1, "Runed Copper Rod", { { 1, "Copper Rod", "Vendor" }, { 1, "Mote of Magic", "Vendor" } }, "Buy from the Enchanting Supply vendor by your trainer, not the Auction House."),
            S(2, 20, 18, "Enchant Bracer - Inferior Stamina", { { 18, "Mote of Magic", "Vendor" } }, "In starting zones only the Zephras Isle and Brill trainers sell Mote of Magic."),
            S(20, 70, 50, "Enchant Chest - Inferior Stamina", { { 50, "Strange Dust" } }, nil, { "50x Enchant Bracer - Minor Deflect (50 Lesser Magic Essence)" }),
        } },
        { name = "Journeyman", from = 70, to = 150, requires = "Enchanting 50 and level 10 to train Journeyman Enchanting (needed past 75).", steps = {
            S(70, 85, 23, "Enchant Chest - Inferior Stamina", { { 23, "Strange Dust" } }),
            S(85, 100, 15, "Enchant Bracer - Minor Stamina", { { 30, "Strange Dust" } }),
            S(100, 109, 9, "Enchant Cloak - Minor Protection", { { 18, "Strange Dust" } }),
            S(109, 110, 1, "Runed Silver Rod", { { 1, "Silver Rod" }, { 3, "Strange Dust" }, { 4, "Lesser Magic Essence" }, { 1, "Shadowgem" } }, "Silver Rod is made by Blacksmiths; buy it on the Auction House."),
            S(110, 130, 32, "Enchant Cloak - Minor Protection", { { 64, "Strange Dust" } }),
            S(130, 150, 20, "Enchant Boots - Minor Stamina", { { 80, "Strange Dust" } }, nil, { "20x Enchant Bracer - Lesser Stamina (20 Soul Dust), if 20 Soul Dust costs less than 80 Strange Dust." }),
        } },
        { name = "Expert", from = 150, to = 225, requires = "Enchanting 125 and level 20; costs 50 silver. Expert trainers only teach up to 225.", steps = {
            S(150, 151, 1, "Runed Golden Rod", { { 1, "Golden Rod" }, { 1, "Iridescent Pearl" }, { 1, "Greater Astral Essence" }, { 1, "Soul Dust" } }),
            S(151, 165, 16, "Minor Mana Oil", { { 16, "Soul Dust" }, { 32, "Maple Seed", "Vendor" }, { 16, "Leaded Vial", "Vendor" } }, "Needs Formula: Minor Mana Oil (vendors in Extras)."),
            S(165, 200, 47, "Enchant Boots - Lesser Agility", { { 47, "Soul Dust" } }, nil,
                { "Stop boots at 185, then make 15x Enchant Bracer - Strength (15 Vision Dust) until 200, if 2 Vision Dust costs less than 3 Soul Dust." }),
            S(200, 201, 1, "Runed Truesilver Rod", { { 1, "Truesilver Rod" }, { 1, "Black Pearl" }, { 1, "Greater Mystic Essence" }, { 1, "Vision Dust" } }),
            S(201, 220, 25, "Lesser Wizard Oil", { { 25, "Vision Dust" }, { 50, "Stranglethorn Seed", "Vendor" }, { 25, "Leaded Vial", "Vendor" } }, "Needs Formula: Lesser Wizard Oil (vendors in Extras)."),
            S(220, 225, 5, "Enchant Cloak - Greater Defense", { { 5, "Vision Dust" } }),
        } },
        { name = "Artisan", from = 225, to = 300, requires = "Enchanting 200 and level 35; learn Artisan Enchanting from Annora in Uldaman.", steps = {
            S(225, 250, 37, "Enchant Gloves - Agility", { { 37, "Vision Dust" } }),
            S(250, 265, 20, "Lesser Mana Oil", { { 20, "Dream Dust" }, { 20, "Purple Lotus" }, { 20, "Crystal Vial", "Vendor" } }, "Needs Formula: Lesser Mana Oil from Kania (Silithus).",
                { "Enchant Bracer - Greater Strength (1 Dream Dust, 2 Lesser Nether Essence each) if you have no Purple Lotus." }),
            S(265, 299, 40, "Enchant Shield - Greater Stamina", { { 240, "Dream Dust" } }, "Formula is bind on pickup: Daniel Bartlett (Undercity) or Mythrin'dir (Darnassus)."),
            S(299, 300, 1, "Runed Arcanite Rod", { { 1, "Arcanite Rod" }, { 1, "Golden Pearl" }, { 10, "Illusion Dust" }, { 4, "Greater Eternal Essence" }, { 4, "Small Brilliant Shard" }, { 2, "Large Brilliant Shard" } },
                "Formula from Lorelae Wintersong (Moonglade, Nighthaven); needed for most 300 recipes.",
                { "Make one more Enchant Shield - Greater Stamina for the last point if you don't need the rod yet." }),
        } },
    },
    shopping = {
        { range = "1-150", from = 1, to = 150, items = { { 19, "Mote of Magic", "Vendor" }, { 1, "Copper Rod", "Vendor" }, { 268, "Strange Dust" },
            { 1, "Silver Rod" }, { 1, "Shadowgem" }, { 4, "Lesser Magic Essence" } } },
        { range = "150-225", from = 150, to = 225, items = { { 1, "Golden Rod" }, { 1, "Iridescent Pearl" }, { 1, "Greater Astral Essence" }, { 64, "Soul Dust" },
            { 32, "Maple Seed", "Vendor" }, { 41, "Leaded Vial", "Vendor" }, { 31, "Vision Dust" }, { 1, "Truesilver Rod" }, { 1, "Black Pearl" },
            { 1, "Greater Mystic Essence" }, { 50, "Stranglethorn Seed", "Vendor" } } },
        { range = "225-300", from = 225, to = 300, items = { { 37, "Vision Dust" }, { 260, "Dream Dust" }, { 20, "Purple Lotus" }, { 20, "Crystal Vial", "Vendor" },
            { 1, "Arcanite Rod" }, { 1, "Golden Pearl" }, { 10, "Illusion Dust" }, { 4, "Greater Eternal Essence" }, { 4, "Small Brilliant Shard" }, { 2, "Large Brilliant Shard" } } },
    },
    trainers = {
        { title = "Apprentice", groups = {
            { "Horde", { { "Jhag", "Orgrimmar" }, { "Malcomb Wynn", "Undercity" }, { "Mot Dawnstrider", "Thunder Bluff; closest for Mulgore, middle rise" },
                { "Pa'zula", "Sen'jin Village, Durotar" }, { "Vance Undergloom", "Upstairs in the inn in Brill, Tirisfal Glades" } } },
            { "Alliance", { { "Betty Quin", "Stormwind City, Mage Quarter; closest for Elwynn Forest" }, { "Thonys Pillarstone", "Ironforge, Great Forge; closest for Dun Morogh" },
                { "Lalina Summermoon", "Darnassus" }, { "Alanna Raveneye", "Oracle Glade, north-west Teldrassil" } } },
            { "Skyborne", { { "Eaysaa Brightgust", "Valanaar, Zephras Isle" }, { "Nasalanna Windsinger", "Shen'dar Village, Zephras Isle" } } },
        } },
        { title = "Journeyman", groups = {
            { "Horde", { { "Godan", "Orgrimmar" }, { "Lavinia Crowe", "Undercity" }, { "Teg Dawnstrider", "Thunder Bluff" } } },
            { "Alliance", { { "Lucan Cordell", "Stormwind City" }, { "Gimble Thistlefuzz", "Ironforge" }, { "Taladan", "Darnassus" } } },
        } },
        { title = "Expert and Artisan", groups = {
            { "Expert (150-225)", { { "Hgarth", "Stonetalon Mountains, Sun Rock Retreat, hill above the village (Horde)" },
                { "Kitta Firewind", "Elwynn Forest, top of the Tower of Azora (Alliance)" } } },
            { "Artisan (225-300)", { { "Annora", "Uldaman (Badlands), back entrance; appears only after every mob in her area is killed" } } },
        } },
    },
    -- How each rank is learned (Extras). Pins: Classic map IDs, approximate town-level spots.
    ranks = (function()
        local R = addon.Rank
        return {
            R("Apprentice (1-75)", "Trainer", "Any Enchanting trainer, no level requirement (see Trainers)."),
            R("Journeyman (75-150)", "Trainer", "A capital-city trainer: Enchanting 50 and level 10."),
            R("Expert (150-225)", "Trainer", "Hgarth (Sun Rock Retreat, Stonetalon Mountains, Horde) or Kitta Firewind (Tower of Azora, Elwynn Forest, Alliance): Enchanting 125, level 20, 50 silver.",
                { 1442, 47, 61 }, { 1429, 65, 69.5 }),
            R("Artisan (225-300)", "Trainer", "Annora, inside Uldaman (Badlands), back entrance; she appears once every mob in her area is dead. Enchanting 200, level 35. No map pin: she is in the dungeon."),
        }
    end)(),
    extras = {
        { title = "Disenchanting and macro", notes = {
            "Disenchant comes with Apprentice Enchanting. It is not in your spellbook: it is in the Enchanting box of the Professions window.",
            "Craft macro (two lines): /run ProfessionsFrame.CraftingPage.CreateButton:Click() and /run StaticPopup1Button1:Click(). Select the enchant, put the item in the optional target slot, then press the macro repeatedly.",
        } },
        { title = "Lesser Magic Essence route (70-150)", notes = { "Alternative to the Strange Dust route. Greater Magic Essence can be right-clicked into 3 Lesser Magic Essence." }, rows = {
            { "49x Enchant Chest - Minor Absorption", "70-109", "49 Lesser Magic Essence" },
            { "23x Greater Magic Wand", "110-125", "23 Simple Wood, 46 Lesser Magic Essence" },
            { "37x Enchant 2H Weapon - Lesser Intellect", "125-150", "148 Lesser Magic Essence. Formula: Kithas (Orgrimmar), Nata Dawnstrider (Thunder Bluff), Leo Sarn (Silverpine Forest), Tilli Thistlefuzz (Ironforge)." },
            { "25x Enchant Boots - Minor Stamina", "125-150", "100 Strange Dust, if you skip the formula." },
        } },
        { title = "Formulas and vendors", rows = {
            { "Minor Mana Oil, Lesser Wizard Oil", nil, "Kithas (Orgrimmar), Nata Dawnstrider (Thunder Bluff), Thaddeus Webb (Undercity), Vaean (Darnassus), Tilli Thistlefuzz (Ironforge), Jessara Cordell (Stormwind City)." },
            { "Lesser Mana Oil", nil, "Kania, upstairs in the inn in Silithus." },
            { "Enchant Shield - Greater Stamina", "BoP", "Daniel Bartlett (Undercity) or Mythrin'dir (Darnassus). Do not buy it on an alt." },
            { "Runed Arcanite Rod", nil, "Lorelae Wintersong, Nighthaven, Moonglade." },
            { "Copper Rod, Mote of Magic", nil, "Enchanting Supply vendor by your trainer." },
            { "Vials and seeds", nil, "Leaded and Crystal Vial: Alchemy Supply vendors (Crystal Vial also Mishta, Silithus). Maple and Stranglethorn Seed: reagent vendors." },
        } },
        { title = "Annora's recipes (Uldaman)", notes = {
            "Learn everything from Annora before you leave Uldaman: recipes from 230 up are taught nowhere else. Bring about 50 Vision Dust to reach 250. You cannot solo Uldaman at 35.",
        }, rows = {
            { "Enchant Chest - Superior Intellect", "230" }, { "Enchant Shield - Greater Spirit", "230" }, { "Enchant Boots - Agility", "235" },
            { "Enchant 2H Weapon - Greater Impact", "240" }, { "Enchant Bracer - Greater Strength", "240" }, { "Enchant Chest - Stats", "245" },
            { "Enchant Weapon - Greater Striking", "245" }, { "Enchant Gloves - Minor Haste", "250" }, { "Enchanted Leather, Enchanted Thorium", "250" },
        } },
        { title = "About this guide", notes = {
            "This guide is based on the Forever beta; higher levels are untested on live.",
            "Forever added new low-level recipes, so the first 70 points are cheaper than in Classic.",
            "Enchanting pairs well with Tailoring: neither needs a gathering profession, and you can disenchant what you sew.",
            "Content from wow-professions.com. See the full guide there.",
        } },
    },
}
