# dotfiles-mac

Personal macOS config — terminal-first, keyboard-driven. Portable across machines.

## What's included

| Tool | What |
|---|---|
| [AeroSpace](https://github.com/nickcoutsos/aerospace) | Tiling window manager |
| [Ghostty](https://ghostty.org) | Terminal emulator |
| [Karabiner-Elements](https://karabiner-elements.pqrs.org) | Key remapping (CapsLock → Esc/Ctrl, etc.) |
| [SketchyBar](https://felixkratz.github.io/SketchyBar) | Scriptable status bar |
| [Starship](https://starship.rs) | Shell prompt |
| [neovim](https://neovim.io) | Text editor |
| [zellij](https://zellij.dev) | Terminal multiplexer |
| [lazygit](https://github.com/jesseduffield/lazygit) | Git TUI |
| [k9s](https://k9scli.io) | Kubernetes TUI |
| [btop](https://github.com/aristocratos/btop) | System monitor |
| [tmux](https://github.com/tmux/tmux) | Terminal multiplexer (classic) |

## Setup

```bash
git clone https://git.rakuten-it.com/scm/~daniel.knezevic/dotfiles-mac.git
cd dotfiles-mac
./setup.sh
```

`setup.sh` creates symlinks from `~/.config/<tool>` into this repo. It's safe to re-run — existing files and symlinks are left in place.

The tools themselves are not installed by the script. Install them first via [Homebrew](https://brew.sh):

```bash
brew install aerospace ghostty karabiner-elements sketchybar starship neovim zellij lazygit k9s btop tmux
```

## Notes

- **SketchyBar** — the base config covers workspaces, clock, battery, disk, volume, and Bluetooth. A separate work overlay adds Airflow DAG status, Teams unread count, and a calendar widget (see the work dotfiles).
- **Karabiner** — remaps CapsLock to Escape (tap) / Left Control (hold). Edit `karabiner/karabiner.json` to adjust.
- **AeroSpace** — workspace layout is configured in `aerospace/aerospace.toml`. Review and adjust keybindings to your preference before starting it.
