local _, addon = ...
-- Source: https://www.wow-professions.com/forever/cooking-leveling-guide (Forever beta). Counts are estimates.
local S = addon.Step

addon.guides.cooking = {
    name = "Cooking",
    skillLine = 185,
    icon = "Interface\\Icons\\INV_Misc_Food_15",
    max = 300,
    intro = "Cooking takes no profession slot. Keep a few recipes ready and cook whatever fish or meat drops while you level. Learn Journeyman Cooking at 50, or you stop gaining skill at 75. Spices come from Cooking Supply vendors near your trainer.",
    tiers = {
        { name = "Apprentice", from = 1, to = 50, requires = "No level requirement.", steps = {
            S(1, 50, 55, "Brilliant Smallfish", { { 55, "Raw Brilliant Smallfish" } }, "Usually the cheapest option.",
                { "Slitherskin Mackerel - 55 Raw Slitherskin Mackerel.", "Charred Wolf Meat - 55 Stringy Wolf Meat (trainer).", "Roasted Boar Meat - 55 Chunk of Boar Meat (trainer)." }),
        } },
        { name = "Journeyman", from = 50, to = 150, requires = "Cooking 50; Journeyman Cooking from any trainer (required past 75).", steps = {
            S(50, 100, 55, "Longjaw Mud Snapper", { { 55, "Raw Longjaw Mud Snapper" } }, nil,
                { "Rainbow Fin Albacore - 55 Raw Rainbow Fin Albacore.", "Smoked Bear Meat - 65-75 Bear Meat.", "Strider Stew - 55 Strider Meat, 55 Shiny Red Apple." }),
            S(100, 130, 30, "Bristle Whisker Catfish", { { 30, "Raw Bristle Whisker Catfish" } }, "Buy about 55: 25 more are needed for 130-150.",
                { "Cooked Crab Claw - 35 Crawler Claw, 35 Mild Spices (Alliance only)." }),
            S(130, 150, 25, "Bristle Whisker Catfish", { { 25, "Raw Bristle Whisker Catfish" } }, nil,
                { "Curiously Tasty Omelet - 20 Raptor Egg, 20 Hot Spices.", "Goblin Deviled Clams - 25 Tangy Clam Meat, 25 Hot Spices.", "Hot Lion Chops - 25 Lion Meat, 25 Hot Spices (Horde only)." }),
        } },
        { name = "Expert", from = 150, to = 225, requires = "Cooking 125; buy the Expert Cookbook from Wulan (Shadowprey Village, Desolace) or Shandrina (Mystral Lake, Ashenvale).", steps = {
            S(150, 175, 30, "Goblin Deviled Clams", { { 30, "Tangy Clam Meat" }, { 30, "Hot Spices", "Vendor" } }, "Bristle Whisker Catfish turns green at 160.",
                { "Curiously Tasty Omelet - 30 Raptor Egg, 30 Hot Spices.", "Hot Lion Chops - 25 Lion Meat, 25 Hot Spices (Horde only)." }),
            S(175, 225, 55, "Roast Raptor", { { 55, "Raptor Flesh" }, { 55, "Hot Spices", "Vendor" } }, "Usually the cheapest option.",
                { "Mithril Headed Trout - 55 Raw Mithril Head Trout.", "Soothing Turtle Bisque - 55 Turtle Meat, 55 Soothing Spices." }),
        } },
        { name = "Artisan", from = 225, to = 300, requires = "Level 35 and Cooking 225; the Clamlette Surprise quest teaches Artisan Cooking.", steps = {
            S(225, 300, 140, "Spotted Yellowtail", { { 140, "Raw Spotted Yellowtail" } }, "Recipe from Gikkix in Steamwheedle Port, Tanaris.", { "Filet of Redgill - 140 Raw Redgill." }),
        } },
    },
    shopping = {
        { range = "1-225", from = 1, to = 225, items = {
            { 55, "Raw Brilliant Smallfish" }, { 55, "Raw Longjaw Mud Snapper" }, { 55, "Raw Bristle Whisker Catfish" }, { 30, "Tangy Clam Meat" },
            { 55, "Raptor Flesh" }, { 85, "Hot Spices", "Vendor" } } },
        { range = "225-300", from = 225, to = 300, items = {
            { 140, "Raw Spotted Yellowtail" }, { 12, "Giant Egg", "Artisan quest" }, { 10, "Zesty Clam Meat", "Artisan quest" }, { 20, "Alterac Swiss", "Artisan quest" } } },
    },
    trainers = {
        { title = "Capital cities", groups = {
            { "Horde", { { "Zamja", "Orgrimmar" }, { "Eunice Burch", "Undercity" }, { "Aska Mistrunner", "Thunder Bluff" } } },
            { "Alliance", { { "Stephen Ryback", "Stormwind City" }, { "Daryl Riknussun", "Ironforge" }, { "Alegorn", "Darnassus" } } },
        } },
        { title = "Starting zones", groups = {
            { "Horde", { { "Cook Torka", "Razor Hill, Durotar" }, { "Pyall Silentstride", "Bloodhoof Village, Mulgore" }, { "William Pickman", "Inn in Brill, Tirisfal Glades" } } },
            { "Alliance", { { "Tomas", "Kitchen of the Goldshire inn, Elwynn Forest" }, { "Gremlock Pilsnor", "Thunderbrew Distillery, Kharanos, Dun Morogh" }, { "Zarrin", "Dolanaar, Teldrassil" } } },
            { "Skyborne", { { "Nyalah Brightfire", "Valanaar, Zephras Isle" }, { "Zerril Softbreeze", "Shen'dar Village, Zephras Isle" } } },
        } },
    },
    -- How each rank is learned (Extras). Pins: Classic map IDs, approximate town-level spots.
    ranks = (function()
        local R = addon.Rank
        return {
            R("Apprentice (1-75)", "Trainer", "Any Cooking trainer, no level requirement (see Trainers)."),
            R("Journeyman (75-150)", "Trainer", "Any trainer: Cooking 50."),
            R("Expert (150-225)", "Item", "Book: Expert Cookbook (Cooking 125). Sold by Wulan (Shadowprey Village, Desolace, Horde) or Shandrina (Mystral Lake, Ashenvale, Alliance).",
                { 1443, 26, 69.5 }, { 1440, 50, 67 }),
            R("Artisan (225-300)", "Quest", "Clamlette Surprise (Cooking 225, level 35), turned in to Dirge Quikcleave in Gadgetzan, Tanaris. Starts with Zamja (Orgrimmar) or Daryl Riknussun (Ironforge). See the Artisan quest page.",
                { 1446, 52.5, 29 }),
        }
    end)(),
    extras = {
        { title = "Artisan quest", notes = { "Artisan Cooking is the reward of Clamlette Surprise; you need level 35 and Cooking 225." }, rows = {
            { "Start", nil, "Horde: To Gadgetzan You Go! from Zamja (Orgrimmar). Alliance: I Know A Guy... from Daryl Riknussun (Ironforge)." },
            { "Collect first", nil, "12 Giant Egg, 10 Zesty Clam Meat and 20 Alterac Swiss. Do not go to Gadgetzan before you have them all." },
            { "Turn in", nil, "Dirge Quikcleave in Gadgetzan. Then buy Recipe: Spotted Yellowtail from Gikkix in Steamwheedle Port." },
        } },
        { title = "Recipe vendors (1-150)", rows = {
            { "Brilliant Smallfish", nil, "Harn Longcast (Mulgore), Sewa Mistrunner (Thunder Bluff), Lizbeth Cromwell (Undercity), Gretta Ganter (Dun Morogh), Tharynn Bouden (Elwynn Forest), Catherine Leland (Stormwind), Nyoma (Teldrassil)." },
            { "Slitherskin Mackerel", nil, "Zansoa (Durotar), Martine Tramblay (Tirisfal Glades), Tansy Puddlefizz (Ironforge), Nessa Shadowsong (Teldrassil)." },
            { "Longjaw Mud Snapper", nil, "Harn Longcast (Mulgore), Killian Sanatha (Silverpine), Lizbeth Cromwell (Undercity), Tharynn Bouden (Elwynn), Tansy Puddlefizz (Ironforge), Nyoma (Teldrassil)." },
            { "Bristle Whisker Catfish", nil, "Derak Nightfall and Lindea Rabonne (Hillsbrad), Naal Mistrunner (Thunder Bluff), Ronald Burch (Undercity), Catherine Leland (Stormwind), Kilxx (The Barrens)." },
            { "Goblin Deviled Clams", "Trainer", "Taught by the Cooking trainer, like Charred Wolf Meat and Roasted Boar Meat." },
        } },
        { title = "Recipe vendors (150-300)", rows = {
            { "Roast Raptor", nil, "Hammon Karwn (Arathi, Alliance); Keena (Arathi, Horde); Ogg'marr (Dustwallow Marsh, Horde)." },
            { "Mithril Headed Trout", nil, "Shankys (Orgrimmar), Kelsey Yance (Stranglethorn), Lizbeth Cromwell (Undercity), Tansy Puddlefizz (Ironforge), Stuart Fleming (Wetlands)." },
            { "Soothing Turtle Bisque", "Quest", "Hillsbrad Foothills: Christoph Jeffcoat (Horde) or Chef Jessen (Alliance)." },
            { "Spotted Yellowtail", nil, "Gikkix, Steamwheedle Port, Tanaris." },
            { "Filet of Redgill", nil, "Kelsey Yance, Stranglethorn Vale." },
        } },
        { title = "About this guide", notes = {
            "You learn the Basic Campfire Kit with Cooking: craft kits from Simple Wood and Flint and Tinder, sold by Cooking Supply vendors.",
            "Counts are estimates: yellow recipes do not always give a point.",
            "This guide is based on the Forever beta; higher levels are untested on live.",
            "Content from wow-professions.com. See the full guide there.",
        } },
    },
}
