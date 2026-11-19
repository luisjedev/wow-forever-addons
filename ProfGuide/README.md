# ProfGuide

In-game profession leveling guides for **WoW Forever**. It covers all 13 professions from wow-professions.com/forever, 1-300: Alchemy, Blacksmithing, Enchanting, Engineering, Leatherworking, Tailoring, Mining, Herbalism, Skinning, First Aid, Cooking, Fishing and Lockpicking.

- **Open it:** minimap button, `/profguide` or `/pg`.
- **Overview:** the window opens on a grid of profession tiles with your current skill. Click a tile to open its guide; **Back** returns to the grid.
- **Leveling:** one page per tier; if you know the profession, it opens on your current tier and marks steps *Now* / *Done*. Lockpicking is not a profession entry, so its skill is not read.
- **Shopping List, Trainers, Extras:** paged with the buttons at the bottom. Gathering guides have no shopping list.
- **Extras** opens on how each rank (Apprentice to Artisan) is learned: trainer, quest or book, with a map button when it is in one place.
- Interface chrome is translated (Spanish for now); guide content is English only.

## Source and limits

Content comes from the [WoW Forever profession guides](https://www.wow-professions.com/forever) on wow-professions.com, written for the Forever beta. Higher ranges are often untested upstream, material totals are estimates, and route maps are not included. Each `Data/*.lua` file names its source page. Get permission from the guide's author before publishing a release.

Adding a profession means a new `Data/<Profession>.lua` in the same shape as the others, listed in the `.toc` and in `addon.guideOrder` (`Pages.lua`).

## Install and check

Copy or symlink this folder to `Interface\AddOns\ProfGuide`. From the repository root: `luajit ProfGuide/ProfGuide.test.lua`. The check uses frame stubs and does not validate the real window layout.
