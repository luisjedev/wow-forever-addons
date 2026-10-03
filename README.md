# WoW Forever Addons

Small addons to enjoy Azeroth your way: organize your plans and remember the players you meet along the way.

This collection brings together [luisjedev](https://github.com/luisjedev)'s addons for **World of Warcraft: Forever**. You can install each one independently.

## The addons

| Addon | What it does | How to open it |
| --- | --- | --- |
| **[TDL](TDL)** | Your in-game task list. Add plans, edit them, and mark what you have completed. | Minimap button, `/tdl`, or `/todo` |
| **[Revenge](Revenge)** | Keep a list of enemy players and recognize their nameplates with a marker and a distinctive style when the game allows identification. | Minimap button or `/rvg` |

Hover over either minimap icon for its controls: left-click to open or close, and drag with the left mouse button to move around the minimap. Position is saved per character, subject to the beta persistence limitation below.

**In development:** [GuildStock](GuildStock/README.md) will help guildmates find profession materials. Its prototype provides a material browser, favorites, a searchable bag inventory and display settings, opened with `/guildstock` or its crate minimap button. The catalog is partial. Guild sharing remains pending; Settings reports the realm restriction observed during testing.

### TDL · Remember your plans

Unfinished quests, materials to gather, or plans for your next session. Create, edit, complete, and delete tasks in a movable window that follows your game's language. All tasks share one vertically scrolling list. Click a truncated task to expand or collapse it, or double-click any task to edit its text directly. Edits save automatically when you leave the field, close the window, reload the UI, or log out. Delete stays visible below each task, and the input at the bottom creates new tasks. The window opens on login or UI reload when you have unfinished tasks.

### Revenge · Some faces are worth remembering

Add your current target with one click or enter their first name and surname. Browse your list, delete entries, and spot saved players on their nameplates. The interface follows your game's language, with English as the fallback.

## Installation

The addons will also be available from [my public CurseForge page (Artidev)](https://www.curseforge.com/members/artidev/projects) as they are published there.

To install them from this repository:

1. Download the repository using **Code → Download ZIP** and extract it.
2. Copy the `TDL` folder, the `Revenge` folder, or both into `World of Warcraft/_classic_beta_/Interface/AddOns/`.
3. Check that the paths are `AddOns/TDL/TDL.toc` and `AddOns/Revenge/Revenge.toc`.
4. Restart the game and enable the addons on the character selection screen.

Do not copy the entire repository folder into `AddOns`. You do not need development tools to play.

## Current status

The addons are in development for **WoW Forever beta**, with interface `16001`. Compatibility with Retail, Classic Era, or other versions is not assumed.

Some beta builds have shown problems restoring saved data after reloading the interface or closing the game. This can affect tasks and the enemy list. Game restrictions may also prevent Revenge from identifying certain players. See the [compatibility log](docs/BLIZZARD_API.md) for the builds reviewed and the tests still pending.

## Ideas and issues

You can [open an issue](https://github.com/luisjedev/wow-forever-addons/issues/new) to suggest improvements or report a problem. Include the addon, game version, and steps to reproduce it. Remove personal data from any screenshots or error reports before sharing them.

To contribute code, see the [development guide](docs/DEVELOPMENT.md).

An independent project with no affiliation with Blizzard Entertainment. World of Warcraft belongs to Blizzard Entertainment.
