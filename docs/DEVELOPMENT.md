# Development

## One working copy

The repository is where editing, commits, and publishing happen. `Interface/AddOns` contains symlinks to the addon folders:

```text
WoW Forever Addons/
├── TDL/                 ← Interface/AddOns/TDL
├── Revenge/             ← Interface/AddOns/Revenge
├── docs/
├── AGENTS.md
└── .local/              (private, excluded from Git)
```

The game reads the same files you edit. There is no need to copy changes or keep two versions in sync. GitHub stores the history and lets you share it; daily work happens in your local clone.

The symlinks are already set up on this machine. Open the **WoW Forever Addons** folder on the desktop as a project in your editor or in Codex to include the shared instructions.

To set up another Mac or a Linux installation, replace the paths in this example:

```sh
repo="$HOME/Desktop/WoW Forever Addons"
addons="/Applications/World of Warcraft/_classic_beta_/Interface/AddOns"
ln -s "$repo/TDL" "$addons/TDL"
ln -s "$repo/Revenge" "$addons/Revenge"
```

The destinations must be unused: if folders already exist, back them up outside `AddOns` first. Do not use `ln -sf` to replace them blindly. On Windows, use a directory junction with `mklink /J`. If you move the repository, update the links.

## Workflow

1. Edit the addon inside the repository.
2. Check syntax and logic outside the game.
3. Use `/reload` to reload Lua. Restart the client when adding a new addon or if it does not detect manifest changes.
4. Test behavior and actual persistence in the specified client build.
5. Review `git diff`, commit, and push from this repository.

Switching branches immediately changes the files that the next `/reload` will read. Each addon keeps its own `.toc`, version, and SavedVariables. Their names are preserved so WoW can still find existing data in `WTF`; that data is not part of the repository.

## Checks

From the repository root, with Lua 5.1 or LuaJIT installed:

```sh
luajit -e 'for _, p in ipairs({"TDL/Locales.lua", "TDL/TDL.lua", "Revenge/Locales.lua", "Revenge/Revenge.lua", "Revenge/Revenge.test.lua"}) do assert(loadfile(p)) end'
(cd Revenge && luajit Revenge.test.lua)
```

You can replace `luajit` with `lua5.1`. GitHub Actions runs the same checks. They do not emulate the WoW API: test TDL, Revenge nameplates, entering and leaving combat, zone changes, and saving after `/reload` and a restart in the game.

## Private recovery for this installation

The originals were preserved in `.local/originals/` during migration. Revenge contained recovery data for a specific character. That data was moved to an optional local addon, `.local/WoWForeverLocal/`, also linked from `Interface/AddOns` and excluded from Git.

Revenge works without that addon; its dependency is optional. On this machine, keep **WoW Forever Local** enabled to preserve beta recovery. It only applies to the configured character with an empty list and an older revision. It does not replace a backup of `WTF` or guarantee that the client fixes its SavedVariables loader. Restart the game after this migration so it discovers the local addon.

Do not distribute `.local/`. Remove the recovery mechanism once native persistence has been validated; preserve the data first. The original backups are a snapshot of the migration, not a second working folder.

## API tracking

`docs/BLIZZARD_API.md` maintains the history by product and build, sources, and pending tests. A daily Codex task checks the installed version and the interface code published on the `forever` branch of the Gethe/wow-ui-source mirror. Its schedule is tied to this Codex installation; cloning the repository does not install it.

The review is scheduled for **10:00, Madrid time**. To access local files, the computer must be on and the app running; see the [scheduled tasks documentation](https://learn.chatgpt.com/docs/automations?surface=app).

When the task finds a new build or relevant evidence, it updates the documentation and publishes only those changes, if Git's state allows it without mixing in pending work. It does not automatically change addon code or the interface number in `.toc` files. It does not claim in-game validation that has not taken place. If a source is unavailable, it keeps the last evidence and reports the blocker.
