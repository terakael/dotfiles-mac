# dotfiles-mac

## Purpose

Personal macOS configuration replicating a terminal-first, keyboard-driven Arch Linux (Omarchy) workflow. Deep work happens entirely in the terminal; GUI apps are organised and reachable but don't compete for focus.

## Tool Choices

| Tool | Replaces | Why chosen |
|---|---|---|
| AeroSpace | Hyprland (Linux) | File-based config; near-instant workspace switching — komorebi on Windows had 1-2s delay |
| Ghostty | Alacritty | File-based config; creator trust (Mitchell Hashimoto) used as tiebreaker against WezTerm |
| tmux | zellij | More minimal; stronger shell integration for programmatic pane control |
| SketchyBar | Waybar (Linux) | macOS equivalent; supports custom plugins and event-driven updates |
| Karabiner | — | Driver-level key translation — intercepts before any app sees input |

WezTerm remains a functional equivalent to Ghostty; there is no strong reason to switch away from either. zellij floating panes were the headline reason to consider it — in practice, tabs and splits were always used instead.

## Workspace Layout

| Workspaces | Apps | Rationale |
|---|---|---|
| 1 | Terminal (Ghostty) | Core deep work |
| 2 | Browser (Brave) | Core deep work |
| 3–5 | Spare | Ad-hoc (PowerPoint, Excel, etc.) |
| 6–0 | Comms (Teams, Outlook, Zoom, Viber) | Both-hands access — deliberate ergonomic friction |

Workspaces 1–5 are reachable with the left hand only (option+1–5). Workspaces 6–0 require both hands. Communication apps are primarily reactive; the friction is intentional.

## Keybinding Split

Karabiner handles key *translation* — what a key is. AeroSpace handles key *actions* — what happens when a key is pressed. These responsibilities do not mix.

- Karabiner: CapsLock → Escape (tap) / Ctrl (hold), Linux-style copy/paste, any future key remapping
- AeroSpace: app launches, workspace switches, script execution (e.g. Bluetooth toggle)

whkd is not used — AeroSpace exec-and-forget covers all action keybinds. A third keybinding location would create an unmaintainable split across Karabiner, AeroSpace, and whkd.

## Keybindings

- `alt+enter` — open Ghostty
- `alt+shift+b` — open Brave
- `alt+b` — toggle headphones Bluetooth (`~/.local/bin/toggle_headphones`)
- `CapsLock` tap — Escape
- `CapsLock` hold — Ctrl
