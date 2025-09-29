#!/usr/bin/env bash
set -euo pipefail

emit() {
  local tips
  # Build tooltip lines like "procname [pid]" separated by \r
  if tips=$(
    fuser /dev/video* 2>/dev/null |
      tr ' ' '\n' | sed '/^$/d' | sort -u |
      xargs -r ps -o pid=,comm= -p |
      awk '{
          # unwrap foo.bar-wrapped variants → bar
          sub(/\.(.*)-wra?p?pe?d?$/, "\\1", $2);
          printf "%s [%s]", $2, $1
        }'
  ); then
    if [[ -n $tips ]]; then
      jq -cn --arg tt "$tips" '{text:"", tooltip:$tt}'
      return
    fi
  fi
  jq -cn '{text:"", tooltip:"No spying eyes!"}'
}

# initial output
emit

# Wayland/Waybar-style event loop:
# - refresh on any incoming line (ignored content)
# - otherwise refresh every 10s to catch changes
while :; do
  read -r -t 10 _ || true
  emit
done
