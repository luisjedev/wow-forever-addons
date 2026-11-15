# ProfGuide

In-game profession leveling guides for **WoW Forever**. This first version covers **Blacksmithing 1-300**: leveling steps, shopping lists, trainers, specializations and the Imperial Plate quests.

- **Open it:** minimap button, `/profguide` or `/pg`.
- **Leveling:** one page per tier; with Blacksmithing learned, it opens on your current tier and marks steps *Now* / *Done*.
- **Shopping List, Trainers, Extras:** paged with the buttons at the bottom.
- Interface chrome is translated (Spanish for now); guide content is English only.

## Source and limits

Content comes from the [WoW Forever Blacksmithing Leveling Guide](https://www.wow-professions.com/forever/blacksmithing-leveling-guide) on wow-professions.com, written for the Forever beta. The 270-300 range is untested upstream and material totals are estimates. Get permission from the guide's author before publishing a release.

Adding a profession means a new `Data/<Profession>.lua` in the same shape as `Data/Blacksmithing.lua` plus a profession selector in the window (not built yet).

## Install and check

Copy or symlink this folder to `Interface\AddOns\ProfGuide`. From the repository root: `luajit ProfGuide/ProfGuide.test.lua`. The check uses frame stubs and does not validate the real window layout.
