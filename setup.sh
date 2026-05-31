#!/bin/bash
# Set up symlinks for all generic configs.
# Safe to re-run — existing symlinks/files are left in place.

set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$HOME/.config"

mkdir -p "$CONFIG"

link() {
  local src="$1" dst="$2"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    echo "  skip  $dst"
  else
    ln -s "$src" "$dst"
    echo "  link  $dst -> $src"
  fi
}

for item in aerospace btop ghostty k9s karabiner lazygit nvim sketchybar tmux zellij; do
  echo "==> $item"
  link "$DOTFILES/$item" "$CONFIG/$item"
done

echo "==> starship"
link "$DOTFILES/starship.toml" "$CONFIG/starship.toml"

echo "==> bin"
mkdir -p "$HOME/.local/bin"
for f in "$DOTFILES/bin/"*; do
  link "$f" "$HOME/.local/bin/$(basename "$f")"
done

echo ""
echo "Done."
