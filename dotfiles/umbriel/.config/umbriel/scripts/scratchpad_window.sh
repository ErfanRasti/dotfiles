#!/usr/bin/env bash
# Mod+W: move a window into or out of the scratchpad.
#   focused window in a shown scratchpad -> take it out, close the scratchpad, and follow it
#                                           (switch to the workspace it lands on, focus it)
#   any other focused window             -> store it in the scratchpad
# (Mod+Ctrl+W is umbriel's plain restore: no follow, the scratchpad stays open.)

msg() { umbriel msg "$@" >/dev/null 2>&1; }

read -r id pad < <(umbriel windows --json | jq -r '
  (map(select(.focused or (.active and .scratchpad != "" and .visible))) | first)
  | "\(.id // "-") \(if (.scratchpad // "") == "" then "-" else .scratchpad end)"')

if [[ "$id" == "-" ]]; then
  exit 0
elif [[ "$pad" == "-" ]]; then
  msg window-move-to-scratchpad
  exit 0
fi

msg window-restore-from-scratchpad
# Close the scratchpad if other windows of it are still shown.
[[ "$(umbriel windows --json | jq '[ .[] | select(.scratchpad != "" and .visible) ] | length')" != "0" ]] &&
  msg scratchpad-toggle
# Follow the window to the workspace it was restored to.
idx="$(jq -rn --argjson w "$(umbriel windows --json)" --argjson s "$(umbriel workspaces --json)" --arg id "$id" '
  ($w | map(select(.id == $id)) | first | .workspace) as $ws
  | $s | map(select(.id == $ws)) | first | .index // empty')"
[[ -n "$idx" ]] && msg workspace-switch "$idx"
msg window-focus "$id"
