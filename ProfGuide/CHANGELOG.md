# ProfGuide 0.1.0-snapshot-1

- First MVP: an in-game Blacksmithing 1-300 guide for WoW Forever, with a Blizzard dialog look.
- Tabs: **Leveling** (one page per tier, step cards with crafts, materials, notes and alternatives), **Shopping List** (1-150, 150-225, 225-300), **Trainers** (apprentice, hammer vendors, higher ranks) and **Extras** (specializations, Imperial Plate quests, notes).
- Reads your Blacksmithing skill: shows a progress bar, opens on your current tier and marks steps as Now / Done.
- Open with the minimap button, `/profguide` or `/pg`. Window position, tab and page are saved per character.
- Guide data is from wow-professions.com (Forever beta). The 270-300 range is untested upstream.

Lua syntax and the data/page checks pass. Not yet verified in the game. Target: WoW Forever 1.60.1, interface 16001.
