# WritBoard 0.1.0-snapshot-8

- Zone selector next to the All / In bags buttons: tick one or more zones to list only those, or pick **All zones** to show everything again. It combines with In bags, and the selection is saved per character.

# WritBoard 0.1.0-snapshot-7

- New **Map** column. Every writ with a known zone gets a map button: in color it opens the map with a waypoint on the recipient; greyed out it opens the zone map, as the exact spot is not published yet. Riverglades (new in Forever) has no map button yet.

# WritBoard 0.1.0-snapshot-6

- Zones are ordered by value: the cost per reputation point of doing all their priced writs, plus a fixed 50 silver for the trip. A zone with several writs shares one trip, so 3 writs for 1g 50s (about 89 copper per reputation point) come before a single writ for 70 silver (160 copper). Zones without prices follow, and the unknown zone stays last.
- Each zone header shows how many of its writs have a price, their total reputation, the cost per reputation point and their total cost.

# WritBoard 0.1.0-snapshot-5

- Two new columns: **Writ price** (Auctionator price of the writ itself) and **Total** (writ plus the items it asks for). The window is wider to fit them.
- Inside each zone, writs are sorted by total, cheapest first; writs without both prices go last.
- Writs in your bags are recognized by item ID. Four writs whose in-game name differs from the guides (for example *Elixir of Ogre's Strength*) were not detected before, and the In bags filter now works in any client language for the 150 known writs.

# WritBoard 0.1.0-snapshot-4

- Shift-click a writ to link its requested item in chat or put it in a search box such as the auction house's; Ctrl-click previews it. If the item is not cached yet, Shift-click inserts its name.

# WritBoard 0.1.0-snapshot-3

- The list is grouped by recipient zone instead of by profession. Zones with Artisan orders come first and unknown recipients last; inside each zone, writs go from most to least reputation.

# WritBoard 0.1.0-snapshot-2

- Fixed the Lua error when opening the window: item counts and icons now use `C_Item.GetItemCount` and `C_Item.GetItemIconByID`, as the global functions are not available in Forever.

# WritBoard 0.1.0-snapshot-1

- New addon: a window listing all 150 Craftsman's Writs with the requested item, recipient and zone, reputation (75/125/200), and Auctionator price. Filter **All** / **In bags**, map waypoints for the Journeyman recipients, and a total for the writs you carry. `/writs` or the minimap's addon list.

Syntax and logic checks pass. Not yet verified in the game.
