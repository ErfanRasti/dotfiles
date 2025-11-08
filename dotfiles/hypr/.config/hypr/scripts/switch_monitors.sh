#!/usr/bin/env bash
# Cycles monitor modes for Hyprland:
# Modes:
#  1) eDP-1 on,  HDMI-A-1 on     (extend)
#  2) eDP-1 off, HDMI-A-1 on
#  3) eDP-1 on,  HDMI-A-1 off
#  4) eDP-1 on,  HDMI-A-1 MIRROR of eDP-1
#
# If HDMI-A-1 is not present in `hyprctl monitors all`, just toggle DPMS for eDP-1.
#
# Safe defaults for enabling a monitor use preferred mode and auto placement.

set -euo pipefail

EDP="eDP-1"
HDMI="HDMI-A-1"

ALL_MONS_JSON="$(hyprctl monitors all -j || true)"

disable_monitor() {
  local name="$1"
  hyprctl keyword monitor "$name,disable" >/dev/null
}

enable_mirror_hdmi_to_edp() {
  # Source must be enabled, then make HDMI mirror the source
  hyprctl reload
  hyprctl keyword monitor "$HDMI,preferred,auto,1,mirror,$EDP" >/dev/null
}

is_mirrored() {
  echo "$ALL_MONS_JSON" | jq -e --arg HDMI "$HDMI" --arg EDP "$EDP" '
    . as $all
    | ($all[] | select(.name==$EDP) | .id | tostring) as $src
    | $all[] | select(.name==$HDMI and (.mirrorOf|tostring)==$src)
  ' >/dev/null
}

# Check for jq
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required (install jq and re-run)." >&2
  exit 1
fi

# Helper: is monitor currently connected (present in hyprctl monitors all)?
is_connected() {
  local name="$1"

  echo "$ALL_MONS_JSON" | jq -e --arg n "$name" '.[] | select(.name == $n)' >/dev/null 2>&1
}

# Helper: is monitor currently enabled (present in hyprctl monitors )?
is_enabled() {
  local name="$1"
  # Return true (0) if the monitor exists and is not disabled
  echo "$ALL_MONS_JSON" | jq -e --arg n "$name" \
    '.[] | select(.name == $n and .disabled == false)' >/dev/null 2>&1
}

dpms_toggle() {
  local name="$1"
  hyprctl dispatch dpms toggle "$name" >/dev/null
}

# If HDMI is not present atcall, just toggle eDP-1 DPMS and exit
is_connected "$HDMI" || {
  dpms_toggle "$EDP"
  exit 0
}

EDP_ENABLE=false
HDMI_ENABLE=false
is_enabled "$EDP" && EDP_ENABLE=true
is_enabled "$HDMI" && HDMI_ENABLE=true

# Determine current mode:
# Mode 1: both active
# Mode 2: only HDMI active
# Mode 3: only EDP active
# Mode 4: HDMI mirror of EDP
# (If neither is active, we’ll treat as undefined and go to Mode 1.)
MODE="undefined"
if is_mirrored; then
  MODE="3"
elif [ "$EDP_ENABLE" = true ] && [ "$HDMI_ENABLE" = true ]; then
  MODE="1"
elif [ "$EDP_ENABLE" = false ] && [ "$HDMI_ENABLE" = true ]; then
  MODE="2"
elif [ "$EDP_ENABLE" = true ] && [ "$HDMI_ENABLE" = false ]; then
  MODE="4"
fi

# Transition square:
# 1 -> 2, 2 -> 3, 3 -> 4, 4 -> 1
case "$MODE" in
"1")
  hyprctl reload
  disable_monitor "$EDP"
  echo "Switched to Mode 2: $EDP disabled, $HDMI enabled."
  notify-send -u critical -a "Hyprland" " 󰍺 External Display Only" "Internal display ($EDP) disabled, external display ($HDMI) enabled."
  ;;
"2")
  hyprctl reload
  enable_mirror_hdmi_to_edp
  echo "Switched to Mode 3 (Mirror): $HDMI mirrors $EDP."
  notify-send -u critical -a "Hyprland" " 󰍺 Mirrored Displays" "External display ($HDMI) is mirroring the internal display ($EDP)."
  ;;
"3")
  hyprctl reload
  disable_monitor "$HDMI"
  echo "Switched to Mode 4: $EDP enabled, $HDMI disabled."
  notify-send -u critical -a "Hyprland" " 󰍺 Laptop Display Only" "Internal display ($EDP) enabled, external display ($HDMI) disabled."
  ;;

"4")
  hyprctl reload
  echo "Switched to Mode 1: $EDP enabled, $HDMI enabled (extended)."
  notify-send -u critical -a "Hyprland" " 󰍺 Extended Displays" "Both displays active in extended layout."
  ;;
*)
  hyprctl reload
  echo "State undefined; set to Mode 1: $EDP enabled, $HDMI enabled."
  notify-send -u critical -a "Hyprland" " 󰍺 Display Configuration Reset" "Display state undefined; reverted to extended layout for both screens."
  ;;
esac

# Restart waybar if running
if pgrep -x waybar >/dev/null; then
  pkill waybar
fi
setsid -f waybar >/dev/null 2>&1

# Restart swayosd
if pgrep -x swayosd-server >/dev/null; then
  pkill swayosd-server
fi
setsid -f swayosd-server >/dev/null 2>&1
