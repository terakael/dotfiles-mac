# sketchybar

## Purpose

macOS status bar replacing Waybar. Base config covers workspaces, clock, battery, volume, and Bluetooth. Work-specific widgets are injected by the work overlay at bar startup.

## Base Bar

- Left: AeroSpace workspace indicators — highlights the active workspace; clicking switches to it
- Centre: clock
- Right: battery, volume, Bluetooth

## Work Overlay

`sketchybarrc` sources `~/.config/sketchybar/sketchybarrc.work` if present. Work plugins are symlinked by `work/setup.sh` into `~/.config/sketchybar/plugins/`. The base bar is fully functional without the overlay.

---

## DAG Status Widget (`dag.sh`)

**What it shows:** Running DAG count across on-prem and Composer environments. Icon turns red on any failure. Hover popup lists running DAG IDs and failed DAG IDs, grouped by environment.

**Why it exists:** The team monitors Airflow DAG health every morning. The widget eliminates the context switch to a browser or a Viber channel for routine health checks. A team Viber channel already handles critical alerts; this widget is personal at-a-glance visibility layered on top.

**Implementation:**
- Calls the `dag-status` binary (`~/.local/bin/dag-status`) with an intranet password read from the macOS keychain (`security find-generic-password`)
- Polls every 60 seconds (`update_freq=60`)
- `mouse.clicked` opens the Airflow web UI filtered to running DAGs
- `mouse.entered` / `mouse.exited` toggle the popup
- Popup items are dynamically rebuilt on each update; previously added items are tracked in `/tmp/sketchybar_dag_popup_items` and removed before each redraw

---

## Teams Unread Widget (`teams.sh` + `teams_watcher.sh`)

**What it shows:** Unread Teams notification count.

**Why event-driven, not polling:** Teams log entries appear within ~300ms of a notification arriving in the UI. Polling at `update_freq=30` introduced up to 30s lag and read the whole log file on every tick.

**Implementation:**
- `teams_watcher.sh`: persistent background process; `tail -F` on the latest `MSTeams_*.log` in `~/Library/Group Containers/UBF8T346G9.com.microsoft.teams/...`; `grep --line-buffered "UserNotificationAction"`; fires `sketchybar --trigger teams_unread_update TEAMS_UNREAD_COUNT=<n>` on each change
- `teams.sh`: reads `$TEAMS_UNREAD_COUNT` from the triggered event env var, calls `sketchybar --set`
- Tail liveness check: if the tail child dies without log rotation, the watcher restarts it
- Log rotation handled: watcher detects when the newest log file changes and restarts `tail` on the new file, seeding the initial count from the new file before switching

**TCC constraint:** The watcher is launched from `sketchybarrc.work`, not a LaunchAgent. SketchyBar holds the `kTCCServiceSystemPolicyAppData` TCC permission that covers `~/Library/Group Containers`. A launchd-spawned bash process does not inherit this permission and cannot read the Teams log directory. Any future change that moves the watcher out of the SketchyBar process tree will break log access.

---

## Calendar Widget (`cal.sh`)

Shows upcoming calendar events. Hover popup expands event detail. Polls every 60 seconds.
