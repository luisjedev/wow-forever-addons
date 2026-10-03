# GuildStock · API prototype 0.1.0

The first implementation stage of the [GuildStock plan](PLAN.md), targeting **WoW Forever beta 1.60.1, build 70205, interface 16001**. This is a development tool for checking the APIs before implementing the material catalog and shared inventories. It is not the finished interface shown in the mockups.

Copy this folder into the client's `Interface/AddOns`, restart the client, and enable GuildStock. Open the movable window with `/guildstock` or its crate minimap button. Left-drag the button to reposition it. English and Spanish (`esES` and `esMX`) are supported; other languages fall back to English.

## Available now

- **My bags** lists all observed bag items, their total counts, bound counts, and observation time. These items are not yet classified as profession materials. Bound status alone does not certify tradeability.
- Bag events coalesce into a complete observation. Missing, inaccessible, locked, inconsistent or not-yet-loaded bags preserve the previous observation. Scanning resumes after combat. A successful empty observation removes previous counts. No bank is scanned.
- `GuildStockDB` stores the character's latest complete observation and minimap angle. Unsupported schemas stay untouched and use temporary runtime data. Native persistence still needs validation against the beta's known SavedVariables limitation.
- **Diagnostics** shows the live build/interface, realm messaging restriction, native registration/sending result names, probe counts, and learned professions. It does not print character names, GUIDs or the roster.

## Two-client communication check

The developer-only `/guildstock probe` command arms a 60-second test and sends one short GUILD probe. While armed, another copy can reply by addon WHISPER. No bag contents are sent. Normal login, bag changes and opening the window send no packets in this prototype.

1. Install the prototype on two consenting guild clients in the same realm. Check Diagnostics on both and record the build, interface, restriction and prefix result.
2. Run `/guildstock probe` on client A, then on client B about 30 seconds later. A should count a received probe and send a WHISPER reply; B should count one confirmed round trip.
3. After A's 60-second cooldown, run its probe again while B's test remains active. B should reply and A should count one confirmed round trip. `Success` from sending alone is **not** evidence of receipt.
4. If senders are unmatched, investigate Forever's roster/address representation. The prototype requires an exact accessible `C_Club` member-name match with online/away/busy presence and excludes self. It deliberately does not guess surname/realm normalization. Do not publish the actual names or member records.

Probes expire and are cancelled on guild or world transitions. Replies are limited to five peers, once per sender, at least two seconds apart. Unknown senders, mobile/offline presence, malformed packets, duplicates, unsupported versions, and unsolicited acknowledgements are rejected. A throttle or lockdown is reported without retries or ordinary-chat fallback. These conservative prototype limits are not claims about Blizzard's rate limits. This is not the production inventory protocol or a roster-completeness guarantee.

## Remaining local checks

Compare several bag stacks, including bound and unbound copies, against the window. Loot, craft, trade, sell and remove the final stack; check reagent bags if available. Verify item names finish loading, a missing read retains its dated snapshot, combat recovery, scrolling, Escape and minimap dragging. Confirm data and minimap position survive `/reload` and a full restart without editing personal SavedVariables files.

The full catalog, profession mappings, guild inventory synchronization, departure cleanup, favorites, player rows and Whisper drafts follow the API feasibility check. Record observed results and remaining limitations in [the compatibility log](../docs/BLIZZARD_API.md); offline checks do not complete that gate.
