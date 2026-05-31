#!/bin/bash
source "$HOME/.config/sketchybar/colors.sh"

USAGE=$(df -h / | awk 'NR==2 {print $5}')
sketchybar --set "$NAME" icon="" label="$USAGE"
