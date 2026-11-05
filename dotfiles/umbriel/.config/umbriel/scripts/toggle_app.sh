#!/usr/bin/env bash
# App toggle (umbriel port of niri/scripts/toggle_app.sh), using umbriel's default scratchpad.
#
# Usage: toggle_app.sh <app-id> <command...>
#   not running            -> start <command> (it opens as a normal floating window, see rules.toml)
#   focused on a workspace -> put it into the scratchpad (Mod+Shift+W shows the scratchpad)
#   in the scratchpad      -> (shown or hidden) move it out to the current workspace and focus it
#   on another workspace   -> bring it to the current workspace and focus it
#   on this workspace      -> focus it

app_id="$1"
shift

# One query: target window (first match) + the focused workspace index.
read -r id pad focused ws cur < <(
  jq -rn --argjson w "$(umbriel windows --json)" --argjson s "$(umbriel workspaces --json)" --arg app "$app_id" '
    ($s | map(select(.focused)) | first) as $cur
    | ($w | map(select(.app_id == $app)) | first) as $t
    | if $t == null then "- - - - \($cur.index)"
      else "\($t.id) \(if $t.scratchpad == "" then "-" else $t.scratchpad end) \($t.focused or ($t.active and $t.scratchpad != "" and $t.visible)) \(if $t.workspace == "" then "-" else $t.workspace end) \($cur.index)"
      end')

msg() { umbriel msg "$@" >/dev/null 2>&1; }

if [[ "$id" == "-" ]]; then
  exec umbriel msg spawn "$@"
elif [[ "$focused" == "true" && "$pad" == "-" ]]; then
  msg window-move-to-scratchpad
elif [[ "$pad" != "-" ]]; then
  # Restoring needs the scratchpad shown; remember whether it was, so it can be hidden again
  # instead of leaving the other scratchpad windows open over the workspace.
  shown="$(umbriel windows --json | jq '[ .[] | select(.scratchpad != "" and .visible) ] | length')"
  msg window-focus "$id"                # reveals it in the scratchpad
  msg window-restore-from-scratchpad    # back to its workspace...
  msg window-move-to-workspace "$cur"   # ...then to the current one
  if [[ "$shown" == "0" ]] &&
     [[ "$(umbriel windows --json | jq '[ .[] | select(.scratchpad != "" and .visible) ] | length')" != "0" ]]; then
    msg scratchpad-toggle               # hide the rest of the scratchpad again
  fi
  msg window-focus "$id"
elif [[ "$focused" != "true" ]]; then
  msg window-focus "$id"
  msg window-move-to-workspace "$cur"
  msg workspace-switch "$cur"
  msg window-focus "$id"
fi
