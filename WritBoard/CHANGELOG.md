# WritBoard 0.1.0-snapshot-3

- The list is grouped by recipient zone instead of by profession. Zones with Artisan orders come first and unknown recipients last; inside each zone, writs go from most to least reputation.

# WritBoard 0.1.0-snapshot-2

- Fixed the Lua error when opening the window: item counts and icons now use `C_Item.GetItemCount` and `C_Item.GetItemIconByID`, as the global functions are not available in Forever.

# WritBoard 0.1.0-snapshot-1

- New addon: a window listing all 150 Craftsman's Writs with the requested item, recipient and zone, reputation (75/125/200), and Auctionator price. Filter **All** / **In bags**, map waypoints for the Journeyman recipients, and a total for the writs you carry. `/writs` or the minimap's addon list.

Syntax and logic checks pass. Not yet verified in the game.
