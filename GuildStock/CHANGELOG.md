# GuildStock 0.4.2

- Retry startup discovery after approximately 15 and 45 seconds so delayed guild presence or lost initial messages do not leave clients permanently undiscovered in the reproduced cases. Retries are bounded and preserve the existing messaging restrictions.
- Extend the optional `/guildstock probe` diagnostic to five minutes with 15-second retries, remaining-time and request counters, and recovery from lost acknowledgements.
- Preserve protocol-2 compatibility with 0.4.0 and 0.4.1, saved inventories, sharing preferences and offline history. Install 0.4.2 on all participants to receive the startup correction on each client; 0.3.x uses an incompatible protocol.

Lua syntax and all seven repository test suites pass, including delayed presence, dropped messages, privacy, offline-history relay and forty simultaneous clients. The startup regression was reproduced against 0.4.1 and compared with 0.3.2. This release has not yet been verified end to end with two native game clients.

Target: WoW Forever 1.60.1, build 70205, interface 16001. Replace the existing `GuildStock` addon folder with the folder from this ZIP and reload the UI. Do not remove SavedVariables.
