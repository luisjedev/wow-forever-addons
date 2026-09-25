---
name: curseforge-publish
description: Create or update this repository's WoW addon projects, descriptions, screenshots, and releases on CurseForge using Chrome and native computer control. Use when preparing or publishing TDL, Revenge, or another addon from this repository.
---

# Publish addons on CurseForge

Work from the repository and use `mcp__cua_repl` for Chrome and native file dialogs. Follow the current tool documentation; browser sessions, accessibility indices, and dialog coordinates are not persistent identifiers. This skill records the working workflow, not permission to publish unrelated changes or modify browser security settings.

## Repository and release conventions

- Read `AGENTS.md`, `README.md`, `docs/DEVELOPMENT.md`, and `docs/BLIZZARD_API.md`. Read the target addon's `.toc` and the code needed to substantiate the description and identify runtime assets.
- Use **Release** by default for this repository, per the owner's preference. A beta game client does not imply a Beta addon release. Use Beta or Alpha only when requested. Keep the ZIP filename, display name, and changelog heading consistent, such as `Revenge-1.4.9.zip` and `Revenge 1.4.9`.
- Confirm addon version, game product, game version, build, and interface separately. The September 25, 2026 reference was WoW Forever `1.60.1`, build `70009`, interface `16001`; recheck the compatibility log rather than treating these as permanent targets. Do not select Retail or Classic Era as a substitute when Forever is unavailable.
- Keep public copy in English. Describe actual features, commands, languages, installation, source/issue links, and known client limitations. Release status does not certify combat, nameplates, or persistence.
- Review `git status` and the relevant diff; run the checks in `docs/DEVELOPMENT.md`. Follow the repository's standing instruction to commit and push completed, validated changes to GitHub without asking again, unless the user requests otherwise. Do this before submitting the CurseForge file, and verify the pushed commit. Do not include unrelated pending work. A description-only edit does not require a new ZIP, version bump, or release.

## Known projects and assets

Verify the account and project title on arrival. Update existing projects instead of creating duplicates.

