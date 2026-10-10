# WoW Forever Addons

Small addons to enjoy Azeroth your way: organize your plans and remember the players you meet along the way.

This collection brings together [luisjedev](https://github.com/luisjedev)'s addons for **World of Warcraft: Forever**. You can install each one independently.

## The addons

| Addon | What it does | How to open it |
| --- | --- | --- |
| **[TDL](TDL)** | Your in-game task list. Add plans, edit them, and mark what you have completed. | Minimap button, `/tdl`, or `/todo` |
| **[Revenge](Revenge)** | Keep a list of enemy players and recognize their nameplates with a marker and a distinctive style when the game allows identification. | Minimap button or `/rvg` |
| **DeathMark** | Remember where you died: your last 10 deaths with zone, coordinates, level and an optional short note. | Minimap button, `/deathmark`, or `/dm` |

Hover over a minimap icon for its controls: left-click to open or close, and drag with the left mouse button to move around the minimap. Position is saved per character, subject to the beta persistence limitation below.

**Testing preview:** [GuildStock](GuildStock/README.md) helps guildmates find profession materials. Its prototype provides a material browser, favorites, a character inventory view, a searchable inventory and display settings, opened with `/guildstock` or its chest minimap button. The bundled partial catalog supplies 589 materials and their observed profession associations on every installation. Version 1.0.0 remembers observed material IDs, includes their character-bank counts in the same total, preserves dated inventories received directly from their owners and automatically exchanges shared inventories at login, batching later changes for 30 seconds, subject to client restrictions. Each character sends only its own inventory; third-party history relaying is removed while retaining protocol-2 direct compatibility. Earlier versions delivered complete peer inventories to the local client; native multi-client validation of this update and cross-shard behavior remain pending. Settings reports communication status.

### TDL · Remember your plans

Unfinished quests, materials to gather, or plans for your next session. Create, edit, complete, and delete tasks in a movable classic gold-framed window that follows your game's language. All tasks share one vertically scrolling list. Click a truncated task to expand or collapse it, or double-click any task to edit its text directly. Edits save automatically when you leave the field, close the window, reload the UI, or log out. Delete stays visible to the right of each task, and the input at the bottom creates new tasks. The window opens on login or UI reload when you have unfinished tasks.

### Revenge · Some faces are worth remembering

Add your current target with one click or enter their first name and surname. Browse your list, delete entries, and spot saved players on their nameplates. The interface follows your game's language, with English as the fallback.

### DeathMark · Where you died

Each death is recorded automatically with date, level, zone and map coordinates, newest first, up to the last 10. Add a short note to the latest entry with `/dm nota <text>`. The interface follows your game's language, with English as the fallback.

## Installation

The addons will also be available from [my public CurseForge page (Artidev)](https://www.curseforge.com/members/artidev/projects) as they are published there.

To install them from this repository:

1. Download the repository using **Code → Download ZIP** and extract it.
2. Copy the `TDL` folder, the `Revenge` folder, the `DeathMark` folder, or any combination into `World of Warcraft/_classic_beta_/Interface/AddOns/`.
3. Check that the paths are `AddOns/TDL/TDL.toc`, `AddOns/Revenge/Revenge.toc`, and `AddOns/DeathMark/DeathMark.toc`.
4. Restart the game and enable the addons on the character selection screen.

Do not copy the entire repository folder into `AddOns`. You do not need development tools to play.

## Current status

The addons are in development for **WoW Forever beta**, with interface `16001`. Compatibility with Retail, Classic Era, or other versions is not assumed.

Forever replaces traditional realm selection with Normal (PvE), PvP and Roleplaying rulesets, with Hardcore planned after launch. Characters use a full first name and surname, unique within a region. For development, layers/shards are temporary world placement, not character or guild identities. See the shared [rulesets, layers and addon communication reference](docs/BLIZZARD_API.md#forever-rulesets-layers-and-addon-communications) for sources and testing requirements.

Some beta builds have shown problems restoring saved data after reloading the interface or closing the game. This can affect tasks and the enemy list. Game restrictions may also prevent Revenge from identifying certain players. See the [compatibility log](docs/BLIZZARD_API.md) for the builds reviewed and the tests still pending.

## Ideas and issues

You can [open an issue](https://github.com/luisjedev/wow-forever-addons/issues/new) to suggest improvements or report a problem. Include the addon, game version, and steps to reproduce it. Remove personal data from any screenshots or error reports before sharing them.

To contribute code, see the [development guide](docs/DEVELOPMENT.md).

An independent project with no affiliation with Blizzard Entertainment. World of Warcraft belongs to Blizzard Entertainment.
