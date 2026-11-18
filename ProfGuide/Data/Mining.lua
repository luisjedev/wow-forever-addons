local _, addon = ...
-- Source: https://www.wow-professions.com/forever/mining-leveling-guide (Forever beta). Route maps on the page are images and are not included.
local S = addon.Step

addon.guides.mining = {
    name = "Mining",
    skillLine = 186,
    icon = "Interface\\Icons\\Trade_Mining",
    max = 300,
    intro = "Mining 1-300 by zone. Buy a Mining Pick first and turn on Find Minerals from the Professions window (it turns off when you die). Respawns are much faster in Forever. Optional smelting to 105 is in Extras.",
    tiers = {
        { name = "Copper", from = 1, to = 65, requires = "Any Mining trainer, or Mining for Dummies on Zephras Isle.", steps = {
            S(1, 65, nil, "Copper Vein: Durotar (Horde) / Elwynn Forest (Alliance)", {}, "Run one or two laps, then smelt. Durotar's cave has 5 Copper Veins with very fast respawn.",
                { "Horde: Mulgore, Tirisfal Glades, Zephras Isle.", "Alliance: Dun Morogh, Teldrassil, Zephras Isle." }),
        } },
        { name = "Tin and Silver", from = 65, to = 125, requires = "Journeyman Mining (Mining 50); starting-area Junior trainers do not teach it.", steps = {
            S(65, 75, nil, "Tin Vein: Wetlands cave (Alliance) / Silverpine Forest cave (Horde)", {}, "Before you leave, smelt Copper and Tin into Bronze: Bronze stops giving points around 105.",
                { "Horde: Hillsbrad Foothills.", "Either faction: Westfall, The Barrens, Ashenvale, Stonetalon Mountains." }),
            S(75, 125, nil, "Silver and Tin Veins: same zones as 65-75", {}, "With a +5 Mining bonus you can switch to Iron at 120 (see Extras)."),
        } },
        { name = "Iron and Gold", from = 125, to = 175, requires = "Expert Mining (Mining 125).", steps = {
            S(125, 155, nil, "Iron Deposit: Thousand Needles (low level) / Arathi Highlands (high level or mount)", {}, "Around level 30, use Thousand Needles.", { "Desolace (untested on the beta)." }),
            S(155, 175, nil, "Gold Vein: Arathi Highlands / Thousand Needles / Desolace", {}, "Arathi has 4 caves: go to the end of each. Low levels should skip them."),
        } },
        { name = "Mithril and Truesilver", from = 175, to = 245, requires = "Artisan Mining (Mining 200) to train past 225.", steps = {
            S(175, 230, nil, "Mithril Deposit: The Hinterlands / Tanaris", {}, "Skip the red route in The Hinterlands at low level (level 62 elites). Below level 60, skip the 4 caves in Tanaris."),
            S(230, 245, nil, "Truesilver Deposit: The Hinterlands / Tanaris", {}),
        } },
        { name = "Thorium", from = 245, to = 300, requires = "Artisan Mining.", steps = {
            S(245, 275, nil, "Small Thorium Vein: Un'Goro Crater / Blasted Lands / Felwood", {},
                "Low levels: skip the south cave in Un'Goro. Alliance cannot mine inside the Garrison Armory in Blasted Lands."),
            S(275, 300, nil, "Rich Thorium Vein: Un'Goro Crater (same route)", {}, nil,
                { "Eastern Plaguelands (red line has level 57-58 elites).", "Winterspring (the gorge has many elites).", "Burning Steppes (some caves have level 50 mobs)." }),
        } },
    },
    trainers = {
        { title = "Horde", groups = {
            { "Capital cities", { { "Makaru", "Orgrimmar" }, { "Brom Killian", "Undercity" }, { "Brek Stonehoof", "Thunder Bluff" } } },
            { "Starting zones", { { "Norzsh", "Valley of Trials, Durotar (only up to 75)" }, { "Krunn", "Razor Hill, Durotar" },
                { "Vartha Rockmane", "Camp Narache, Mulgore (only up to 75)" }, { "Walter Mason", "Deathknell, Tirisfal Glades (only up to 75)" } } },
        } },
        { title = "Alliance", groups = {
            { "Capital cities", { { "Gelman Stonehand", "Stormwind City" }, { "Geofram Bouldertoe", "Ironforge" },
                { "Kurdram Stonehammer", "Auberdine, Darkshore (Darnassus has no trainer)" } } },
            { "Starting zones", { { "Kelsey Fargo", "Elwynn Forest (only up to 75)" }, { "Sally Swiftwrench", "Dun Morogh (only up to 75)" },
                { "Yarr Hammerstone", "Steelgrill's Depot, Dun Morogh" }, { "Dank Drizzlecut", "Gol'Bolar Quarry, Dun Morogh" },
                { "Fanorran Stilloak", "Aldrassil, Shadowglen, Teldrassil (only up to 75)" } } },
        } },
        { title = "Zephras Isle", groups = {
            { "Skyborne", { { "No trainer", "Thendal Village: the Harvesting Windstones quest rewards Mining for Dummies, which teaches Mining." },
                { "Halavuul Cragwind", "Valanaar" }, { "Messana Crestwind", "Shen'dar Village" } } },
        } },
    },
    extras = {
        { title = "Smelting to 105", notes = { "Optional: buy about 140 Copper Ore and 70 Tin Ore and smelt to 105 instead of mining. Bars often sell close to the ore price." }, rows = {
            { "Smelt Copper", "1-65", "120-140x. Keep 70 Copper Bars for Bronze." },
            { "Smelt Tin", "65-75", "70x after learning Journeyman Mining. Keep all 70 bars for Bronze." },
            { "Smelt Bronze", "75-105", "70x from your Copper and Tin Bars. Make a few extra." },
            { "Smelt Silver", "105-120", "Optional, check prices: 35-45x." },
            { "Smelt Iron", "to 135", "Optional: about 20 Iron Ore. Rarely gives a point after 135." },
            { "Smelt Gold", "155-175", "About 22 Gold Ore. A point each time until 170." },
        } },
        { title = "Skill bonuses", notes = { "Not required, but with +5 you can mine Iron from 120 instead of 125." }, rows = {
            { "Enchant Gloves - Mining", "+2", "From an enchanter." },
            { "Enchant Gloves - Advanced Mining", "+5", "From an enchanter." },
            { "Goblin Mining Helmet", "+5", "Made by Engineers; needs Engineering 205 to wear." },
            { "Twilight Mine Light", "+4", "Reward of A Miner Problem (Alliance, Riverglades)." },
            { "Miner's Cape", "+2", "Drops from Miner Johnson in The Deadmines." },
        } },
        { title = "Mining Pick vendors", rows = {
            { "Horde", nil, "Durotar: Norzsh, Flakk. Mulgore: Vartha Rockmane, Wunna Darkmane. Tirisfal: Walter Mason, Abigail Shiel. Orgrimmar: Gorina. Undercity: Elizabeth Van Talen. Thunder Bluff: Kurm Stonehoof." },
            { "Alliance", nil, "Elwynn: Brother Danil, Tharynn Bouden. Dun Morogh: Thrawn Boltar. Teldrassil: Fanorran Stilloak, Narret Shadowgrove. Stormwind: Brooke Stonebraid. Ironforge: Thurgrum Deepforge. Darnassus: Mythrin'dir." },
            { "Zephras Isle", nil, "Uualia Suncrest (Thendal Village), Belandiel Farflight (Shen'dar Village)." },
        } },
        { title = "About this guide", notes = {
            "Outlevel the cave mobs: with Forever's faster respawns they keep coming back on top of you.",
            "Routes after 125 follow standard Classic routes; the author could only test up to the beta cap of 30.",
            "Content from wow-professions.com. See the full guide and its route maps there.",
        } },
    },
}
