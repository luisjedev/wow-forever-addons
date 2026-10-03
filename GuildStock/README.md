# GuildStock · Interface prototype 0.2.0

An in-development implementation of the [GuildStock design](PLAN.md), targeting **WoW Forever beta 1.60.1, build 70205, interface 16001**. The interface follows the agreed mockups: dark panels with gold accents, three top tabs, and a three-column material browser. The catalog is partial and guild inventory sharing is not active yet.

Copy this folder into the client's `Interface/AddOns`, restart the client, and enable GuildStock. Open the movable window with `/guildstock` or its crate minimap button. Left-drag the button to reposition it. English and Spanish (`esES` and `esMX`) are supported; other languages fall back to English.

## Available now

- **Materials:** search, All materials / Favorites, one profession filter in the sidebar with All professions first, item icons and favorite stars. The detail table keeps Player, Bags, Last online and Whisper headings. It shows a waiting or realm-restriction notice while no guild data is available; it never invents owners or counts.
- **My inventory:** a full-width searchable table of discovered profession materials and actual bag quantities. Bound counts and observation time appear in row tooltips.
- **Settings:** offline-member display preference, minimap visibility, opening view and window scale. Synchronization status is read-only and appears here, with no footer indicator or manual synchronization controls. A restricted realm is never presented as active sharing.
- Bag events coalesce into complete observations. Missing, inaccessible, locked, inconsistent or not-yet-loaded bags preserve the previous observation. Scanning resumes after combat. A successful empty observation removes previous quantities. No bank is scanned.
- `GuildStockDB` preserves bag observations, discovered materials, favorites and display preferences per character. Unsupported schemas stay untouched and use temporary runtime data. The beta's historical persistence limitation remains open.

The **partial catalog** is built from the current client's crafting-reagent item flag and reagents in accessible recipes when a profession window is opened. Only observed recipe data establishes profession relationships. Discovered materials remain searchable after their bag quantity reaches zero; this is not an exhaustive Forever catalog. No Classic/Retail list or mock player data is shipped.

All materials is the default opening view. The removed For my professions preference is migrated to All materials; existing favorites and other preferences are preserved.

`/guildstock diagnostics` prints the build/interface, prefix and send results, probe counts and learned professions locally. It does not print character names, GUIDs or the roster.

## Two-client communication check

The developer-only `/guildstock probe` command arms a 60-second test and sends one short GUILD probe. While armed, another copy can reply by addon WHISPER. No bag contents are sent. Normal login, bag changes and opening the window send no packets in this prototype.

1. Install the prototype on two consenting guild clients in the same realm. Check Settings and `/guildstock diagnostics` on both and record the build, interface, restriction and prefix result. The development realm reported outgoing addon messages restricted on October 3; the probe stops in that state.
2. Run `/guildstock probe` on client A, then on client B about 30 seconds later. A should count a received probe and send a WHISPER reply; B should count one confirmed round trip.
3. After A's 60-second cooldown, run its probe again while B's test remains active. B should reply and A should count one confirmed round trip. `Success` from sending alone is **not** evidence of receipt.
4. If senders are unmatched, investigate Forever's roster/address representation. The prototype requires an exact accessible `C_Club` member-name match with online/away/busy presence and excludes self. It deliberately does not guess surname/realm normalization. Do not publish the actual names or member records.

Probes expire and are cancelled on guild or world transitions. Replies are limited to five peers, once per sender, at least two seconds apart. Unknown senders, mobile/offline presence, malformed packets, duplicates, unsupported versions, and unsolicited acknowledgements are rejected. A throttle or lockdown is reported without retries or ordinary-chat fallback. These conservative prototype limits are not claims about Blizzard's rate limits. This is not the production inventory protocol or a roster-completeness guarantee.

## Remaining local checks

Compare several bag stacks, including bound and unbound copies, against the window. Loot, craft, trade, sell and remove the final stack; check reagent bags if available. Verify item names finish loading, a missing read retains its dated snapshot, combat recovery, scrolling, Escape and minimap dragging. Confirm data and minimap position survive `/reload` and a full restart without editing personal SavedVariables files.

The full catalog audit, guild inventory synchronization, departure cleanup, player rows and Whisper drafts still depend on the API feasibility check. The offline-display setting is saved in preparation for real peer records; it has no rows to filter yet. Record observed results and remaining limitations in [the compatibility log](../docs/BLIZZARD_API.md); offline checks do not complete that gate.
