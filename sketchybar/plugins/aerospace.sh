#!/bin/bash
source "$HOME/.config/sketchybar/colors.sh"

FOCUSED=$(aerospace list-workspaces --focused)

if [ "$1" = "$FOCUSED" ]; then
  sketchybar --set "$NAME" label.color=$BG1 background.drawing=on
else
  WINS=$(aerospace list-windows --workspace "$1" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$WINS" -gt 0 ]; then
    sketchybar --set "$NAME" label.color=$TEXT1 background.drawing=off
  else
    sketchybar --set "$NAME" label.color=$TEXT3 background.drawing=off
  fi
fi
