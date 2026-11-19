#!/usr/bin/env bash
# SUPER+SHIFT+R: restart Hyprland's helper programs to match DESKTOP_SHELL in hyprland.lua
# ("noctalia", "dms" or "standalone"), so switching shells needs no re-login.

CONFIG_FILE="$HOME/.config/hypr/hyprland.lua"
CONFIG_AUTOSTART_FILE="$HOME/.config/hypr/config/autostart.lua"
DESKTOP_SHELL="$(sed -n 's/^DESKTOP_SHELL = "\([a-z]*\)".*/\1/p' "$CONFIG_FILE")"
export CONFIG_FILE CONFIG_AUTOSTART_FILE DESKTOP_SHELL

# Restart pyprland if running
pypr reload 2>/dev/null

# Bar / shell (noctalia, dms or waybar)
~/.config/hypr/scripts/reload_bar.sh &
disown

restart() { # restart <process name> [command...]
  local name="$1"
  shift
  pkill -x "$name"
  setsid -f "${@:-$name}" >/dev/null 2>&1
}

pkill -x swayidle
case "$DESKTOP_SHELL" in
noctalia | dms)
  # The shell provides notifications, OSD, wallpaper, night light and the lock screen
  pkill -x swaync
  pkill -x swayosd-server
  pkill -x hyprpaper
  pkill -x swww-daemon
  systemctl --user stop hypridle-runner.service hyprsunset.service vicinae.service
  setsid -f ~/.config/hypr/scripts/swayidle_runner.sh "$DESKTOP_SHELL" >/dev/null 2>&1
  ;;
*)
  systemctl --user restart hypridle-runner.service hyprsunset.service
  restart hyprpaper
  restart swaync
  restart swayosd-server
  # Optional extras, restarted only when autostart.lua runs them
  grep -q '^\s\+hl\.exec_cmd("swww-daemon")' "$CONFIG_AUTOSTART_FILE" && restart swww-daemon
  grep -q '^\s\+hl\.exec_cmd("hypr-dock")' "$CONFIG_AUTOSTART_FILE" && restart hypr-dock
  grep -q '^\s\+hl\.exec_cmd("systemctl --user start vicinae\.service")' "$CONFIG_AUTOSTART_FILE" &&
    systemctl --user restart vicinae.service
  ;;
esac

# Polkit agent: noctalia ships its own
if [[ "$DESKTOP_SHELL" == noctalia ]]; then
  systemctl --user stop hyprpolkitagent
else
  systemctl --user restart hyprpolkitagent
fi

# Restart xdg-desktop-portal-hyprland
systemctl --user restart xdg-desktop-portal-hyprland
