#!/bin/bash

LOG_DIR="$HOME/Library/Group Containers/UBF8T346G9.com.microsoft.teams/Library/Application Support/Logs"

FIFO=$(mktemp -u /tmp/teams_watcher_XXXXXX)
mkfifo "$FIFO"

TAIL_PID=""

current_log() {
  ls -t "$LOG_DIR"/MSTeams_*.log 2>/dev/null | head -1
}

cleanup() {
  [[ -n "$TAIL_PID" ]] && kill "$TAIL_PID" 2>/dev/null
  rm -f "$FIFO"
}
trap cleanup EXIT

start_tail() {
  [[ -n "$TAIL_PID" ]] && kill "$TAIL_PID" 2>/dev/null
  tail -F -n 0 "$1" 2>/dev/null | grep --line-buffered "UserNotificationAction" >"$FIFO" &
  TAIL_PID=$!
}

last_count=-1
last_log=""

# Open FIFO read+write so reads don't EOF when the tail writer is replaced
exec 3<>"$FIFO"

while true; do
  log=$(current_log)

  if [[ -z "$log" ]]; then
    sleep 5
    continue
  fi

  # Restart tail if the log rotated OR if the tail child died unexpectedly
  if [[ "$log" != "$last_log" ]] || { [[ -n "$TAIL_PID" ]] && ! kill -0 "$TAIL_PID" 2>/dev/null; }; then
    last_log="$log"

    initial=$(grep "UserNotificationAction" "$log" 2>/dev/null \
      | tail -1 | grep -oE 'unread notification count: [0-9]+' | grep -oE '[0-9]+$')
    initial="${initial:-0}"
    if [[ "$initial" != "$last_count" ]]; then
      last_count="$initial"
      sketchybar --trigger teams_unread_update TEAMS_UNREAD_COUNT="$initial"
    fi

    start_tail "$log"
  fi

  # Block up to 10s for a line; timeout lets us re-check for log rotation
  if IFS= read -r -t 10 line <&3; then
    count=$(echo "$line" | grep -oE 'unread notification count: [0-9]+' | grep -oE '[0-9]+$')
    if [[ -n "$count" && "$count" != "$last_count" ]]; then
      last_count="$count"
      sketchybar --trigger teams_unread_update TEAMS_UNREAD_COUNT="$count"
    fi
  fi
done
