#!/usr/bin/env bash
# Battery info for hyprlock (and anything else that wants it).
#
# Run it for text output (see --help), or `source` it to reuse the helpers without
# starting a new process (~/.config/noctalia/scripts/lock_battery.sh does this). Everything is read
# from sysfs with bash builtins, so it forks nothing; only --profile/--all start
# powerprofilesctl, which is a Python program and takes ~0.2s.

# Sets BAT_PATH, BAT_PERCENT and BAT_STATUS (Charging, Discharging, Full,
# Not charging). Returns 1 when there is no battery.
battery_read() {
  local bats=(/sys/class/power_supply/BAT*)
  BAT_PATH="${bats[0]}"
  [[ -r "$BAT_PATH/capacity" ]] || return 1
  read -r BAT_PERCENT <"$BAT_PATH/capacity"
  read -r BAT_STATUS <"$BAT_PATH/status"
}

# Sets BAT_ICON from BAT_PERCENT and BAT_STATUS.
battery_icon() {
  case "$BAT_STATUS" in
  Charging) BAT_ICON="󰂄" ;;
  Full) BAT_ICON="󰁹" ;;
  *)
    if ((BAT_PERCENT < 20)); then
      BAT_ICON="󰂃"
    elif ((BAT_PERCENT < 40)); then
      BAT_ICON="󰁻"
    elif ((BAT_PERCENT < 60)); then
      BAT_ICON="󰁽"
    elif ((BAT_PERCENT < 80)); then
      BAT_ICON="󰁿"
    else
      BAT_ICON="󰂁"
    fi
    ;;
  esac
}

# Sets BAT_TIME, like "02h 15m remaining" or "00h 40m until charged".
battery_time() {
  local now=0 full=0 power=0 minutes
  [[ -r "$BAT_PATH/energy_now" ]] && read -r now <"$BAT_PATH/energy_now"
  [[ -r "$BAT_PATH/energy_full" ]] && read -r full <"$BAT_PATH/energy_full"
  [[ -r "$BAT_PATH/power_now" ]] && read -r power <"$BAT_PATH/power_now"
  if ((power <= 0)); then
    BAT_TIME="Threshold Charged"
  elif [[ "$BAT_STATUS" == "Charging" ]]; then
    minutes=$(((full - now) * 60 / power))
    printf -v BAT_TIME '%02dh %02dm until charged' $((minutes / 60)) $((minutes % 60))
  elif [[ "$BAT_STATUS" == "Discharging" ]]; then
    minutes=$((now * 60 / power))
    printf -v BAT_TIME '%02dh %02dm remaining' $((minutes / 60)) $((minutes % 60))
  else
    BAT_TIME="Threshold Charged"
  fi
}

# Sets PROFILE and PROFILE_ICON.
power_profile() {
  PROFILE="$(powerprofilesctl get 2>/dev/null)"
  case "$PROFILE" in
  power-saver) PROFILE_ICON="󰌪" ;;
  balanced) PROFILE_ICON="" ;;
  performance) PROFILE_ICON="󰓅" ;;
  *) PROFILE_ICON="??" ;;
  esac
}

usage() {
  echo "Usage: ${0##*/} [OPTION]

Options:
  --status        Show battery percentage and status icon
  --profile       Show current power profile icon
  --time          Show remaining battery time
  --all           Show full output (status + profile + time)
  --help, -h      Show this help message
  (no option)     Same as --all
"
}

main() {
  case "${1:---all}" in
  --help | -h)
    usage
    return
    ;;
  --status | --profile | --time | --all) ;;
  *)
    echo "Error: Unknown option '$1'"
    usage
    return 1
    ;;
  esac

  battery_read || {
    echo "No battery"
    return 1
  }

  case "${1:---all}" in
  --status)
    battery_icon
    echo "${BAT_PERCENT}% ${BAT_ICON}"
    ;;
  --profile)
    power_profile
    echo "${PROFILE_ICON} ${PROFILE}"
    ;;
  --time)
    battery_time
    echo "${BAT_TIME}"
    ;;
  --all)
    battery_icon
    battery_time
    power_profile
    echo "${BAT_ICON} ${BAT_PERCENT}% | ${PROFILE_ICON} ${PROFILE} | ${BAT_TIME}"
    ;;
  esac
}

# Only run when executed, not when sourced.
[[ "${BASH_SOURCE[0]}" == "$0" ]] && main "$@"
