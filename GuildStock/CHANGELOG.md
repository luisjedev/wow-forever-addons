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
