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
