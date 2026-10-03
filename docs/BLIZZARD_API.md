# Blizzard Lua API compatibility and limitations

This log covers the **API inside the WoW client**: Lua functions, events, frames, secret values, and SavedVariables. It does not cover the Battle.net HTTP API.

It is extended for each version and build that affects our addons. It does not aim to certify every historical WoW version. A release version can include several builds with API differences even when the `Interface` number stays the same.

## Current reference

| Field | Value |
| --- | --- |
| Development product | `wow_classic_beta` · WoW Forever |
| Installed client observed on October 3, 2026 | `1.60.1.70205` |
| Interface declared by TDL and Revenge | `16001` |
| Blizzard code source | [Gethe/wow-ui-source, forever branch](https://github.com/Gethe/wow-ui-source/tree/forever) |
| Latest source revision consulted | [`e3ecc27` · 1.60.1 (70205), October 3, 2026](https://github.com/Gethe/wow-ui-source/commit/e3ecc27b64d30fdc735a3f6579b866858f9f9df1) |
| Last review of this log | October 3, 2026; guild materials planning only |

The installed version comes from the `wow_classic_beta` product row in `.build.info`. The interface value comes from our `.toc` files; it is not evidence of a client test. In the game, `/dump GetBuildInfo()` lets you check the version, build, and interface number.

Gethe is a **community mirror of Blizzard's interface code**, not an official service or a guarantee of immediate publication. We chose `forever` because its commit identifies the same build as the installed client. Do not assume the `classic_beta` branch still represents Forever.

## History

| Product / version / build | Evidence | Limitations and status |
| --- | --- | --- |
| Forever beta · 1.60.1 · 69913 | Earlier note included in [TDL/README.txt](../TDL/README.txt) | A failure to restore SavedVariables after reload or exit was documented. This is a historical project record, not official confirmation or a new reproduction. |
| Forever beta · 1.60.1 · 70009 | Local installation and source review at `bd2470a` | Identity restrictions and signatures reviewed in source. Persistence, combat, and nameplates still require validation in this build. The earlier failure is not considered fixed. |
| Forever beta · 1.60.1 · 70205 | Local installation and source review at `e3ecc27` | Guild addon messaging, inventory, bank, and profession APIs reviewed for a proposed addon. No new in-game validation; previous addon limitations remain unresolved. |

## Guild materials feasibility review October 3 2026

Product `wow_classic_beta`, installed version `1.60.1.70205`, matches source revision `e3ecc27`. Existing addons declare interface `16001`; the running client's interface value still needs `GetBuildInfo()` verification. This review supports the [guild materials implementation plan](GUILD_MATERIALS_PLAN.md); it does not revalidate TDL or Revenge.

| Area | Documented in source | Consequence and pending verification |
| --- | --- | --- |
| Addon transport | `C_ChatInfo.RegisterAddonMessagePrefix`, `SendAddonMessage`, and `CHAT_MSG_ADDON` expose prefix registration, payload transport, and sender/channel metadata. Registration and sending return result enums, not success booleans. | Proposed transport uses `GUILD` with a dedicated prefix. Prove bidirectional delivery between two guild members on this realm before implementing distributed inventory. A successful send result alone does not prove receipt. |
| Messaging restrictions | `AreOutgoingAddonChatMessagesRestricted()` documents realm-dependent restrictions and independent control of receiving. `SendAddonMessage` rejects secret arguments. Result enums include `AddOnMessageLockdown`, `AddonMessageThrottle`, `ChannelThrottle`, `NotInGuild`, and `TargetOffline`. | Respect restrictions, handle the actual enums, and stop rather than switching to visible chat to evade a restriction. Exact byte/rate limits and `GUILD`/`WHISPER` behavior remain runtime tests; no Retail or Classic limit is certified here. |
| Bags | `C_Container.GetContainerNumSlots` and `GetContainerItemInfo` expose slots, `itemID`, `stackCount`, and `isBound`; `BAG_UPDATE_DELAYED` is documented. | Scan only accessible values on the local character. Verify event coverage for looting, crafting, selling, and trading. Inaccessible or incomplete reads must not replace known counts with zero. |
| Bank | Camelot's `BankFrame.lua` uses `C_Bank.FetchPurchasedBankTabData`, `CanViewBank`, and container reads using returned tab IDs. `BagIndex` distinguishes character and account bank tabs. `BANKFRAME_OPENED`, `BANKFRAME_CLOSED`, and bank update events are documented. | Do not copy Classic bank bag IDs. Initial scope is the character bank. Capture complete readable snapshots while visiting the bank, retain the observation date outside it, and test transfers between bags and bank without double counting. Account and guild banks need separate ownership models and are deferred. |
| Bank counts | `C_Item.GetItemCount` has bank inclusion parameters. | A signature does not establish closed-bank freshness or tradeability. Prefer a verified slot scan for the proposed exchangeable inventory; compare behavior during the feasibility test. |
| Professions and materials | Camelot's profession book uses `GetProfessions()` and `GetProfessionInfo()`. `C_TradeSkillUI.GetRecipeSchematic` exposes recipe data; item data APIs support asynchronous loading. | Verify learned professions and recipe access in the client. The reviewed sources do not establish an exhaustive accessible catalog of all Forever materials. Catalog completeness and material-to-profession mappings require matching-build data and an audit. |

Permanent sources for build 70205: [chat API](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_APIDocumentationGenerated/ChatInfoDocumentation.lua), [chat result enums](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_APIDocumentationGenerated/ChatConstantsDocumentation.lua), [containers](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_APIDocumentationGenerated/ContainerDocumentation.lua), [bank API](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_APIDocumentationGenerated/BankDocumentation.lua), [Camelot bank implementation](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_UIPanels_Game/Camelot/BankFrame.lua), [bag indices](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_APIDocumentationGenerated/BagIndexConstantsDocumentation.lua), [items](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua), [Camelot profession book](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_ProfessionsBook/Camelot/Blizzard_ProfessionsBook.lua), and [recipe API](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_APIDocumentationGenerated/TradeSkillUIDocumentation.lua).

**Affected addon:** proposed guild materials addon, working name GuildStock. **Reproduced in the game:** nothing in this review. **Pending:** two-client communications and realm restrictions; exact identity/addressing semantics with Forever surnames; roster membership checks; complete and partial bank reads; bound materials; profession/catalog coverage; combat; localized item loading; SavedVariables after reload and restart. The historic persistence problem remains open.

## Forever 1.60.1 · build 70009

| Area | Evidence or limitation | Impact and approach |
| --- | --- | --- |
| Unit name | `UnitName` declares `SecretWhenUnitNameIdentityRestricted`. | Revenge needs the name to compare it with its list. If it is inaccessible, skip identification; test behavior in combat and PvP. |
| Identity and class | `UnitNameUnmodified`, `UnitClassBase`, and `UnitGUID` declare `SecretWhenUnitIdentityRestricted`. `UnitClassBase` may return no results. | Do not treat a function's existence as permission to process its result. Review initialization paths as well. |
| Nameplates | `C_NamePlate.GetNamePlateForUnit` declares `SecretArguments = "AllowedWhenUntainted"`. | This is a condition on arguments, not general permission to modify any frame. The internal structures used by Revenge require a visual test for each build. |
| First name and surname | The Camelot implementation of `NameUtil` uses first name and surname to compose identity. | Do not assume the name/realm interpretation from other branches applies without checking. The generated documentation retains generic names for return values. |
| Saved data | TDL's historical note describes a loader failure. Revenge keeps a per-character copy in an account-wide variable and supports optional local recovery. | These are project mitigations, not evidence that Blizzard fixed the failure. Verify that adding and deleting entries persists after reload and restart. |
| UI dependencies | Revenge declares `Blizzard_NamePlates` and uses `plate.UnitFrame`, `healthBar`, and `CompactUnitFrame_UpdateHealthColor`. | These references have been identified in our code; contractual stability of FrameXML structures is not certified. |
| Floating button layering | Documented in source: `TargetFrameTemplate` uses `LOW` strata and frame level `500`; native character and spell windows inherit their strata. Revenge previously forced its floating button to `HIGH`. | Revenge now uses `LOW`, one frame level above `TargetFrame` when present, to preserve visibility at its initial anchor. Overlap with native windows and input handling remain pending in-game verification; inherited runtime strata are not established by the XML alone. |

Sources for the exact build: [UnitDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/bd2470aed543f72697a044e989285b6c83e63f73/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua), [NamePlateDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/bd2470aed543f72697a044e989285b6c83e63f73/Interface/AddOns/Blizzard_APIDocumentationGenerated/NamePlateDocumentation.lua), and [Camelot/NameUtil.lua](https://github.com/Gethe/wow-ui-source/blob/bd2470aed543f72697a044e989285b6c83e63f73/Interface/AddOns/Blizzard_FrameXMLUtil/Camelot/NameUtil.lua).

Frame layering evidence for the same build: [TargetFrame.xml](https://github.com/Gethe/wow-ui-source/blob/bd2470aed543f72697a044e989285b6c83e63f73/Interface/AddOns/Blizzard_UnitFrame/Mainline/TargetFrame.xml#L52), [Camelot/CharacterFrame.xml](https://github.com/Gethe/wow-ui-source/blob/bd2470aed543f72697a044e989285b6c83e63f73/Interface/AddOns/Blizzard_UIPanels_Game/Camelot/CharacterFrame.xml#L403), and [Camelot/Blizzard_PlayerSpellsFrame.xml](https://github.com/Gethe/wow-ui-source/blob/bd2470aed543f72697a044e989285b6c83e63f73/Interface/AddOns/Blizzard_PlayerSpells/Camelot/Blizzard_PlayerSpellsFrame.xml#L4).

Blizzard explains the purpose of secret values in its [article on combat and addons in Midnight](https://news.blizzard.com/en-us/article/24246290/combat-philosophy-and-addon-disarmament-in-midnight): certain data can be displayed through permitted operations without becoming available for addon decisions. That article provides context; Forever's specific restrictions are checked against its own build.

## Minimap controls review · September 27, 2026

The installed product remains `wow_classic_beta`, version `1.60.1.70009`; both addons still declare interface `16001`.

- **Documented in source:** the matching build exposes `RegisterForDrag` and `GetEffectiveScale` in [SimpleFrameAPIDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/bd2470aed543f72697a044e989285b6c83e63f73/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua). Scale results carry a secret-aspect annotation. [Camelot/Skin.lua](https://github.com/Gethe/wow-ui-source/blob/bd2470aed543f72697a044e989285b6c83e63f73/Interface/AddOns/Blizzard_Minimap/Camelot/Skin.lua) selects the native circular minimap mask for fixed and rotated modes.
- **Affected addons:** TDL and Revenge now provide minimap tooltips, left-click window toggling, left-button dragging around the native minimap, and no right-click action. Dragging skips inaccessible cursor/geometry values and only reanchors each addon’s own button. Settings live in the existing character DB; Revenge updates its revision and existing backup on changes.
- **Automated checks:** real addon handlers with frame stubs cover scaled cursor positioning, drag cleanup, position restoration, malformed saved angles, preserved existing entries, translations, and Revenge backup updates. These checks do not certify native persistence or combat behavior.
- **Reproduced in the game:** after `/reload`, TDL displayed the new tooltip, opened and closed with left-click, and the user confirmed physical mouse dragging moves its icon. Revenge was found loading a separate installed copy rather than the repository; that copy was preserved privately and the development symlink restored. After reloading, both icons were visibly repositioned along the lower-left minimap rim. No list entries were edited for these checks.
- **Pending verification:** position after another reload/restart, combat, UI scale changes, and replacement minimap shapes. Automated pointer dragging did not visibly move the icon, while the user confirmed TDL dragging; do not treat synthetic input as a reliable drag test for this client. The historical beta SavedVariables issue remains open.

### TDL interface review · September 27, 2026

Product `wow_classic_beta`, version `1.60.1`, build `70009`, addon interface `16001` remains the reference.

- **Documented in source:** `PLAYER_ENTERING_WORLD` supplies `isInitialLogin` and `isReloadingUi`. TDL checks these flags after its `PLAYER_LOGIN` initialization, opening when a task is unfinished without reopening on ordinary zone transitions. See [SystemDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/bd2470aed543f72697a044e989285b6c83e63f73/Interface/AddOns/Blizzard_APIDocumentationGenerated/SystemDocumentation.lua).
- **Documented in source:** font strings expose independent word and non-space wrapping controls plus line and string height measurements. TDL disables both wrapping modes and fixes the line height while collapsed, then measures wrapped text when expanded. These measurements can be secret when anchored to secret geometry; TDL uses its own frames and user-authored task text. See [SimpleFontStringAPIDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/bd2470aed543f72697a044e989285b6c83e63f73/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFontStringAPIDocumentation.lua).
- **Documented in source:** `UIPanelScrollFrameTemplate` provides a scroll bar and mouse-wheel handlers. TDL uses it for one continuous list and updates its scroll child after accordion layout changes. See [SecureScrollTemplates.xml](https://github.com/Gethe/wow-ui-source/blob/bd2470aed543f72697a044e989285b6c83e63f73/Interface/AddOns/Blizzard_SharedXML/SecureScrollTemplates.xml) and [SecureScrollTemplates.lua](https://github.com/Gethe/wow-ui-source/blob/bd2470aed543f72697a044e989285b6c83e63f73/Interface/AddOns/Blizzard_SharedXML/SecureScrollTemplates.lua).
- **Reproduced in the game:** the initial layout let long unbroken text wrap below the collapsed row. After controlling both wrapping modes and text height, a long task displays a single-line ellipsis and expands or collapses on click. Actions remain below the text in both states. Expanding an earlier task pushes the next task down. The shared background, full-width editor group, absence of page controls, hidden scroll bar for a short list, and automatic opening after `/reload` were observed.
- **Documented in source:** `EditBox` supports multiline input, focus, cursor position, and line counts. TDL opens an inline editor on a task's double click, grows the row while typing, and commits changed text on focus loss, closing, or `PLAYER_LOGOUT`. Blank or over-limit edits preserve the saved text; entering edit mode alone does not rewrite it. See [SimpleEditBoxAPIDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/bd2470aed543f72697a044e989285b6c83e63f73/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleEditBoxAPIDocumentation.lua) and the native [OnDoubleClick example](https://github.com/Gethe/wow-ui-source/blob/bd2470aed543f72697a044e989285b6c83e63f73/Interface/AddOns/Blizzard_Calendar/Mainline/Blizzard_CalendarTemplates.xml). The input at the bottom creates new tasks; Delete stays visible under each task.
- **Reproduced in the game, inline editing:** double-clicking a task focuses its multiline field with a visible caret. Enter adds a line and moves Delete down; removing that line restores the row height, and Escape exits editing. The original task text was restored during this check. Automatic opening with unfinished tasks was also observed when entering from character selection.
- **Pending verification:** scroll an overflowing list using both wheel and bar, collapse a row near the bottom, and check translated fonts. Combat, zone transitions, and persistence of edited text after reload and a full client restart still need in-game checks. Offline assertions cover more than eight tasks, layout offsets, caret visibility, scroll clamping, inline autosave on focus loss/close/logout, validation, deletion, and empty/completed/pending auto-open conditions; they do not validate client rendering or persistence. The historical SavedVariables limitation is not considered resolved.
- **Scrollbar visibility follow-up:** TDL now keeps the native scrollbar visible for short and empty lists. Removed its explicit range-based hiding and `scrollBarHideable` override. In the matching build's [SecureScrollTemplates.lua](https://github.com/Gethe/wow-ui-source/blob/bd2470aed543f72697a044e989285b6c83e63f73/Interface/AddOns/Blizzard_SharedXML/SecureScrollTemplates.lua#L56), the default zero-range behavior keeps the thumb and disabled arrow buttons visible. Offline checks cover short and empty list visibility. **Reproduced in the game:** after `/reload`, the scrollbar, thumb, and disabled arrows are visible beside a two-task list without overflow. Empty-list rendering and overflowing-list interaction remain pending in-game checks.

## Pending tests in 70009

- **TDL:** create, edit, complete, and delete tasks; check language; reload and restart without losing changes.
- **Revenge:** add manually and from the target; observe nameplates when entering and leaving range; check players whose identity is inaccessible, combat, and zone changes.
- **Revenge interface:** check translated labels, tooltips, and status messages for clipping. After `/reload`, overlap the floating button with the character window, bags, quest log, map, Revenge, and TDL; verify it stays behind windows and remains clickable and draggable when unobstructed, including beside the target frame.
- **Revenge persistence:** verify additions and deletions after `/reload` and restart, both with and without local recovery. Do not perform destructive tests on the personal list.
- **Errors and taint:** record the exact message, steps, build, and context when a failure occurs. Never include real names, player GUIDs, or personal SavedVariables content.

## Maintenance

The daily Codex review compares the installed version and the latest commit on the `forever` branch with this log. It also checks for relevant new evidence about open issues, even if the build has not changed. It distinguishes the installed build from the one published in the mirror.

For new findings, add an entry with product, version, build, interface if verified, date, permanent source, relevant change, and affected addons. Preserve history and earlier conclusions under their own build. Classify evidence as **documented in source**, **reproduced in the game**, **external report**, or **pending verification**.

The process can automatically document signature changes and declared restrictions. It cannot prove on its own that a function behaves correctly during a game session. It does not expand compatibility claims or modify `.toc` files merely because it detects a new build.

If other game branches become project targets, they will have their own entries. Do not copy conclusions from Retail, Classic Era, or one beta to another without evidence.
