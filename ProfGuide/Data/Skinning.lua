local _, addon = ...
-- Source: https://www.wow-professions.com/forever/skinning-leveling-guide (Forever beta).
local S = addon.Step

addon.guides.skinning = {
    name = "Skinning",
    skillLine = 393,
    icon = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",
    max = 300,
    intro = "Level Skinning by skinning hundreds of mobs at a good spot for each range. You need a Skinning Knife in your bags. A mob of level 20 or more needs 5 times its level in Skinning (see Extras). Pairs well with Leatherworking.",
    tiers = {
        { name = "Apprentice", from = 1, to = 75, requires = "Any Skinning trainer and a Skinning Knife.", steps = {
            S(1, 75, nil, "Mottled Boars (Valley of Trials, Durotar) or wolves (Northshire Valley, Elwynn Forest)", {}, "Any starting zone works for a new character."),
        } },
        { name = "Journeyman", from = 75, to = 150, requires = "Journeyman Skinning (Skinning 50); starting-area Junior trainers do not teach it.", steps = {
            S(75, 125, nil, "Elder Mountain Boar, Black Bear Patriarch, Loch Crocolisk: Loch Modan", {}, "Mob level 16-17. Stay until about 125, then go north to the Wetlands.",
                { "Barrens raptor camp west of Northwatch Hold: Sunscale Scytheclaw, Zhevra Charger, Ornery Plainstrider (to 150)." }),
            S(125, 150, nil, "Mottled Scytheclaw, Mottled Razormaw: Whelgar's Excavation Site, Wetlands", {}, "Mob level 25-27."),
        } },
        { name = "Expert", from = 150, to = 225, requires = "Expert Skinning, learned at 125 (needed to train past 150).", steps = {
            S(150, 225, nil, "Cave Yeti, Ferocious Yeti: Foothill Caverns, Hillsbrad Foothills", {}, "Mob level 30-32. From Tarren Mill (Horde) or Southshore (Alliance). Fast respawn: stay inside the cave.",
                { "Nightbane worgen at the Rotting Orchard, Duskwood (level 26-29)." }),
        } },
        { name = "Artisan", from = 225, to = 300, requires = "Artisan Skinning (Skinning 200).", steps = {
            S(225, 280, nil, "Feral Scar yetis: Feral Scar Vale, south Feralas", {}, "Mob level 43-46. From Camp Mojache (Horde) or Feathermoon Stronghold (Alliance)."),
            S(280, 300, nil, "Diemetradons and Pterrordaxes: western Un'Goro Crater", {}, "Mob level 50-55. Fly to Marshal's Refuge."),
        } },
    },
    trainers = {
        { title = "Trainers", groups = {
            { "Horde", { { "Thuwd", "Orgrimmar" }, { "Killian Hagey", "Undercity" }, { "Mooranta", "Thunder Bluff" }, { "Kagil", "Valley of Trials, Durotar (only up to 75)" },
                { "Nawka Wildsong", "Camp Narache, Mulgore (only up to 75)" }, { "Yonn Deepcut", "Bloodhoof Village, Mulgore" },
                { "Margaret Weaver", "Deathknell, Tirisfal Glades (only up to 75)" }, { "Rand Rhobart", "Tirisfal Glades" } } },
            { "Alliance", { { "Maris Granger", "Stormwind City" }, { "Balthus Stoneflayer", "Ironforge" }, { "Eladriel", "Darnassus" },
                { "Riley Peltskinner", "Northshire Valley, Elwynn Forest (only up to 75)" }, { "Helene Peltskinner", "Goldshire, Elwynn Forest" },
                { "Brighid Stormflayer", "Dun Morogh (only up to 75)" }, { "Terunne Bearshaper", "Aldrassil, Shadowglen, Teldrassil (only up to 75)" }, { "Radnaal Maneweaver", "Teldrassil" } } },
            { "Skyborne", { { "No trainer", "Thendal Village: Harvesting Windstones rewards Pelt Collecting for Beginners, which teaches Skinning." },
                { "Ishlee Breezewhisper", "Valanaar, Zephras Isle" }, { "Mendalass Tattermend", "Shen'dar Village, Zephras Isle" } } },
        } },
    },
    extras = {
        { title = "Which mobs can I skin?", rows = {
            { "Mob level 20+", "5x", "Skinning needed = 5 times the mob level (level 30 needs 150)." },
            { "Mob level 11-19", nil, "10 at level 11, plus 10 per level (level 15 needs 50, level 19 needs 90)." },
            { "Mob level 1-10", nil, "Skinning 1." },
        } },
        { title = "Tools and bonuses", rows = {
            { "Skinning Knife", "Required", "Keep it in your bags. Leatherworking Supply and most General Goods vendors sell it." },
            { "Enchant Gloves - Skinning", "+5", "Lets you skin mobs one level higher." },
            { "Keen Skinning Knife", "+3", "Horde reward from Unwelcome Guests, The Barrens." },
        } },
        { title = "About this guide", notes = {
            "This guide is based on the Forever beta; higher levels are untested on live.",
            "Content from wow-professions.com. See the full guide there.",
        } },
    },
}
