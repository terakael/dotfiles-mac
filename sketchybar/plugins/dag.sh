#!/bin/bash
source "$HOME/.config/sketchybar/colors.sh"

DAG_BIN="$HOME/.local/bin/dag-status"
INTRA_PW=$(security find-generic-password -a "$USER" -s "intra-pw" -w 2>/dev/null)
POPUP_STATE="/tmp/sketchybar_dag_popup_items"

toggle_popup() {
  sketchybar --set "$NAME" popup.drawing="$1"
}

add_popup_item() {
  local name="$1"; shift
  sketchybar --add item "$name" popup."$NAME" --set "$name" "$@"
  echo "$name" >> "$POPUP_STATE"
}

render_env_section() {
  local label="$1" env_json="$2" slug="$3"
  local running_count issue_count

  running_count=$(echo "$env_json" | jq -r '.running_dag_count')
  issue_count=$(echo "$env_json"   | jq -r '.dags_with_issues | length')

  # Section header
  add_popup_item "dag.${slug}.run_header" \
    label="$label — Running ($running_count)" \
    label.font="Agave Nerd Font:Bold:12.0" \
    label.color=$TEXT2 \
    icon.drawing=off \
    background.drawing=off

  if [ "$running_count" -gt 0 ]; then
    local i=0
    while IFS= read -r dag_id; do
      [ -z "$dag_id" ] && continue
      add_popup_item "dag.${slug}.run.$i" \
        label="$dag_id" \
        label.color=$TEXT1 \
        icon="" \
        icon.font="Agave Nerd Font:Regular:10.0" \
        icon.color=$LAVENDER \
        background.drawing=off
      i=$(( i + 1 ))
    done < <(echo "$env_json" | jq -r '.running_dag_ids[]')
  else
    add_popup_item "dag.${slug}.run.none" \
      label="none" \
      label.color=$TEXT4 \
      icon.drawing=off \
      background.drawing=off
  fi

  if [ "$issue_count" -gt 0 ]; then
    add_popup_item "dag.${slug}.issue_header" \
      label="$label — Issues ($issue_count)" \
      label.font="Agave Nerd Font:Bold:12.0" \
      label.color=$RED \
      icon.drawing=off \
      background.drawing=off

    local j=0
    while IFS= read -r dag_id; do
      [ -z "$dag_id" ] && continue
      add_popup_item "dag.${slug}.issue.$j" \
        label="$dag_id" \
        label.color=$RED \
        icon="" \
        icon.font="Agave Nerd Font:Regular:10.0" \
        icon.color=$RED \
        background.drawing=off
      j=$(( j + 1 ))
    done < <(echo "$env_json" | jq -r '.dags_with_issues[]')
  fi
}

update() {
  OUTPUT=$("$DAG_BIN" "$INTRA_PW" 2>/dev/null) || {
    sketchybar --set "$NAME" icon="" icon.color=$TEXT4 label="?"
    return
  }

  RUNNING_COUNT=$(echo "$OUTPUT" | jq -r '.running_dag_count')
  ISSUE_COUNT=$(echo "$OUTPUT"   | jq -r '.issue_count')
  TOTAL_COUNT=$(( RUNNING_COUNT + ISSUE_COUNT ))

  if [ "$ISSUE_COUNT" -gt 0 ]; then
    ICON=$(printf '\xee\xaf\x9e')
    ICON_COLOR=$RED
  else
    ICON=$(printf '\xee\xac\xac')
    ICON_COLOR=$LAVENDER
  fi

  sketchybar --set "$NAME" \
    icon="$ICON"           \
    icon.color=$ICON_COLOR \
    label="$TOTAL_COUNT"

  # Rebuild popup
  if [ -f "$POPUP_STATE" ]; then
    while IFS= read -r item; do
      sketchybar --remove "$item" 2>/dev/null
    done < "$POPUP_STATE"
    rm "$POPUP_STATE"
  fi

  render_env_section "On-prem" "$(echo "$OUTPUT" | jq '.envs.onprem')"   "onprem"
  render_env_section "Composer" "$(echo "$OUTPUT" | jq '.envs.composer')" "composer"
}

case "$SENDER" in
  mouse.entered) toggle_popup on  ;;
  mouse.exited)  toggle_popup off ;;
  mouse.clicked) open "http://afpbidatalakejob201z.prod.jp.local:8080/home?status=running" ;;
  *)             update           ;;
esac
