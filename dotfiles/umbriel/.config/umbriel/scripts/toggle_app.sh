#!/usr/bin/env bash
# App toggle (umbriel port of niri/scripts/toggle_app.sh), using umbriel's default scratchpad.
#
# Usage: toggle_app.sh <app-id> <command...>
#   not running            -> start <command> (it opens as a normal floating window, see rules.toml)
#   focused on a workspace -> put it into the scratchpad (Mod+Shift+W shows the scratchpad)
#   in the scratchpad      -> (shown or hidden) move it out to the current workspace and focus it
#   on another workspace   -> bring it to the current workspace and focus it
#   on this workspace      -> focus it
#
# umbriel's move actions act on the FOCUSED window, so every move first makes sure the target
# really has focus and otherwise does nothing (never moves some other window by mistake).

app_id="$1"
shift

msg() { umbriel msg "$@" >/dev/null 2>&1; }
focused_id() { umbriel focused-window --json 2>/dev/null | jq -r '.id // empty' 2>/dev/null; }
focus() { # <id>: focus it and wait (max ~0.5 s) until umbriel reports it focused
  msg window-focus "$1"
  for _ in {1..15}; do
    [[ "$(focused_id)" == "$1" ]] && return 0
    sleep 0.03
  done
  return 1
}
pad_shown() { umbriel windows --json | jq '[ .[] | select(.scratchpad != "" and .visible) ] | length'; }

# Target window (first top-level match, dialogs excluded) + the focused workspace index.
read -r id pad cur < <(
  jq -rn --argjson w "$(umbriel windows --json)" --argjson s "$(umbriel workspaces --json)" --arg app "$app_id" '
    ($s | map(select(.focused)) | first | .index) as $cur
    | ($w | map(select(.app_id == $app and .parent == "")) | first) as $t
    | if $t == null then "- - \($cur)"
      else "\($t.id) \(if $t.scratchpad == "" then "-" else $t.scratchpad end) \($cur)" end')

if [[ "$id" == "-" ]]; then
  exec umbriel msg spawn "$@"
fi

if [[ "$(focused_id)" == "$id" && "$pad" == "-" ]]; then
  msg window-move-to-scratchpad
elif [[ "$pad" != "-" ]]; then
  # Restoring needs the scratchpad shown; remember whether it was, so it can be hidden again
  # instead of leaving the other scratchpad windows open over the workspace.
  shown="$(pad_shown)"
  focus "$id" || exit 0                 # reveals it in the scratchpad
  msg window-restore-from-scratchpad    # back to its workspace...
  focus "$id" && msg window-move-to-workspace "$cur"   # ...then to the current one
  [[ "$shown" == "0" && "$(pad_shown)" != "0" ]] && msg scratchpad-toggle
  focus "$id"
else
  focus "$id" || exit 0
  msg window-move-to-workspace "$cur"
  msg workspace-switch "$cur"
  focus "$id"
fi
