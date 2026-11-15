# Murly: WoW Agent overlay (macOS)

A floating gem button that stays above World of Warcraft: Forever and opens Murly, a small chat with Claude Code drawn with the same frame art as the TDL addon. It is not an addon and never touches the game client.

- Runs your local `claude` CLI with your logged-in subscription; `ANTHROPIC_API_KEY` is removed from its environment so it never bills an API key.
- Starts in this repository with the game folder (`/Applications/World of Warcraft/_forever_`) added, plus a short system prompt with the game paths and rules.
- Your global skills (for example `agent-desktop`) load as usual.

## Use

```sh
tools/wow-agent-overlay/build.sh --open
```

- Click the gem to open or close the chat. Drag it to move it. Right-click it to quit.
- Enter sends, Shift+Enter adds a line, Esc closes, ↺ starts a new conversation.
- Set WoW to windowed fullscreen; exclusive fullscreen can hide the overlay.
- To start it at login, add `Murly.app` under System Settings → General → Login Items.

## Permissions

There is no approval prompt. Edits and the tools in `allowedTools` (`main.swift`) run automatically, and the chat reports any other tool as not allowed. Add tools to that list and rebuild if you need more.

Do not use the agent to click or press keys inside WoW: automating gameplay breaks Blizzard's terms.
