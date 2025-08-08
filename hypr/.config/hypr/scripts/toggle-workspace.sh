#!/usr/bin/env sh

# Set range variable in order to match the workspace (not working by id only)
rid="w[tv1]s[false]"

# Current gaps for active workspace
gaps_in_current=$(hyprctl workspacerules -j | jq --arg rid "$rid" '[.[] | select(.workspaceString | startswith($rid)) | .gapsIn[0]] | .[0]')
gaps_out_current=$(hyprctl workspacerules -j | jq --arg rid "$rid" '[.[] | select(.workspaceString | startswith($rid)) | .gapsOut[0]] | .[0]')

# Toggle gaps for the active workspace
if [ "$gaps_in_current" = "null" ] && [ "$gaps_out_current" = "null" ]; then
  hyprctl --batch "\
    keyword workspace w[tv1]s[false], gapsout:0, gapsin:0;\
    keyword workspace f[1]s[false], gapsout:0, gapsin:0;\
    keyword windowrule bordersize 0, floating:0, onworkspace:w[tv1]s[false];\
    keyword windowrule rounding 0, floating:0, onworkspace:w[tv1]s[false];\
    keyword windowrule bordersize 0, floating:0, onworkspace:f[1]s[false];\
    keyword windowrule rounding 0, floating:0, onworkspace:f[1]s[false]"
  exit
fi
hyprctl reload
