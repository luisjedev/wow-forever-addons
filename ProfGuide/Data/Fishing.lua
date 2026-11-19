local _, addon = ...
-- Source: https://www.wow-professions.com/forever/fishing-leveling-guide (Forever beta).
local S = addon.Step

addon.guides.fishing = {
    name = "Fishing",
    skillLine = 356,
    icon = "Interface\\Icons\\Trade_Fishing",
    max = 300,
    intro = "No materials needed, only a Fishing Pole and some lures. Level in a starting zone, then capital cities. From 150 use Bright Baubles, and complete Nat Pagle's quest to train past 225.",
    tiers = {
        { name = "Apprentice", from = 1, to = 75, requires = "No level requirement; any trainer.", steps = {
            S(1, 75, nil, "Starting zones: Dun Morogh, Durotar, Elwynn Forest, Mulgore, Teldrassil, Tirisfal Glades, Zephras Isle", {}, "Use a Fishing Pole with Shiny Baubles in lakes, ponds or rivers."),
        } },
        { name = "Journeyman", from = 75, to = 150, requires = "Fishing 50 and level 10 (every trainer teaches it).", steps = {
            S(75, 150, nil, "Capital cities: Darnassus, Stormwind, Orgrimmar, Undercity, Thunder Bluff", {}, "If fish keep getting away, switch to Nightcrawlers (Fishing 50).",
                { "The Barrens, Darkshore, Ironforge, Loch Modan, Silverpine Forest, Westfall." }),
        } },
        { name = "Expert", from = 150, to = 225, requires = "Level 20 and Fishing 125: Expert Fishing - The Bass and You, from Old Man Heming in Booty Bay.", steps = {
            S(150, 225, nil, "Dustwallow Marsh", {}, "Use Bright Baubles. Buy a stack from Old Man Heming before leaving Booty Bay.",
                { "Alterac Mountains, Arathi Highlands, Desolace, Stranglethorn Vale, Swamp of Sorrows, Thousand Needles." }),
        } },
        { name = "Artisan", from = 225, to = 300, requires = "Level 35 and Fishing 225; complete Nat Pagle, Angler Extreme (Dustwallow Marsh).", steps = {
            S(225, 300, nil, "Felwood, Feralas, The Hinterlands, Tanaris, Un'Goro Crater, Western Plaguelands", {}, "Use Bright Baubles to stop fish getting away."),
        } },
    },
    trainers = {
        { title = "Trainers", groups = {
            { "Horde", { { "Lumak", "Orgrimmar" }, { "Armand Cromwell", "Undercity" }, { "Kah Mistrunner", "Thunder Bluff" }, { "Lau'Tiki", "Sen'jin Village coast, Durotar" },
                { "Uthan Stillwater", "Stonebull Lake, Mulgore" }, { "Clyde Kellen", "Brightwater Lake, east of Brill, Tirisfal Glades" } } },
            { "Alliance", { { "Arnold Leland", "Stormwind City" }, { "Grimnur Stonebrand", "Ironforge" }, { "Astaia", "Darnassus" },
                { "Lee Brown", "Crystal Lake, east of Goldshire, Elwynn Forest" }, { "Paxton Ganter", "Iceflow Lake, Dun Morogh" }, { "Androl Oakhand", "Rut'theran Village, Teldrassil" } } },
            { "Skyborne", { { "Baelann Swiftcurrent", "Valanaar, Zephras Isle" }, { "Fenn Fairweather", "Shen'dar Village, Zephras Isle" } } },
        } },
    },
    -- How each rank is learned (Extras). Pins: Classic map IDs, approximate town-level spots.
    ranks = (function()
        local R = addon.Rank
        return {
            R("Apprentice (1-75)", "Trainer", "Any Fishing trainer, no level requirement (see Trainers)."),
            R("Journeyman (75-150)", "Trainer", "Any trainer: Fishing 50 and level 10."),
            R("Expert (150-225)", "Item", "Book: Expert Fishing - The Bass and You (Fishing 125, level 20). Sold by Old Man Heming, Booty Bay, Stranglethorn Vale (both factions).",
                { 1434, 27, 77 }),
            R("Artisan (225-300)", "Quest", "Nat Pagle, Angler Extreme (Fishing 225, level 35), from Nat Pagle in Dustwallow Marsh. See Nat Pagle's quest page.",
                { 1445, 58.5, 60 }),
        }
    end)(),
    extras = {
        { title = "Gear and lures", rows = {
            { "Fishing Pole", "Vendor", "Fishing Supply or Trade Supply vendors. In capitals the vendor stands next to the trainer." },
            { "Shiny Bauble", "1-75", "Basic lure for the starting zones." },
            { "Nightcrawlers", "75+", "When fish keep getting away; needs Fishing 50." },
            { "Bright Baubles", "150+", "For Dustwallow Marsh, the 225-300 zones and Feralas." },
        } },
        { title = "Nat Pagle's quest", notes = {
            "Nat Pagle, Angler Extreme: Nat Pagle in Tidefury Cove, Dustwallow Marsh. Level 35 and Fishing 225. Catch one quest fish in each zone below.",
        }, rows = {
            { "Feralas Ahi", "Feralas", "Use Bright Baubles here." },
            { "Misty Reed Mahi Mahi", "Swamp", "Swamp of Sorrows." },
            { "Sar'theris Striker", "Desolace" },
            { "Savage Coast Blue Sailfin", "STV", "Stranglethorn Vale." },
        } },
        { title = "About this guide", notes = {
            "The Expert book is also sold on the Auction House.",
            "This guide is based on the Forever beta; higher levels are untested on live.",
            "Content from wow-professions.com. See the full guide and vendor list there.",
        } },
    },
}
