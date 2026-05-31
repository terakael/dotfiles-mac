#!/bin/bash
source "$HOME/.config/sketchybar/colors.sh"

VOL=$(osascript -e 'output volume of (get volume settings)')
MUTED=$(osascript -e 'output muted of (get volume settings)')

if [ "$MUTED" = "true" ] || [ "$VOL" -eq 0 ]; then
  ICON="󰸈"; COLOR=$TEXT4
elif [ "$VOL" -lt 33 ]; then ICON="󰕿"; COLOR=$LAVENDER
elif [ "$VOL" -lt 66 ]; then ICON="󰖀"; COLOR=$LAVENDER
else                          ICON="󰕾"; COLOR=$LAVENDER
fi

sketchybar --set "$NAME" icon="$ICON" label="${VOL}%" icon.color=$COLOR
