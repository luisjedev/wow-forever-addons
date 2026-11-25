# WritBoard

A list of every **Craftsman's Writ** in WoW Forever: the item each one asks for, who takes it and where, the **Azeroth Commerce Authority** reputation it gives, and what the item costs at the auction house.

Open it with `/writs` (or `/writboard`), or click **WritBoard** in the minimap's addon list.

- **All** lists the 150 orders. **In bags** shows only the writs you are carrying, with how many of each. A writ the addon does not know yet still shows up there.
- The **zone selector** shows only the zones you tick (any number of them); **All zones** shows everything again. It works together with All / In bags and is remembered per character.
- Writs are grouped by the zone where you deliver them. Zones go from best to worst value: the total price of their priced writs plus 50 silver for the trip, divided by the reputation they give. Doing several writs in one zone shares the trip, so busy zones usually come first. Zones without prices follow, and writs whose recipient is unknown are grouped at the end.
- Each zone header shows the reputation, cost per reputation point and total cost of its priced writs.
- **Rep** is the reputation per delivery: 75 Journeyman, 125 Expert, 200 Artisan.
- **Deliver to** names the recipient. Many Expert and Artisan recipients are still unknown.
- **Map** opens the delivery zone's map. A colored button also places a waypoint on the recipient (Journeyman orders, where coordinates are published); a grey one only opens the zone, since the exact spot is unknown.
- **Item price** is Auctionator's latest price for the requested item, times the quantity asked. **Writ price** is the price of the writ itself, and **Total** adds both, so you can see what buying the writ and its items would cost. Scan the auction house with Auctionator to fill them in. Without Auctionator they show a dash.
- Inside each zone, writs go from the cheapest total to the most expensive; writs missing a price go last.
- An item name in green means you already have enough of it in your bags or bank. Hover a row for the item tooltip, tier, skill and how many you have.
- **Shift-click** a row to link the requested item in chat or drop it into a search box, such as the auction house's. **Ctrl-click** previews it.
- The bottom line adds up the writs in your bags: how many, total reputation and total cost.
- **Recipes** shows one tile per profession sold at the camps (Alchemy, Blacksmithing, Cooking, Enchanting, Engineering, Leatherworking, Tailoring) plus **Other items** (tabards, Pack Kodo, Packmule Treat, Forger's Quill, certifications…). Each tile counts how many of its recipes you know. Open one to see all 308 recipes with the profession skill, the reputation needed, the cost in Merchant's Favor and a green check for the ones you have learned. Hover for the recipe tooltip; shift-click links it in chat.

## Limits

- Recipe and vendor data comes from [wow-professions.com](https://www.wow-professions.com/forever/merchants-favor-durotar-supply-azeroth-commerce) (November 25, 2026). The learned check reads the recipe's crafting spell and still needs confirming in the game.
- Writ data comes from community guides ([conquestcapped.com](https://conquestcapped.com/guides/wow-forever/wow-forever-craftsmans-writs/) and [foreverchanges.pro](https://foreverchanges.pro/merchants-favor), November 15, 2026) and is English only.
- The 150 known writs are recognized by item ID. A writ missing from the data is only recognized by its English name (`Craftsman's Writ: …`).
- Nine items have two versions (the original recipe and a Forever one). The addon counts and prices both, but a writ may accept only one of them.
