# MissingBuffs 0.1.0-snapshot-3

- The rested icon now tracks the **Well-Rested** buff from the Cozy Sleeping Bag (spell 429959) instead of rested experience, and uses its icon. It still only shows below the level cap.

Syntax and logic checks pass. Not yet verified in the game.

# MissingBuffs 0.1.0-snapshot-2

- MissingBuffs now appears in the minimap's addon list with a food icon. Click it to show all three icons on a blue placeholder and drag the row anywhere; click it again to lock it. The position is saved (`MissingBuffsDB`).

After `/reload` the minimap addon counter went from 7 to 8, so the entry is registered. Not yet verified in the game: opening the list, dragging, and the saved position after `/reload`.

# MissingBuffs 0.1.0-snapshot-1

- A row of icons in the middle of the screen shows which of these you are missing: **Well Fed**, **rested experience** (only below the level cap) and **Find Minerals** (only if you know it). Present buffs are hidden, so the row disappears when you have all three.

Checked in the game (build with interface 16001): loads without errors, the row is empty with all three active, and the Find Minerals icon appears after `/cancelaura Find Minerals` and hides again after recasting it.
