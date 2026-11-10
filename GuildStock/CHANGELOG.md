# GuildStock 1.1.1

- Stop bag items flickering after each crafted item: profession updates no longer hide every useful-material badge before redrawing them.
- Remove the **Scan all prices** button and the automatic full auction scan on opening the auction house. In the game the full scan froze the client, gave little feedback and saved no prices. Prices now update only from the commodity/item searches you make in the auction house, which already worked.
Lua syntax and all repository suites pass, including a regression for the crafting flicker. Not yet verified while crafting in the game. No saved-data or protocol change; 1.0.x and 1.1.0 clients stay compatible. Target: WoW Forever 1.60.1, interface 16001.

# GuildStock 1.1.0

- Shift-click an item row, or its icon, in GuildStock to link it in the focused chat box or paste it into the auction house search, like a bag item.
- Add a **Scan all prices** button to Materials. While the auction house is open it requests a full auction replication on demand, bypassing only the addon's own 15-minute cooldown, and reports in chat when the scan starts, how many prices were saved, or that the server did not respond.
- Fix auction scans discarding prices for records whose seller names were still loading; nearly every material price from a bulk scan was dropped.
- Process scan batches in larger groups so a later replication event cannot cancel a long scan.

Lua syntax and all repository suites pass. Shift-click linking to chat verified in the game after `/reload`; auction search insertion, the reworked scan button and multi-client validation remain pending. No saved-data or protocol change; 1.0.x clients stay compatible. Target: WoW Forever 1.60.1, interface 16001.

# GuildStock 1.0.1

- Show "Useful for" in bag tooltips with bag addons such as Bagnon, and with any other native bag-item tooltip. Blizzard bag buttons keep their search filter behavior.
- Mark useful materials on Bagnon's item buttons too, using the existing size and enable settings. Bagnon stays optional.
- Accept guild packets from any verified guild member, even when the local roster still shows them offline. A received packet proves presence; previously a later login could stay invisible to earlier clients in both directions.
- Refresh the native guild roster every 60 seconds so readiness and Online/Offline status no longer depend on opening the guild window. This requests no addon traffic.
- Keep listening during combat with the last verified roster. Replies still wait until combat ends.
- `/guildstock probe` follows the same presence rule. `/guildstock diagnostics` adds `sync rejected` and `sync lastRejected`.

Lua syntax and all repository suites pass, including stale-roster and combat regressions verified to fail without their fixes. No saved-data or protocol change; 1.0.0 clients stay compatible but keep their own limits. Native validation with several clients on the launch build remains pending. Target: Forever 1.60.1, build 70790.

# GuildStock 1.0.0

- Fix the Characters header so primary-profession information cannot overlap the inventory subtitle when a character has a short name.
- Replace the brown profession bars with an original blue-gradient texture and the native profession progress border. Keep the fixed 0–300 scale and unknown-level display.
- Retain the direct-owner inventory synchronization, sharing controls, local auction estimates and saved-data behavior from 0.5.1.

Lua syntax and all eight repository suites pass. The updated profession bars and short-name layout were verified in the game after `/reload`. Multi-client validation of direct-owner synchronization, cross-shard delivery, full-restart persistence and other scales/locales remain pending. Target: WoW Forever 1.60.1, build 70205, interface 16001.

# GuildStock 0.5.1

- Each character now sends only its own inventory. Remove offline-inventory forwarding through other guild members and ignore legacy relay traffic.
- Keep the existing protocol-2 prefix, direct message formats, GUILD transport, startup discovery, acknowledgements, 30-second batching, privacy withdrawals and bounded retries. Direct synchronization remains compatible with 0.4.x and 0.5.0; update every participant to stop relaying on every client.
- Retain dated inventories received directly from their owners. Remove saved records explicitly marked as relayed so fabricated revisions cannot block a returning owner's direct update. Preserve local inventory, auction prices, preferences and unsupported saved schemas.

Lua syntax and all eight repository suites pass, including relay rejection, saved-history migration and mixed direct exchanges with the unmodified 0.5.0 sync module. Native reload and multi-client validation of this update remain pending. Target: Forever 1.60.1, build 70205, interface 16001.

# GuildStock 0.5.0

- Add local estimated auction buyout prices per unit beside the material title and beneath item names in Materials, Favorites, My inventory, Not shared and Characters.
- Read auction snapshots during visits and completed item searches; preserve earlier prices and dates when fresh data is unavailable. Prices are saved per character and never synchronized with guildmates.
- Add a transparent clock with localized update age: neutral through 12 hours, orange after 12 hours, red after 24 hours. Stale and unknown prices prompt a visit to the auction house.

Lua syntax and all eight repository suites pass. Native unknown-price layout verified after reload; live auction acquisition, populated prices and reload/restart persistence remain pending. Target: Forever 1.60.1, build 70205, interface 16001.

# GuildStock 0.4.4

- Show the selected guildmate’s actual primary-profession levels shared by their own GuildStock, using the existing vertical 0–300 bars. Stop using unreliable native guild ranks.
- Add optional level metadata while retaining protocol 2, its prefix, all existing inventory message formats, GUILD transport, batching, acknowledgements and retries. Older protocol-2 versions continue exchanging inventories; unavailable levels show `?`.
- Save received levels with the owner’s matching inventory revision for offline display. Offline inventory relay behavior is unchanged; relays do not forward levels.

# GuildStock 0.4.3

- Show the selected character's two primary professions beside their name in two stacked rows, with icons and progress bars on a fixed 0–300 scale.
- Read profession ranks directly from the native guild roster. Missing or restricted data shows `?`; secondary professions are omitted. No new synchronization packets, SavedVariables fields or remote addon update are required for these ranks.

Lua syntax and all seven repository suites pass. Target: WoW Forever 1.60.1, build 70205, interface 16001. Existing inventory protocol and persistence limitations remain unchanged.

# GuildStock 0.4.2

- Reuse the prepared inventory between changes and check sharing permissions without copying items, reducing temporary memory allocation while idle. Preserve the 30-second change batch, immediate privacy withdrawals and bounded discovery retries.
- Retry startup discovery after approximately 15 and 45 seconds so delayed guild presence or lost initial messages do not leave clients permanently undiscovered in the reproduced cases. Retries are bounded and preserve the existing messaging restrictions.
- Extend the optional `/guildstock probe` diagnostic to five minutes with 15-second retries, remaining-time and request counters, and recovery from lost acknowledgements.
- Preserve protocol-2 compatibility with 0.4.0 and 0.4.1, saved inventories, sharing preferences and offline history. Install 0.4.2 on all participants to receive the startup correction on each client; 0.3.x uses an incompatible protocol.

Lua syntax and all seven repository test suites pass, including delayed presence, dropped messages, privacy, offline-history relay and forty simultaneous clients. The startup regression was reproduced against 0.4.1 and compared with 0.3.2. This release has not yet been verified end to end with two native game clients.

Target: WoW Forever 1.60.1, build 70205, interface 16001. Replace the existing `GuildStock` addon folder with the folder from this ZIP and reload the UI. Do not remove SavedVariables.
