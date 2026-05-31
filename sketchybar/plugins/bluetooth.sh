#!/bin/bash
source "$HOME/.config/sketchybar/colors.sh"

POWER=$(blueutil --power)

if [ "$POWER" = "1" ]; then
  COUNT=$(blueutil --connected | grep -c "address")
  ICON="󰂯"; COLOR=$LAVENDER; LABEL="$COUNT"
else
  ICON="󰂲"; COLOR=$TEXT4; LABEL=""
fi

sketchybar --set "$NAME" icon="$ICON" label="$LABEL" icon.color=$COLOR