| Addon | Existing project | Public page |
| --- | --- | --- |
| TDL | [1704713](https://authors.curseforge.com/#/projects/1704713/general) | [TDL](https://www.curseforge.com/wow/addons/tdl) |
| Revenge | [1711522](https://authors.curseforge.com/#/projects/1711522/general) | [Revenge: Enemy List](https://www.curseforge.com/wow/addons/revenge-enemy-list) |

The author is **Artidev**. The plain name “Revenge” was already taken; its project title is “Revenge: Enemy List”, while the addon folder and `.toc` title remain `Revenge`.

Revenge's project icon is `docs/images/revenge-curseforge-icon.png`; its generation prompt is in the adjacent `.md` file. This marketing icon does not replace the in-game TGA asset. The existing UI screenshot is in the project's Media tab; retrieve its actual hosted URL from the image element when embedding it.

## Prepare the deliverables

1. **ZIP:** include one top-level addon folder with its `.toc`, loaded Lua/XML files, and referenced runtime assets. Preserve exact names and `Interface\\AddOns\\...` paths. Follow XML includes and texture references as well as `.toc` entries. Use an explicit reviewed file list with the standard `zipfile` module or an existing packager; inspect archive entries and run `ZipFile.testzip()` before uploading. Do not zip the repository wholesale.
2. Exclude `.local/`, WTF, SavedVariables, accounts, player lists, GUIDs, tokens, personal paths, `.git`, `.DS_Store`, tests, private recovery addons, and unused design variants. Optional private dependencies are not downloadable CurseForge relations. Built-in Blizzard addons are not separate CurseForge downloads either.
3. **Icon:** reuse the project's approved icon unless a replacement is requested or needed. For requested generation, use the available image generation skill/tool, save the selected result in the repository, and record its prompt. Keep it square, readable at small sizes, and free of unintended text. Inspect the upload crop: CurseForge may initially select only the upper-left corner. Expand it to include the full icon and visually verify before saving.
4. **UI screenshots:** use real addon UI captures, not generated mockups presented as actual behavior. Reuse uploaded images when suitable. Check readability, framing, and privacy; only use personal screenshots when the user has authorized that specific image for publication. Do not extract images or data from `.local/`.
5. **Description:** place a clear UI image near the start, immediately before or after the short introduction, so visitors can understand the addon without opening Gallery. Keep the same screenshot in Media with a descriptive title and caption. Do this for each addon being published; preserve existing useful images such as TDL's.

## Chrome and file uploads

1. Start with the relevant `cua` entry point: inventory if the tab is unknown, otherwise bind the existing CurseForge tab in **Chrome**. Name the browser session using the supported API. Reuse the current form and its account; avoid navigating away from unsaved work.
2. Use fresh AX/DOM state after actions. Wait for form data to populate before editing: the file editor briefly showed empty fields and Release before loading the actual saved Beta value. Prefer semantic locators for repeated actions; reacquire indices after navigation or rerendering.
3. Read the browser's `file-uploads` documentation. First try its supported file chooser flow. If Chrome returns `Not allowed`, read its upload troubleshooting documentation and use the native macOS picker when possible. Do not enable broader extension permissions without the applicable authorization.
4. For native fallback, activate the intended Chrome tab, click its upload button, and inspect the file dialog. Use **Command+Shift+G**, enter the exact absolute path, press Return, then verify the selected filename/preview before Open. This avoids accidentally selecting a different screenshot from a long Desktop list. Do not put personal absolute paths into public descriptions or this skill.
5. Inspect the uploaded image itself, not just a success message. For the square icon crop, the southeast handle supports arrow keys; Shift+Right enlarged it during the observed workflow. Read the current labels and verify the full crop visually instead of relying on saved coordinates or a fixed number of presses.

## Create or update the project

- **New project:** choose World of Warcraft / Addons, a distinct title, icon, one-line English summary, and the relevant category (Revenge uses PvP; TDL uses Miscellaneous). Fill Description and License, then create the project. Preserve an existing license and distribution preference; do not silently grant new licensing rights. Revenge was created with All Rights Reserved and third-party distribution disabled.
- If creation returns to the form without an explanation, inspect visible validation and relevant browser console errors. The original Revenge submission failed because its name was already in use. Resolve the specific error; do not repeatedly submit or create duplicate projects when success is uncertain.
- **Existing project:** edit only the requested fields. For release uploads use Files → Add File. For screenshot uploads use Media → Add media, then set the title/caption and Apply.
- **Inline UI image:** obtain the actual HTTPS image URL from the uploaded Media image's DOM `src`; do not invent attachment URLs or use `blob:`, local file paths, or the Gallery page URL. In Description's Markdown editor insert `![Descriptive UI alt text](ACTUAL_IMAGE_URL)` near the start. Read and preserve the rest of the current description. Gallery upload alone does not embed an image in the description.
- Save and check the rendered project page or the author's Project Page preview. Confirm the UI image loads at readable size and appears inside the description, not only in a gallery carousel. Avoid duplicate copies on repeat updates.

## Submit and verify a release

1. Choose the reviewed ZIP. Select the matching **WoW Forever** game version after the upload exposes that field. Set **Release** explicitly and check the display name and changelog. Describe changes and actual validation without implying unperformed game tests.
2. Preserve the requested publication behavior. For a request to publish, automatic publication after approval is appropriate; keep drafts/manual publication when requested. Submit once and inspect the file list before retrying an uncertain result.
3. Verify the resulting row's display name, **Release** type, game version, and status. `Uploading`, `Processing`, and `Under Review` are not public availability. Refresh once if needed; the portal's Refresh button may return to General, requiring a return to Files.
4. If only the release type/name is wrong, edit the existing file instead of uploading a duplicate. The original Revenge ZIP retained `-beta` in its filename after its type was corrected to Release; avoid that mismatch in future packages.
5. Verify the final description, inline screenshot, and icon. Mark the result tab as a deliverable. Report the project/file links, GitHub commit when pushed, and the exact pending moderation state. Stop after verified submission; do not promise approval or keep polling unchanged moderation status unless asked to monitor it.
