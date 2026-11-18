local _, addon = ...
-- Source: https://www.wow-professions.com/forever/lockpicking-leveling-guide. 150-300 routes are reader reports and Classic assumptions.
local S = addon.Step

addon.guides.lockpicking = {
    name = "Lockpicking",
    skillLine = 633,
    icon = "Interface\\Icons\\Spell_Nature_MoonKey",
    max = 300,
    intro = "Lockpicking cannot go higher than 5 times your character level, so level it alongside your character. Each range names the best place to pick locks.",
    tiers = {
        { name = "Level 20", from = 1, to = 100, requires = "Character level 20 for skill 100.", steps = {
            S(1, 100, nil, "Buccaneer's Strongboxes inside the ship near Ratchet, The Barrens (Horde)", {},
                "Strongboxes respawn in seconds, so two rogues can level together. Do not open the Jewel of the Southsea at low level: it spawns a mob that kills you.",
                { "Practice Lockboxes north of Lake Everstill, Redridge Mountains (fast respawn)." }),
        } },
        { name = "Level 30", from = 100, to = 150, requires = "Character level 30 for skill 150.", steps = {
            S(100, 150, nil, "Waterlogged Footlockers along the shore, Zoram Strand, Ashenvale", {}),
        } },
        { name = "Level 45", from = 150, to = 225, requires = "Character level 45 for skill 225.", steps = {
            S(150, 175, nil, "Battered Footlockers upstairs, Angor Fortress, Badlands", {}, "Move downstairs at 175."),
            S(175, 225, nil, "Dented Footlockers downstairs, Angor Fortress, Badlands", {}, "A point every time until 215; stay until 225."),
        } },
        { name = "Level 60", from = 225, to = 300, requires = "Character level 60 for skill 300.", steps = {
            S(225, 300, nil, "Upper Dented Footlockers, The Slag Pit, Searing Gorge", {}, "Yellow until 290, green after, so the last 10 points are slower.",
                { "Lower Dented Footlockers in The Slag Pit (need 200), until they stop giving points." }),
        } },
    },
    extras = {
        { title = "About this guide", notes = {
            "The 1-100 route was confirmed by a reader on a Horde rogue. The 150-300 routes come from Classic and are not yet confirmed in Forever.",
        }, rows = {
            { "Max skill by level", nil, "Level 20: 100. Level 30: 150. Level 45: 225. Level 60: 300." },
        } },
    },
}
