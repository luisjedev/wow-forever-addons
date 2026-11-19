local _, addon = ...
-- Source: https://www.wow-professions.com/forever/engineering-leveling-guide (Forever beta). Shopping totals are estimates.
-- The page puts 50-51 (Arclight Spanner) under Apprentice, so Apprentice runs 1-51.
local S = addon.Step

addon.guides.engineering = {
    name = "Engineering",
    skillLine = 202,
    icon = "Interface\\Icons\\Trade_Engineering",
    max = 300,
    intro = "Fastest and cheapest Engineering 1-300 on WoW Forever (beta). Pair it with Mining: almost every recipe needs stone or bars. You need a Blacksmith Hammer for most recipes (see Extras).",
    tiers = {
        { name = "Apprentice", from = 1, to = 51, requires = "No level requirement.", steps = {
            S(1, 30, 66, "Rough Blasting Powder", { { 66, "Rough Stone" } }, "Keep all of them: you need 66 for the bombs at 51."),
            S(30, 50, 33, "Handful of Copper Bolts", { { 33, "Copper Bar" } }, "Keep these too: you need all 33 for the bombs."),
            S(50, 51, 1, "Arclight Spanner", { { 6, "Copper Bar" } }, "Used to craft Engineering recipes, so keep it."),
        } },
        { name = "Journeyman", from = 51, to = 150, requires = "Engineering 50 and level 10.", steps = {
            S(51, 75, 33, "Rough Copper Bomb", { { 33, "Copper Bar" }, { 33, "Handful of Copper Bolts" }, { 66, "Rough Blasting Powder" }, { 33, "Linen Cloth" } },
                "Do not AFK craft unless you already learned Journeyman Engineering; you may go past 75 with these."),
            S(75, 90, 60, "Coarse Blasting Powder", { { 60, "Coarse Stone" } }, "Keep them: you need all 60 for the dynamite at 90."),
            S(90, 100, 20, "Coarse Dynamite", { { 60, "Coarse Blasting Powder" }, { 20, "Linen Cloth" } }),
            S(100, 105, 5, "Silver Contact", { { 5, "Silver Bar" } }, nil, { "If Silver Bar is expensive: 5x Flying Tiger Goggles - 30 Light Leather, 10 Tigerseye." }),
            S(105, 125, 25, "Bronze Tube", { { 50, "Bronze Bar" }, { 25, "Weak Flux", "Vendor" } }, "Keep 10 for 125. If you are a few points short of 125, start the scopes."),
            S(125, 135, 10, "Standard Scope", { { 10, "Bronze Tube" }, { 10, "Moss Agate" } }, "Make Heavy Blasting Powder instead if Moss Agate is missing or too expensive."),
            S(135, 150, 30, "Heavy Blasting Powder", { { 30, "Heavy Stone" }, { 30, "Bronze Bar" }, { 15, "Wool Cloth" } },
                "Also make 15x Whirring Bronze Gizmo (30 Bronze Bar, 15 Wool Cloth, included above): you need both for the sheep at 160."),
        } },
        { name = "Expert", from = 150, to = 200, requires = "Engineering 125 and level 20; costs 50 silver.", steps = {
            S(150, 160, 15, "Bronze Framework", { { 30, "Bronze Bar" }, { 15, "Medium Leather" }, { 15, "Wool Cloth" } }, "Keep all 15 for the sheep."),
            S(160, 175, 15, "Explosive Sheep", { { 30, "Heavy Blasting Powder" }, { 15, "Whirring Bronze Gizmo" }, { 15, "Bronze Framework" }, { 30, "Wool Cloth" } }, "Keep 5 for Goblin Engineering at 200."),
            S(175, 194, 60, "Solid Blasting Powder", { { 120, "Solid Stone" } }, "Save these; you need them later."),
            S(194, 195, 1, "Gyromatic Micro-Adjustor", { { 4, "Steel Bar" } }, "Keep it. If you are below 195, craft a few Iron Grenades or any recipe that gives points."),
            S(195, 200, 6, "Mithril Tube", { { 18, "Mithril Bar" } }, "Keep all 6 in case you choose Gnomish Engineering at 200."),
        } },
        { name = "Artisan", from = 200, to = 300, requires = "Engineering 200 and level 35; Buzzek Bracketswing in Gadgetzan, Tanaris (also teaches recipes above 200).", steps = {
            S(200, 215, 20, "Unstable Trigger", { { 20, "Mithril Bar" }, { 20, "Mageweave Cloth" }, { 20, "Solid Blasting Powder" } }, "Keep all 20 for the bombs at 238."),
            S(215, 238, 40, "Mithril Casing", { { 120, "Mithril Bar" } }, "Keep 40 for the bombs."),
            S(238, 250, 20, "Hi-Explosive Bomb", { { 40, "Mithril Casing" }, { 20, "Unstable Trigger" }, { 40, "Solid Blasting Powder" } }),
            S(250, 260, 44, "Dense Blasting Powder", { { 88, "Dense Stone" } }),
            S(260, 285, 35, "Thorium Widget", { { 105, "Thorium Bar" }, { 35, "Runecloth" } }, "Schematic sold by Sovik (Orgrimmar) and Gearcutter Cogspinner (Ironforge)."),
            S(285, 300, 20, "Thorium Tube", { { 120, "Thorium Bar" } }, "Schematic sold by Xizzer Fizzbolt in Everlook, Winterspring. Bind on pickup."),
        } },
    },
    shopping = {
        { range = "1-150", from = 1, to = 150, items = {
            { 66, "Rough Stone" }, { 72, "Copper Bar" }, { 53, "Linen Cloth" }, { 60, "Coarse Stone" }, { 5, "Silver Bar" },
            { 80, "Bronze Bar" }, { 25, "Weak Flux", "Vendor" }, { 10, "Moss Agate" }, { 30, "Heavy Stone" }, { 15, "Wool Cloth" } } },
        { range = "150-225", from = 150, to = 225, items = {
            { 30, "Bronze Bar" }, { 45, "Wool Cloth" }, { 15, "Medium Leather" }, { 4, "Steel Bar" }, { 120, "Solid Stone" },
            { 158, "Mithril Bar" }, { 20, "Mageweave Cloth" } } },
        { range = "225-300", from = 225, to = 300, items = { { 88, "Dense Stone" }, { 225, "Thorium Bar" }, { 35, "Runecloth" } } },
    },
    trainers = {
        { title = "Apprentice", groups = {
            { "Horde", { { "Thund", "Orgrimmar" }, { "Graham Van Talen", "Undercity, Rogues' Quarter. Closest for Undead" },
                { "Mukdrak", "Razor Hill, Durotar, near the forge by the road to Orgrimmar" },
                { "Twizwick Sprocketgrind", "Mulgore, plateau above the Venture Co. Mine; hard to reach at low level" } } },
            { "Alliance", { { "Sprite Jumpsprocket", "Stormwind City, Dwarven District. Closest for Humans" }, { "Jemma Quikswitch", "Ironforge" },
                { "Bronk Guzzlegear", "Steelgrill's Depot, Dun Morogh" }, { "Jenna Lemkenilli", "Auberdine, Darkshore. Closest for Night Elves" } } },
            { "Skyborne", { { "Strange Hermit", "Shadowgale Forest, Zephras Isle" } } },
        } },
        { title = "Journeyman", groups = {
            { "Horde", { { "Nogg", "Orgrimmar" }, { "Franklin Lloyd", "Undercity" } } },
            { "Alliance", { { "Lilliam Sparkspindle", "Stormwind City" }, { "Trixie Quikswitch", "Ironforge" }, { "Finbus Geargrind", "Duskwood" } } },
        } },
        { title = "Expert and Artisan", groups = {
            { "Expert (150-200)", { { "Roxxik", "Orgrimmar (Horde)" }, { "Springspindle Fizzlegear", "Ironforge (Alliance)" } } },
            { "Artisan (200-300)", { { "Buzzek Bracketswing", "Gadgetzan, Tanaris, outside the inn near the mailbox (both factions)" } } },
        } },
    },
    -- How each rank is learned (Extras). Pins: Classic map IDs, approximate town-level spots.
    ranks = (function()
        local R = addon.Rank
        return {
            R("Apprentice (1-75)", "Trainer", "Any Engineering trainer, no level requirement (see Trainers)."),
            R("Journeyman (75-150)", "Trainer", "A capital-city trainer: Engineering 50 and level 10."),
            R("Expert (150-225)", "Trainer", "Roxxik (Orgrimmar, Horde) or Springspindle Fizzlegear (Ironforge, Alliance): Engineering 125, level 20, 50 silver."),
            R("Artisan (225-300)", "Trainer", "Buzzek Bracketswing, outside the Gadgetzan inn, Tanaris (both factions): Engineering 200, level 35.", { 1446, 52, 28 }),
        }
    end)(),
    extras = {
        { title = "Tools and specializations", notes = {
            "At Engineering 200 and level 30 you can specialize in Gnomish or Goblin Engineering. Keep 5 Explosive Sheep for Goblin and 6 Mithril Tubes for Gnomish.",
            "The Gnome racial changed in Forever: Engineering Specialization makes devices fail or backfire 20% less often, so Gnomes level like everyone else.",
        }, rows = {
            { "Blacksmith Hammer", "Required", "Most recipes need it. Buy it from a Blacksmithing or Engineering Supply vendor. Near Dun Morogh use Thrawn Boltar (Kharanos); on Zephras Isle, Aedi Thriceforged (Shen'dar Village)." },
            { "Weak Flux", "Vendor", "Engineering Supply vendors near your trainer." },
        } },
        { title = "About this guide", notes = {
            "No Engineering trainer in Thunder Bluff, Darnassus, Tirisfal Glades, Elwynn Forest or Teldrassil. Ask a guard to mark the closest one.",
            "This guide is based on the Forever beta; higher levels are untested on live. Shopping numbers are estimates.",
            "Content from wow-professions.com. See the full guide and the Gnomish vs Goblin page there.",
        } },
    },
}
