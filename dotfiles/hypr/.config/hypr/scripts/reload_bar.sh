#!/usr/bin/env bash
# (Re)start the bar for DESKTOP_SHELL in hyprland.lua and stop the other ones.
# Called by reload_config.sh (SUPER+SHIFT+R), which exports DESKTOP_SHELL.

CONFIG_FILE="${CONFIG_FILE:-$HOME/.config/hypr/hyprland.lua}"
CONFIG_AUTOSTART_FILE="${CONFIG_AUTOSTART_FILE:-$HOME/.config/hypr/config/autostart.lua}"
DESKTOP_SHELL="${DESKTOP_SHELL:-$(sed -n 's/^DESKTOP_SHELL = "\([a-z]*\)".*/\1/p' "$CONFIG_FILE")}"

stop_noctalia() {
  pkill -f '^noctalia( |$)' # shows up as ".noctalia-wrapped" on NixOS
  # Wait for it to exit: its single-instance lock makes a new one quit otherwise
  for _ in {1..30}; do pgrep -f '^noctalia( |$)' >/dev/null || break; sleep 0.1; done
}
stop_dms() { dms kill >/dev/null 2>&1; }
stop_bars() { pkill -x waybar; pkill -x ashell; }

case "$DESKTOP_SHELL" in
noctalia)
  stop_dms
  stop_bars
  stop_noctalia
  setsid -f noctalia >/dev/null 2>&1
  ;;
dms)
  stop_noctalia
  stop_bars
  stop_dms
  setsid -f dms run >/dev/null 2>&1
  ;;
*)
  stop_noctalia
  stop_dms
  stop_bars
  grep -q '^\s\+hl\.exec_cmd("waybar")' "$CONFIG_AUTOSTART_FILE" && setsid -f waybar >/dev/null 2>&1
  grep -q '^\s\+hl\.exec_cmd("ashell")' "$CONFIG_AUTOSTART_FILE" && setsid -f ashell >/dev/null 2>&1
  ;;
esac
