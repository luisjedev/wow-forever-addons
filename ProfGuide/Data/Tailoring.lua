local _, addon = ...
-- Source: https://www.wow-professions.com/forever/tailoring-leveling-guide (Forever beta).
-- Shopping uses the page's own luck ranges; it has no 280-300 list yet.
local S = addon.Step

addon.guides.tailoring = {
    name = "Tailoring",
    skillLine = 197,
    icon = "Interface\\Icons\\Trade_Tailoring",
    max = 300,
    intro = "Tailoring uses cloth from humanoid drops, so it needs no gathering profession. Enchanting is a popular pair: disenchant what you sew to level it. Most trainers have a Tailoring Supply vendor nearby for thread and dye.",
    tiers = {
        { name = "Apprentice", from = 1, to = 55, requires = "No level requirement.", steps = {
            S(1, 30, 30, "Bolt of Linen Cloth", { { 60, "Linen Cloth" } }, "Keep the bolts: you need all of them for the belts."),
            S(30, 55, 28, "Linen Belt", { { 28, "Bolt of Linen Cloth" }, { 28, "Coarse Thread", "Vendor" } }),
        } },
        { name = "Journeyman", from = 55, to = 140, requires = "Tailoring 50 and level 10 (needed to train past 75).", steps = {
            S(55, 80, 45, "Bolt of Woolen Cloth", { { 135, "Wool Cloth" } }, "Learn Journeyman first: no points above 75 until then. Keep the bolts (153 needed until 140)."),
            S(80, 95, 22, "Woolen Cape", { { 22, "Bolt of Woolen Cloth" }, { 22, "Fine Thread", "Vendor" } }),
            S(95, 100, 5, "Double-stitched Woolen Shoulders", { { 15, "Bolt of Woolen Cloth" }, { 10, "Fine Thread", "Vendor" } }),
            S(100, 120, 54, "Bolt of Silk Cloth", { { 216, "Silk Cloth" } }, "Keep the bolts (184 needed until 190)."),
            S(120, 140, 29, "Gloves of Meditation", { { 116, "Bolt of Woolen Cloth" }, { 87, "Fine Thread", "Vendor" }, { 29, "Elixir of Wisdom" } }, "Elixir of Wisdom from the Auction House or an Alchemist."),
        } },
        { name = "Expert", from = 140, to = 200, requires = "Tailoring 125 and level 20; costs 50 silver (needed to train past 150).", steps = {
            S(140, 150, 23, "Bolt of Mageweave", { { 115, "Mageweave Cloth" } }, "Keep the bolts (157 needed until 225)."),
            S(150, 170, 20, "Crimson Silk Vest", { { 80, "Bolt of Silk Cloth" }, { 40, "Red Dye", "Vendor" }, { 40, "Fine Thread", "Vendor" } }),
            S(170, 190, 26, "Crimson Silk Pantaloons", { { 104, "Bolt of Silk Cloth" }, { 52, "Red Dye", "Vendor" }, { 52, "Silken Thread", "Vendor" } }),
            S(190, 200, 19, "Black Mageweave Leggings", { { 38, "Bolt of Mageweave" }, { 57, "Silken Thread", "Vendor" } }),
        } },
        { name = "Artisan", from = 200, to = 300, requires = "Tailoring 200 and level 35 (needed to train past 225).", steps = {
            S(200, 205, 5, "Black Mageweave Shoulders", { { 15, "Bolt of Mageweave" }, { 10, "Heavy Silken Thread", "Vendor" } }, "Only the Artisan trainers teach it."),
            S(205, 215, 23, "Bolt of Runecloth", { { 115, "Runecloth" } }, "Keep the bolts (311 needed until 280)."),
            S(215, 225, 26, "Mageweave Bag", { { 104, "Bolt of Mageweave" }, { 52, "Silken Thread", "Vendor" } }, "Recommended over the belt: bags are more useful.",
                { "10x Runecloth Belt - 30 Bolt of Runecloth, 10 Rune Thread." }),
            S(225, 240, 24, "Runecloth Belt", { { 72, "Bolt of Runecloth" }, { 24, "Rune Thread", "Vendor" } }),
            S(240, 250, 11, "Runecloth Gloves", { { 44, "Bolt of Runecloth" }, { 44, "Rugged Leather" }, { 11, "Rune Thread", "Vendor" } }, "Pattern sold by Qia in Winterspring."),
            S(250, 280, 39, "Runecloth Cuffs", { { 195, "Bolt of Runecloth" }, { 39, "Ironweb Spider Silk" }, { 39, "Rune Thread", "Vendor" } },
                "Pattern sold by Pexmit in Mount Hyjal. Bind on pickup: buy it with the leveling character."),
            S(280, 300, 58, "Runecloth Shoulders", { { 406, "Bolt of Runecloth" }, { 116, "Ironweb Spider Silk" }, { 232, "Rugged Leather" } },
                "Pattern is a world drop or on the Auction House.",
                { "58x Wizardweave Turban - 348 Bolt of Runecloth, 232 Dream Dust, 58 Star Ruby (rare pattern)." }),
        } },
    },
    shopping = {
        { range = "1-150", from = 1, to = 150, items = {
            { 60, "Linen Cloth" }, { "408-459", "Wool Cloth" }, { 29, "Elixir of Wisdom" }, { "205-216", "Silk Cloth" }, { "93-115", "Mageweave Cloth" } } },
        { range = "150-225", from = 150, to = 225, items = {
            { "492-520", "Silk Cloth" }, { "538-670", "Mageweave Cloth", "Or 108-134 Bolt of Mageweave if cheaper." }, { "104-115", "Runecloth" } } },
        { range = "225-280", from = 225, to = 280, items = {
            { "1292-1440", "Runecloth" }, { 44, "Rugged Leather" }, { 39, "Ironweb Spider Silk" } } },
    },
    trainers = {
        { title = "Apprentice", groups = {
            { "Horde", { { "Snang", "Orgrimmar, the Drag" }, { "Victor Ward", "Undercity" }, { "Vhan", "Thunder Bluff, middle rise" },
                { "Bowen Brisboise", "Cold Hearth Manor, south-west of Brill, Tirisfal Glades" } } },
            { "Alliance", { { "Lawrence Schneider", "Stormwind City" }, { "Uthrar Threx", "Ironforge, Great Forge" }, { "Trianna", "Darnassus, Craftsmen's Terrace" },
                { "Eldrin", "Eastvale Logging Camp, Elwynn Forest" } } },
            { "Skyborne", { { "Othesia Evengale", "Valanaar, Zephras Isle" }, { "Taleen Shimmerthread", "Shen'dar Village, Zephras Isle" } } },
        } },
        { title = "Journeyman", groups = {
            { "Horde", { { "Magar", "Orgrimmar" }, { "Rhiannon Davis", "Undercity" }, { "Tepa", "Thunder Bluff" } } },
            { "Alliance", { { "Sellandus", "Stormwind City" }, { "Jormund Stonebrow", "Ironforge" }, { "Me'lynn", "Darnassus" } } },
        } },
        { title = "Expert and Artisan", groups = {
            { "Expert (140-200)", { { "Josef Gregorian", "Undercity (Horde)" }, { "Georgio Bolero", "Stormwind City (Alliance)" } } },
            { "Artisan (200-300)", { { "Daryl Stack", "Tarren Mill, Hillsbrad Foothills (Horde)" }, { "Timothy Worthington", "Theramore Isle, Dustwallow Marsh (Alliance)" } } },
        } },
    },
    -- How each rank is learned (Extras). Pins: Classic map IDs, approximate town-level spots.
    ranks = (function()
        local R = addon.Rank
        return {
            R("Apprentice (1-75)", "Trainer", "Any Tailoring trainer, no level requirement (see Trainers)."),
            R("Journeyman (75-150)", "Trainer", "A capital-city trainer: Tailoring 50 and level 10."),
            R("Expert (150-225)", "Trainer", "Josef Gregorian (Undercity, Horde) or Georgio Bolero (Stormwind City, Alliance): Tailoring 125, level 20, 50 silver."),
            R("Artisan (225-300)", "Trainer", "Daryl Stack (Tarren Mill, Hillsbrad Foothills, Horde) or Timothy Worthington (Theramore Isle, Dustwallow Marsh, Alliance): Tailoring 200, level 35.",
                { 1424, 62, 20 }, { 1445, 66.5, 49.5 }),
        }
    end)(),
    extras = {
        { title = "Patterns and quests", rows = {
            { "Runecloth Gloves", nil, "Sold by Qia in Winterspring." },
            { "Runecloth Cuffs", "BoP", "Sold by Pexmit in Mount Hyjal. Horde can also get it from Threading a Solution (Kal'tinzan, Elderwild, Mount Hyjal; level 54, 6 Bolt of Runecloth)." },
            { "Runecloth Shoulders", nil, "World drop or Auction House." },
            { "Wizardweave Turban", "Rare", "Grab it if you see it on the Auction House." },
        } },
        { title = "Other 280-300 recipes", notes = {
            "Runecloth Headband (42x: 168 Bolt of Runecloth, 84 Ironweb Spider Silk) and Runecloth Cuffs stop giving points before 300.",
            "The Cenarion Circle gloves, cords and footpads (285-300) need a Loom, which you can only make at Tailoring 300. The page says this may change.",
        } },
        { title = "About this guide", notes = {
            "Counts shown as ranges depend on luck: with the bigger number 9 out of 10 players have enough.",
            "No supply vendor near the Tirisfal Glades trainer: buy Coarse Thread from Abigail Shiel in Brill.",
            "The 225-280 shopping list is not final and there is no 280-300 list yet. This guide is based on the Forever beta.",
            "Content from wow-professions.com. See the full guide there.",
        } },
    },
}
