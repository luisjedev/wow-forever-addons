# ProfGuide 0.1.0-snapshot-6

- The Recipes tab groups recipes by what they craft. Armor types come first (Cloth, Leather, Mail, Plate, Shields…), then weapon types (One-Handed Maces, Polearms…), then other item types (potions, elixirs…), and enchants last. Each group header shows how many recipes it has, and inside a group recipes stay ordered by skill. Group names come from the client, so they follow its language.

Lua syntax and the checks pass. Not yet verified in the game.

# ProfGuide 0.1.0-snapshot-5

- **WritBoard is now part of ProfGuide.** Uninstall the separate WritBoard addon.
- The window is wider (1000 px), the size WritBoard had, so the writ table fits.
- New **Writs** button at the top right opens the Craftsman's Writs view: every writ with its reputation, recipient, map button and Auctionator prices, grouped by zone, with the zone selector. **Back** returns to where you were. `/writs` and `/writboard` open it directly.
- The writs view has three filters: **All**, **In bags** and **Vendor items** (tabards, Pack Kodo, certifications and other items sold for Merchant's Favor).
- New **Recipes** tab in Alchemy, Blacksmithing, Cooking, Enchanting, Engineering, Leatherworking and Tailoring: that profession's camp vendor recipes with skill, reputation, Merchant's Favor cost and a learned check. Hold Shift over a recipe to compare the crafted item with your equipped gear.
- ProfGuide also appears in the minimap's addon list.
- The writ filter and zone selection are saved in ProfGuide's data. Choices made in WritBoard do not carry over.

Lua syntax and the checks pass. Not yet verified in the game.

# ProfGuide 0.1.0-snapshot-4

- Extras now opens on **Learning each rank**: where Apprentice, Journeyman, Expert and Artisan are learned and whether it is a trainer, a quest or a book. Ranks learned at a specific place (Artisan trainers, Expert books, Artisan quests) get a **Show on map** button for your faction. Lockpicking has no ranks and is unchanged.

Lua syntax and the data/page checks pass. Not yet verified in the game; pins are approximate town-level spots.

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
