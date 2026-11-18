local _, addon = ...
-- Source: https://www.wow-professions.com/forever/alchemy-leveling-guide (Forever beta). Shopping totals are estimates.
local S = addon.Step

addon.guides.alchemy = {
    name = "Alchemy",
    skillLine = 171,
    icon = "Interface\\Icons\\Trade_Alchemy",
    max = 300,
    intro = "The fastest and cheapest Alchemy path from 1 to 300 on WoW Forever, based on the Forever beta. Alchemy pairs well with Herbalism, since you can skip buying herbs from the Auction House. Shopping totals are estimates, because some crafts may not give a skill-up once recipes turn yellow.",
    tiers = {
        { name = "Apprentice", from = 1, to = 55, requires = "None. Apprentice Alchemy has no level requirement in Forever.", steps = {
            S(1, 10, 9, "Elixir of Minor Force", { { 9, "Silverleaf" }, { 9, "Empty Vial", "Vendor" } }),
            S(10, 55, 45, "Elixir of Minor Defense", { { 45, "Silverleaf" }, { 45, "Peacebloom" }, { 45, "Empty Vial", "Vendor" } }),
        } },
        { name = "Journeyman", from = 55, to = 150, requires = "Learn Journeyman Alchemy from a capital-city trainer: Alchemy 50 and level 10.", steps = {
            S(55, 65, 10, "Minor Mana Potion", { { 10, "Mageroyal" }, { 10, "Peacebloom" }, { 10, "Empty Vial", "Vendor" } }),
            S(65, 90, 28, "Elixir of Minor Fortitude", { { 56, "Earthroot" }, { 28, "Peacebloom" }, { 28, "Empty Vial", "Vendor" } }),
            S(90, 120, 30, "Elixir of Wisdom", { { 30, "Mageroyal" }, { 60, "Briarthorn" }, { 30, "Empty Vial", "Vendor" } }, "Keep these elixirs if you also level Tailoring (Gloves of Meditation)."),
            S(120, 130, 10, "Lesser Mana Potion", { { 10, "Mageroyal" }, { 10, "Stranglekelp" }, { 10, "Empty Vial", "Vendor" } }),
            S(130, 150, 20, "Fire Oil", { { 40, "Firefin Snapper" }, { 20, "Empty Vial", "Vendor" } }, "2 oils per craft. Keep 30 for Elixir of Fire Power (150-165)."),
        } },
        { name = "Expert", from = 150, to = 225, requires = "Learn Expert Alchemy from Doctor Herbert Halsey (Undercity) or Ainethil (Darnassus): Alchemy 125, level 20, 50 silver.", steps = {
            S(150, 165, 15, "Elixir of Fire Power", { { 30, "Fire Oil", "Crafted" }, { 15, "Kingsblood" }, { 15, "Leaded Vial" } }, "Uses the 30 Fire Oil kept from 130-150."),
            S(165, 195, 36, "Mana Potion", { { 36, "Stranglekelp" }, { 36, "Kingsblood" }, { 36, "Leaded Vial" } }),
            S(195, 225, 36, "Nature Protection Potion", { { 36, "Liferoot" }, { 36, "Stranglekelp" }, { 36, "Leaded Vial" } }, "Needs the Nature Protection Potion recipe (see recipe vendors)."),
        } },
        { name = "Artisan", from = 225, to = 300, requires = "Learn Artisan Alchemy from Rogvar (Stonard, Swamp of Sorrows) or Kylanna Windwhisper (Feathermoon Stronghold, Feralas): Alchemy 200, level 35.", steps = {
            S(225, 235, 26, "Nature Protection Potion", { { 26, "Liferoot" }, { 26, "Stranglekelp" }, { 26, "Leaded Vial" } }),
            S(235, 250, 15, "Elixir of Greater Intellect", { { 15, "Blindweed" }, { 15, "Khadgar's Whisker" }, { 15, "Crystal Vial" } }),
            S(250, 260, 47, "Stonescale Oil", { { 47, "Stonescale Eel" }, { 47, "Leaded Vial" } }, "One craft makes 2. Keep all 94 for Elixir of Greater Defense (265-300).",
                { "If Stonescale Eel is expensive: skip this, keep making Elixir of Greater Intellect until 265 (about 21), then make Superior Mana Potions under 265-300." }),
            S(260, 265, 10, "Elixir of Greater Intellect", { { 10, "Blindweed" }, { 10, "Khadgar's Whisker" }, { 10, "Crystal Vial" } }),
            S(265, 300, 47, "Elixir of Greater Defense", { { 94, "Stonescale Oil", "Crafted" }, { 47, "Sungrass" }, { 47, "Crystal Vial" } }, "Recipe: Elixir of Superior Defense (Kor'geld or Soolie Berryfizz).",
                { "If you skipped the Stonescale Oil: 55x Superior Mana Potion, 110 Sungrass, 110 Blindweed, 55 Crystal Vial (recipe from Algernon or Ulthir)." }),
        } },
    },
    shopping = {
        { range = "1-150", from = 1, to = 150, items = {
            { 83, "Peacebloom" }, { 54, "Silverleaf" }, { 50, "Mageroyal" }, { 56, "Earthroot" }, { 60, "Briarthorn" },
            { 10, "Stranglekelp" }, { 40, "Firefin Snapper" }, { 152, "Empty Vial", "Vendor" } } },
        { range = "150-225", from = 150, to = 225, items = {
            { 30, "Fire Oil", "Crafted" }, { 51, "Kingsblood" }, { 72, "Stranglekelp" }, { 36, "Liferoot" }, { 87, "Leaded Vial" } } },
        { range = "225-300", from = 225, to = 300, items = {
            { 26, "Liferoot" }, { 26, "Stranglekelp" }, { 25, "Blindweed" }, { 25, "Khadgar's Whisker" }, { 47, "Sungrass" },
            { 47, "Stonescale Eel" }, { 73, "Leaded Vial" }, { 72, "Crystal Vial" }, { 94, "Stonescale Oil", "Crafted" } } },
    },
    trainers = {
        { title = "Apprentice (1-55): capital cities", groups = {
            { "Horde", { { "Whuut", "Orgrimmar" }, { "Doctor Martin Felben", "Undercity" }, { "Kray", "Thunder Bluff" } } },
            { "Alliance", { { "Tel'Athir", "Stormwind City" }, { "Vosur Brakthel", "Ironforge" }, { "Milla Fairancora", "Darnassus" } } },
        } },
        { title = "Apprentice (1-55): starting zones", groups = {
            { "Horde", { { "Miao'zan", "Durotar, Sen'jin Village" }, { "Kray", "Mulgore (no trainer there; go to Thunder Bluff middle rise)" },
                { "Carolai Anise", "Tirisfal Glades, small house at north-west end of Brill" } } },
            { "Alliance", { { "Alchemist Mallory", "Elwynn Forest, cottage in the hills between Stormwind and Northshire" },
                { "Vosur Brakthel", "Dun Morogh (no trainer there; Tinker Town in Ironforge)" },
                { "Cyndra Kindwhisper", "Teldrassil, small house east of the inn in Dolanaar" } } },
            { "Skyborne", { { "Iaadaria Bitterwind or Valiena Swiftgale", "Zephras Isle, Valanaar" }, { "Nyassa Swiftdraught", "Zephras Isle, Shen'dar Village" } } },
        } },
        { title = "Journeyman (55-150)", groups = {
            { "Horde", { { "Yelmak", "Orgrimmar" }, { "Doctor Marsh", "Undercity" }, { "Bena Winterhoof", "Thunder Bluff" } } },
            { "Alliance", { { "Lilyssia Nightbreeze", "Stormwind City" }, { "Tally Berryfizz", "Ironforge" }, { "Sylvanna Forestmoon", "Darnassus" } } },
        } },
        { title = "Expert and Artisan", groups = {
            { "Expert (150-225)", { { "Doctor Herbert Halsey", "Undercity (Horde)" }, { "Ainethil", "Darnassus (Alliance)" } } },
            { "Artisan (225-300)", { { "Rogvar", "Stonard, Swamp of Sorrows (Horde)" }, { "Kylanna Windwhisper", "Feathermoon Stronghold, Feralas (Alliance)" } } },
        } },
    },
    extras = {
        { title = "Vials and recipes", notes = {
            "Vials are sold by Alchemy Supply and Trade Supply vendors. Most trainers have one nearby (for example Algernon in Undercity, Narret Shadowgrove in Dolanaar).",
        }, rows = {
            { "Nature Protection Potion (item 6057)", "BoP", "Bronk (Feralas, Horde); Logannas (Feralas, Alliance); Glyx Brewright (Stranglethorn Vale); Alchemist Pestlezugg (Tanaris). Bind on pickup: buy it on the character that levels Alchemy." },
            { "Elixir of Superior Defense (item 13478)", nil, "Kor'geld (Orgrimmar); Soolie Berryfizz (Ironforge)" },
            { "Superior Mana Potion (item 13477)", nil, "Algernon (Undercity); Ulthir (Darnassus)" },
        } },
        { title = "About this guide", notes = {
            "This guide is based on the Forever beta.",
            "Shopping totals are estimates: yellow recipes may need a few more or fewer.",
            "Content from wow-professions.com. See the full guide there.",
        } },
    },
}
