# WritBoard

A list of every **Craftsman's Writ** in WoW Forever: the item each one asks for, who takes it and where, the **Azeroth Commerce Authority** reputation it gives, and what the item costs at the auction house.

Open it with `/writs` (or `/writboard`), or click **WritBoard** in the minimap's addon list.

- **All** lists the 150 orders. **In bags** shows only the writs you are carrying, with how many of each. A writ the addon does not know yet still shows up there.
- Writs are grouped by the zone where you deliver them, with the highest-reputation zones first and writs ordered from most to least reputation. Writs whose recipient is unknown are grouped at the end.
- **Rep** is the reputation per delivery: 75 Journeyman, 125 Expert, 200 Artisan.
- **Deliver to** names the recipient. The map button places a waypoint where coordinates are published (Journeyman orders). Many Expert and Artisan recipients are still unknown.
- **Auction** is Auctionator's latest price for the requested item, times the quantity asked. Scan the auction house with Auctionator to fill it in. Without Auctionator it shows a dash.
- An item name in green means you already have enough of it in your bags or bank. Hover a row for the item tooltip, tier, skill and how many you have.
- The bottom line adds up the writs in your bags: how many, total reputation and total cost.

## Limits

- Writ data comes from community guides ([conquestcapped.com](https://conquestcapped.com/guides/wow-forever/wow-forever-craftsmans-writs/) and [foreverchanges.pro](https://foreverchanges.pro/merchants-favor), November 15, 2026) and is English only.
- Writs are recognized by their English name (`Craftsman's Writ: …`). Other client languages are not supported yet.
- Nine items have two versions (the original recipe and a Forever one). The addon counts and prices both, but a writ may accept only one of them.
