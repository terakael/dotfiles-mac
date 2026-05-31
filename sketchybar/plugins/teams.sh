#!/bin/bash

source "$HOME/.config/sketchybar/colors.sh"

COUNT="${TEAMS_UNREAD_COUNT:-0}"

sketchybar --set teams icon="󰻞" icon.color=$LAVENDER label="$COUNT" label.color=$TEXT1
