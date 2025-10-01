#!/usr/bin/env bash
set -euo pipefail

# Optional: be nice to the scheduler + disk
command -v ionice >/dev/null && ionice -c3 -p $$
command -v renice >/dev/null && renice 10 $$ >/dev/null

emit() {
  # Collect unique PIDs using bash only (no ps/tr/sed/sort)
  local -A seen=()
  local -a pids=()
  # fuser prints PIDs space-separated; avoid forking extra tools
  if read -ra pids <<<"$(fuser /dev/video* 2>/dev/null || true)"; then
    local tips=() pid comm
    for pid in "${pids[@]}"; do
      [[ -r "/proc/$pid/comm" ]] || continue
      # uniq by PID without forking sort -u
      [[ ${seen[$pid]+x} ]] && continue
      seen[$pid]=1
      IFS= read -r comm <"/proc/$pid/comm" || continue
      # unwrap "foo.bar-wrapped" → "bar"
      if [[ $comm =~ \.(.*)-wra?p?pe?d?$ ]]; then
        comm="${BASH_REMATCH[1]}"
      fi
      tips+=("$comm [$pid]")
    done

    if ((${#tips[@]})); then
      # Join with \r like Waybar tooltip
      printf -v tt '%s' "$(
        IFS=$'\r'
        echo "${tips[*]}"
      )"
      jq -cn --arg tt "$tt" '{text:"", tooltip:$tt}'
      return
    fi
  fi
  jq -cn '{text:"", tooltip:"No spying eyes!"}'
}

# initial output
emit

# Prefer event-driven updates via inotify; fall back to slow polling if not available
if command -v inotifywait >/dev/null; then
  # Monitor open/close on device nodes and also device add/remove
  # The -m stream blocks (0% CPU) until something happens.
  inotifywait -qm \
    -e open -e close -e create -e delete -e move \
    /dev --format '%e %w%f' |
    while IFS= read -r line; do
      # only react if it concerns a /dev/video* node, or every 5 minutes for sanity refresh
      if [[ $line == *"/dev/video"* ]]; then
        emit
      fi
    done &

  watcher_pid=$!

  # Lightweight periodic refresh in case we miss an event (rare)
  while :; do
    sleep 300
    emit
  done

  # Cleanup if we ever exit
  trap 'kill "$watcher_pid" 2>/dev/null || true' EXIT
else
  # 2) Gentle polling fallback (no busy loop)
  while :; do
    read -r -t 60 _ || true # wake once per minute instead of every 10s
    emit
  done
fi
