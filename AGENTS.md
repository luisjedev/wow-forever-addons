# Shared context

A collection of Lua addons for WoW Forever. Read `README.md`, `docs/DEVELOPMENT.md`, and `docs/BLIZZARD_API.md` before changing code. English is the repository's base language, including code, documentation, and the player-facing main README. Keep supported translations in locale tables.

- Each addon folder can be installed independently. Preserve folder names and `Interface\\AddOns\\...` paths.
- Use the client API and existing patterns. Share conventions and documentation; extract a common library only when actual duplication justifies it.
- Identify the product, version, build, and interface before assuming compatibility. Forever is neither Classic Era nor Retail.
- Consult sources for the matching build and record discovered limitations, evidence, affected addons, and pending tests in `docs/BLIZZARD_API.md`. Do not claim a bug is fixed merely because the version changed.
- Respect secret values, combat restrictions, and protected frames. Do not try to bypass them. A function's existence does not guarantee permission to operate on its result.
- Preserve SavedVariables, review every initialization path, and do not overwrite valid data during recovery or migration.
- `.local/` contains private backups and recovery data. Never publish it, read it to write public documentation, or use `git add -f`. Do not upload WTF, accounts, real GUIDs, player lists, tokens, or personal paths.
- Work in the repository; the `Interface/AddOns` symlinks point here. Tests can affect the local client: verify in the game with `/reload` and restart it when adding addons.
- Run the syntax check and tests described in `docs/DEVELOPMENT.md`. Tests outside the game do not validate nameplates, combat, or actual persistence.
- Keep changes small, without dependencies or speculative shared layers. Maintain tests for affected logic and avoid unnecessary changes to other addons.
- After completing and validating repository changes, always commit and push them to GitHub without asking again, unless the user explicitly requests otherwise. Include only the task's reviewed files, preserve unrelated work, never force-push, and report any blocker that prevents publishing.

For CurseForge project creation, updates, screenshots, or releases, use the repository skill at [.agents/skills/curseforge-publish/SKILL.md](.agents/skills/curseforge-publish/SKILL.md).
