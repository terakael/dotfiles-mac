#!/bin/bash
source "$HOME/.config/sketchybar/colors.sh"

CAL_BIN="$HOME/.local/bin/calrs"
POPUP_STATE="/tmp/sketchybar_cal_popup_items"

toggle_popup() {
  sketchybar --set "$NAME" popup.drawing="$1"
}

format_remaining() {
  local mins=$1
  if [ "$mins" -le 0 ]; then
    echo "now"
  elif [ "$mins" -lt 60 ]; then
    echo "${mins}m"
  elif [ "$mins" -lt 120 ]; then
    echo "1h $(( mins - 60 ))m"
  else
    echo "$(( mins / 60 ))h"
  fi
}

rebuild_popup() {
  local events_json="$1"

  if [ -f "$POPUP_STATE" ]; then
    while IFS= read -r item; do
      sketchybar --remove "$item" 2>/dev/null
    done < "$POPUP_STATE"
    rm "$POPUP_STATE"
  fi

  local i=0
  while IFS= read -r event; do
    local subject start_str start_epoch start_local
    subject=$(echo "$event" | jq -r '.subject')
    start_str=$(echo "$event" | jq -r '.start.dateTime' | cut -d'.' -f1)
    start_epoch=$(date -j -u -f "%Y-%m-%dT%H:%M:%S" "$start_str" +%s 2>/dev/null)
    start_local=$(date -r "$start_epoch" +%H:%M 2>/dev/null)

    local name="cal.meeting.$i"
    sketchybar --add item "$name" popup."$NAME" \
      --set "$name" \
        label="${start_local}  ${subject}" \
        label.color=$TEXT1 \
        icon="󰃰" \
        icon.font="Agave Nerd Font:Regular:10.0" \
        icon.color=$LAVENDER \
        background.drawing=off
    echo "$name" >> "$POPUP_STATE"
    i=$(( i + 1 ))
  done < <(echo "$events_json" | jq -c '.[]')
}

update() {
  local cal_json now future_json future_count

  cal_json=$("$CAL_BIN" list 2>/dev/null) || cal_json="[]"
  now=$(date -u +%s)
  local now_iso
  now_iso=$(date -u -r "$now" +%Y-%m-%dT%H:%M:%S)

  # Filter cancelled events, keep those not yet ended, sort by start
  future_json=$(echo "$cal_json" | jq -c --arg now "$now_iso" '
    [.[]
      | select(.subject | startswith("Canceled:") | not)
      | select(.end.dateTime > $now)
    ] | sort_by(.start.dateTime)
  ')

  future_count=$(echo "$future_json" | jq 'length')

  rebuild_popup "$future_json"

  if [ "$future_count" -eq 0 ]; then
    sketchybar --set "$NAME" \
      icon="󰃭" \
      icon.color=$TEXT4 \
      label="no meetings today" \
      label.color=$TEXT3 \
      click_script=""
    return
  fi

  # Find the first meeting that started within the last 5 minutes or hasn't started yet
  local now_minus5
  now_minus5=$(( now - 300 ))
  local now_minus5_iso
  now_minus5_iso=$(date -u -r "$now_minus5" +%Y-%m-%dT%H:%M:%S)

  local next
  next=$(echo "$future_json" | jq -c --arg cutoff "$now_minus5_iso" \
    '[.[] | select(.start.dateTime >= $cutoff)] | .[0]')

  if [ "$next" = "null" ] || [ -z "$next" ]; then
    sketchybar --set "$NAME" \
      icon="󰃭" \
      icon.color=$TEXT4 \
      label="no meetings today" \
      label.color=$TEXT3 \
      click_script=""
    return
  fi

  local subject start_str start_epoch mins_remaining time_str web_link click_script
  subject=$(echo "$next" | jq -r '.subject')
  start_str=$(echo "$next" | jq -r '.start.dateTime' | cut -d'.' -f1)
  start_epoch=$(date -j -u -f "%Y-%m-%dT%H:%M:%S" "$start_str" +%s 2>/dev/null)
  mins_remaining=$(( (start_epoch - now) / 60 ))

  time_str=$(format_remaining "$mins_remaining")

  web_link=$(echo "$next" | jq -r '.join_url // ""')
  if [ -n "$web_link" ]; then
    click_script="open '${web_link}'"
  else
    click_script=""
  fi

  local display_name
  if [ "${#subject}" -gt 30 ]; then
    display_name="${subject:0:30}..."
  else
    display_name="$subject"
  fi

  sketchybar --set "$NAME" \
    icon="󰃭" \
    icon.color=$LAVENDER \
    label="${display_name} (${time_str})" \
    label.color=$TEXT1 \
    click_script="$click_script"
}

case "$SENDER" in
  mouse.entered) toggle_popup on  ;;
  mouse.exited)  toggle_popup off ;;
  *)             update           ;;
esac
