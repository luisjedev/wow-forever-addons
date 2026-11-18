local _, addon = ...
-- Source: https://www.wow-professions.com/forever/first-aid-leveling-guide (Forever beta). Shopping totals are estimates.
local S = addon.Step
-- Both manuals are sold by the same vendors. Pins use the Classic map IDs and coordinates.
local function Manual(name)
    return { "Manual: " .. name, "Vendor, 1g.",
        "Horde: Balai Lok'Wein, Brackenwall Village, Dustwallow Marsh (36.4, 30.4).",
        "Alliance: Deneb Walker, Stromgarde Keep, Arathi Highlands (26.8, 59.6).",
        pins = { Horde = { 1445, 36.4, 30.4 }, Alliance = { 1417, 26.8, 59.6 } } }
end

addon.guides.firstaid = {
    name = "First Aid",
    skillLine = 129,
    icon = "Interface\\Icons\\Spell_Holy_SealOfSacrifice",
    max = 300,
    intro = "First Aid takes no profession slot. Learn Silk Bandage from your trainer before you leave, and buy the Expert First Aid book at 125. In Forever, First Aid also makes the healing potions that used to be Alchemy recipes.",
    tiers = {
        { name = "Apprentice", from = 1, to = 75, requires = "No level requirement.", steps = {
            S(1, 40, 50, "Linen Bandage", { { 50, "Linen Cloth" } }, nil, { "Healing Potions path (1-75): 86x Minor Healing Potion - 86 Peacebloom, 86 Mild Spices, 86 Empty Vial." }),
            S(40, 75, 49, "Heavy Linen Bandage", { { 98, "Linen Cloth" } }),
        } },
        { name = "Journeyman", from = 75, to = 150, requires = "First Aid 50, then Journeyman First Aid from any trainer.", steps = {
            S(75, 80, 16, "Heavy Linen Bandage", { { 32, "Linen Cloth" } }),
            S(80, 90, 12, "Wool Bandage", { { 12, "Wool Cloth" } }, "If you must buy everything, the Healing Potions path is cheaper."),
            S(90, 115, 43, "Wool Bandage", { { 43, "Wool Cloth" } }, nil,
                { "Healing Potions path (90-150): 54x Simple Poultice (54 Spider Ichor, 54 Mild Spices, 54 Bottle of Dalaran Noir) to 125, then 31x Healing Potion (31 Bruiseweed, 31 Hot Spices, 31 Leaded Vial)." }),
            S(115, 150, 54, "Heavy Wool Bandage", { { 108, "Wool Cloth" } }),
        } },
        { name = "Expert", from = 150, to = 225, requires = "First Aid 125: buy Expert First Aid - Under Wraps (no level requirement).", steps = {
            S(150, 180, 47, "Silk Bandage", { { 47, "Silk Cloth" } }, "Learn it from your trainer before you leave: it is the last recipe trainers teach."),
            S(180, 210, 47, "Heavy Silk Bandage", { { 94, "Silk Cloth" } }, "Learn it from Manual: Heavy Silk Bandage.", nil, Manual("Heavy Silk Bandage")),
            S(210, 225, 19, "Mageweave Bandage", { { 19, "Mageweave Cloth" } }, "Learn it from Manual: Mageweave Bandage.", nil, Manual("Mageweave Bandage")),
        } },
        { name = "Artisan", from = 225, to = 300, requires = "First Aid 225 and level 35; complete the Triage quest (quest level 45).", steps = {
            S(225, 240, 29, "Mageweave Bandage", { { 29, "Mageweave Cloth" } }, "Triage must be done to train past 225 (see Extras)."),
            S(240, 260, 30, "Heavy Mageweave Bandage", { { 60, "Mageweave Cloth" } }, "The Triage doctor teaches it at 240."),
            S(260, 275, 20, "Runecloth Bandage", { { 20, "Runecloth" } }, "The Triage doctor teaches it at 260."),
            S(275, 300, 30, "Major Healing Potion", { { 30, "Golden Sansam" }, { 90, "Soothing Spices", "Vendor" }, { 30, "Crystal Vial", "Vendor" } },
                "Manual: Major Healing Potion. Buy it on the Auction House if under 8g.",
                { "Pexmit in Mount Hyjal sells the manual for 8g.", "Horde: reward of A Rest Without Pain (Ortak Lomgok, Elderwild, Mount Hyjal)." },
                { "Manual: Major Healing Potion", "Vendor: Pexmit, Mount Hyjal (8g).", "Horde quest: A Rest Without Pain, from Ortak Lomgok in Elderwild, Mount Hyjal.",
                    "Also on the Auction House." }),
        } },
    },
    shopping = {
        { range = "1-150", from = 1, to = 150, items = { { 180, "Linen Cloth" }, { 163, "Wool Cloth" } } },
        { range = "150-225", from = 150, to = 225, items = { { 141, "Silk Cloth" }, { 19, "Mageweave Cloth" } } },
        { range = "225-300", from = 225, to = 300, items = { { 89, "Mageweave Cloth" }, { 20, "Runecloth" }, { 30, "Golden Sansam" },
            { 90, "Soothing Spices", "Vendor" }, { 30, "Crystal Vial", "Vendor" } } },
    },
    trainers = {
        { title = "Capital cities", groups = {
            { "Horde", { { "Arnok", "Orgrimmar" }, { "Mary Edras", "Undercity" }, { "Pand Stonebinder", "Thunder Bluff" } } },
            { "Alliance", { { "Shaina Fuller", "Stormwind City" }, { "Nissa Firestone", "Ironforge" }, { "Dannelor", "Darnassus" } } },
        } },
        { title = "Starting zones", groups = {
            { "Horde", { { "Rawrk", "Barracks in Razor Hill, Durotar" }, { "Vira Younghoof", "Inn in Bloodhoof Village, Mulgore" }, { "Nurse Neela", "Inn in Brill, Tirisfal Glades" } } },
            { "Alliance", { { "Michelle Belle", "Upstairs in the Goldshire inn, Elwynn Forest" }, { "Thamner Pol", "Thunderbrew Distillery, Kharanos, Dun Morogh" },
                { "Byancie", "Building north of the inn, Dolanaar, Teldrassil" } } },
            { "Skyborne", { { "Melasa Fairmend", "Valanaar, Zephras Isle" }, { "Naleeia Tattermend", "Shen'dar Village, Zephras Isle" } } },
        } },
        { title = "Expert book and Triage", groups = {
            { "Expert First Aid book and manuals", { { "Balai Lok'Wein", "Dustwallow Marsh (Horde)" }, { "Deneb Walker", "Arathi Highlands (Alliance)" } } },
            { "Triage quest (Artisan)", { { "Doctor Gregory Victor", "Hammerfall, Arathi Highlands (Horde)" },
                { "Doctor Gustaf VanHowzen", "Foothold Citadel, Dustwallow Marsh (Alliance)" } } },
        } },
    },
    extras = {
        { title = "Triage quest", notes = {
            "Needed to train past 225. You get a stack of Triage Bandages and must save 15 patients, healing the critically injured first. Set aside about 10 minutes.",
        }, rows = {
            { "Health bars", nil, "Press CTRL + V or enable NPC names, and zoom the camera out." },
            { "Bandages", nil, "Use the doctor's Triage Bandages from your action bar, not your own." },
            { "Position", nil, "Stand in the middle of the room and click the next patient while the current heal finishes." },
            { "Turn in", "Warning", "After 15 patients, turn the quest in immediately: if more patients die afterwards, it can fail." },
        } },
        { title = "Reagent vendors", notes = { "Spices, vials and Bottle of Dalaran Noir for the Healing Potions path." }, rows = {
            { "Horde", nil, "Orgrimmar: Xen'to (spices), Kor'geld (vials), Barkeep Morag (Noir). Undercity: Felicia Doan. Thunder Bluff: Naal Mistrunner, Mani Winterhoof." },
            { "Alliance", nil, "Stormwind: Edna Mullby; Noir from Roberto Pupellyverbos or Elly Langston. Ironforge: Emrul Riknussun, Gwina Stonebranch, Bruuk Barleybeard. Darnassus: Mythrin'dir." },
            { "Booty Bay", nil, "Nixxrax Fillamug sells Bottle of Dalaran Noir." },
        } },
        { title = "About this guide", notes = {
            "Shopping numbers are estimates: yellow recipes do not always give a point.",
            "The page lists Triage at Theramore in one place and Foothold Citadel in another (its map pin is Foothold Citadel).",
            "This guide is based on the Forever beta; higher levels are untested on live.",
            "Content from wow-professions.com. See the full guide there.",
        } },
    },
}
