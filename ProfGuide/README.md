# ProfGuide

In-game profession leveling guides for **WoW Forever**, plus the camp vendors' recipes and a Craftsman's Writs board. It covers all 13 professions from wow-professions.com/forever, 1-300: Alchemy, Blacksmithing, Enchanting, Engineering, Leatherworking, Tailoring, Mining, Herbalism, Skinning, First Aid, Cooking, Fishing and Lockpicking.

- **Open it:** minimap button, `/profguide` or `/pg`.
- **Overview:** the window opens on a grid of profession tiles with your current skill. Click a tile to open its guide; **Back** returns to the grid.
- **Leveling:** one page per tier; if you know the profession, it opens on your current tier and marks steps *Now* / *Done*. Lockpicking is not a profession entry, so its skill is not read.
- **Shopping List, Trainers, Extras:** paged with the buttons at the bottom. Gathering guides have no shopping list.
- **Extras** opens on how each rank (Apprentice to Artisan) is learned: trainer, quest or book, with a map button when it is in one place.
- **Recipes** (Alchemy, Blacksmithing, Cooking, Enchanting, Engineering, Leatherworking, Tailoring): the recipes sold by the Azeroth Commerce Authority / Durotar Supply camp vendors for Merchant's Favor, with profession skill, reputation needed, cost and a green check for the ones you know. Hover for the recipe tooltip; hold Shift to compare the crafted item with your equipped gear; shift-click links the recipe in chat.
- Interface chrome is translated (Spanish for now); guide content is English only.

## Craftsman's Writs

The **Writs** button at the top right (or `/writs`, `/writboard`) lists every **Craftsman's Writ**: the item it asks for, who takes it and where, the **Azeroth Commerce Authority** reputation it gives, and what it costs at the auction house. **Back** returns to the guide or the overview.

- **All** lists the 150 orders. **In bags** shows only the writs you carry, with how many of each; a writ the addon does not know yet still shows up there. **Vendor items** lists the other items sold for Merchant's Favor (tabards, Pack Kodo, Packmule Treat, Forger's Quill, certifications…).
- The **zone selector** shows only the zones you tick; **All zones** shows everything again. It is remembered per character.
- Writs are grouped by delivery zone, from best to worst value: the total price of their priced writs plus 50 silver for the trip, divided by the reputation they give. Zones without prices follow, and writs whose recipient is unknown come last. Each zone header shows its reputation, cost per reputation point and total cost.
- **Rep** is the reputation per delivery: 75 Journeyman, 125 Expert, 200 Artisan. **Deliver to** names the recipient; many Expert and Artisan recipients are still unknown.
- **Map** opens the delivery zone's map. A colored button also places a waypoint on the recipient; a grey one only opens the zone, as the exact spot is unknown.
- **Item price** is Auctionator's latest price for the requested item times the quantity asked, **Writ price** the price of the writ itself, and **Total** both. Scan the auction house with Auctionator to fill them in; without Auctionator they show a dash. Inside each zone, the cheapest total comes first.
- A green item name means you already have enough in your bags or bank. **Shift-click** a row to link the item or drop it into a search box; **Ctrl-click** previews it. The bottom line adds up the writs in your bags.

## Source and limits

Content comes from the [WoW Forever profession guides](https://www.wow-professions.com/forever) on wow-professions.com, written for the Forever beta. Higher ranges are often untested upstream, material totals are estimates, and route maps are not included. Each `Data/*.lua` file names its source page. Get permission from the guide's author before publishing a release.

Writ data comes from community guides ([conquestcapped.com](https://conquestcapped.com/guides/wow-forever/wow-forever-craftsmans-writs/) and [foreverchanges.pro](https://foreverchanges.pro/merchants-favor), November 15, 2026) and is English only. The 150 known writs are recognized by item ID; an unknown one only by its English name (`Craftsman's Writ: …`). Nine items have two versions (original and Forever recipe); both are counted and priced, but a writ may accept only one. Recipe and vendor data comes from [wow-professions.com](https://www.wow-professions.com/forever/merchants-favor-durotar-supply-azeroth-commerce) (November 25, 2026); the learned check reads the recipe's crafting spell and still needs confirming in the game.

Adding a profession means a new `Data/<Profession>.lua` in the same shape as the others, listed in the `.toc` and in `addon.guideOrder` (`Pages.lua`).

## Install and check

Copy or symlink this folder to `Interface\AddOns\ProfGuide`. From the repository root: `luajit ProfGuide/ProfGuide.test.lua` and `luajit ProfGuide/Writs.test.lua`. The check uses frame stubs and does not validate the real window layout.
