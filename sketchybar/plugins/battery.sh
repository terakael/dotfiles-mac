#!/bin/bash
source "$HOME/.config/sketchybar/colors.sh"

INFO="$(pmset -g batt)"
PCT=$(echo "$INFO" | grep -o '[0-9]*%' | head -1 | tr -d '%')

if [ "$PCT" -le 10 ];    then ICON="󰁺"; COLOR=$RED
elif [ "$PCT" -le 25 ];    then ICON="󰁼"; COLOR=$YELLOW
elif [ "$PCT" -le 75 ];    then ICON="󰁾"; COLOR=$TEXT1
elif [ "$PCT" -le 95 ];    then ICON="󰂀"; COLOR=$TEXT1
else                             ICON="󰂂"; COLOR=$LAVENDER
fi

sketchybar --set "$NAME" icon="$ICON" label="${PCT}%" icon.color=$COLOR
