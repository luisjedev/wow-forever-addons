# ProfGuide 0.1.0-snapshot-3

- First Aid manual steps: hover the card to see where the manual comes from (vendor, quest or Auction House). Vendor manuals get a **Show on map** button that marks your faction's vendor.

# ProfGuide 0.1.0-snapshot-2

- Guides for all 13 professions on wow-professions.com/forever: Alchemy, Blacksmithing, Enchanting, Engineering, Leatherworking, Tailoring, Mining, Herbalism, Skinning, First Aid, Cooking, Fishing and Lockpicking.
- New overview: the window opens on a grid of profession tiles showing your skill; click one to open its guide, **Back** returns to the grid.
- Gathering guides (Mining, Herbalism, Skinning, Fishing, Lockpicking) show zones per skill range and have no Shopping List tab.
- Blacksmithing trainers get a **Show on map** button that places a waypoint on the town.
- Saved pages are now kept per profession; the previous Blacksmithing pages carry over.

Lua syntax and the data/page checks pass. Not yet verified in the game.

# ProfGuide 0.1.0-snapshot-1

- First MVP: an in-game Blacksmithing 1-300 guide for WoW Forever, with a Blizzard dialog look.
- Tabs: **Leveling** (one page per tier, step cards with crafts, materials, notes and alternatives), **Shopping List** (1-150, 150-225, 225-300), **Trainers** (apprentice, hammer vendors, higher ranks) and **Extras** (specializations, Imperial Plate quests, notes).
- Reads your Blacksmithing skill: shows a progress bar, opens on your current tier and marks steps as Now / Done.
- Open with the minimap button, `/profguide` or `/pg`. Window position, tab and page are saved per character.
- Guide data is from wow-professions.com (Forever beta). The 270-300 range is untested upstream.

Lua syntax and the data/page checks pass. Not yet verified in the game. Target: WoW Forever 1.60.1, interface 16001.
