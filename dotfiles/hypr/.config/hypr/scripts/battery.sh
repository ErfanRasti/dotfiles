#!/usr/bin/env bash

# Battery Info
current_profile="$(powerprofilesctl get)"
status="$(acpi -b | cut -d',' -f1 | cut -d':' -f2 | tr -d ' ')"
percentage="$(acpi -b | cut -d',' -f2 | tr -d ' ',%)"
time="$(acpi -b | awk -F',' '{print $3}' | sed -E 's/^ +//; s/([0-9]+):([0-9]+):[0-9]+/\1h \2m/')"

if [[ -z "$time" ]]; then
  time='Threshold Charged'
fi

# Discharging
if [[ $percentage -ge 5 ]] && [[ $percentage -le 19 ]]; then
  ICON_STATUS="󰂃"
elif [[ $percentage -ge 20 ]] && [[ $percentage -le 39 ]]; then
  ICON_STATUS="󰁻"
elif [[ $percentage -ge 40 ]] && [[ $percentage -le 59 ]]; then
  ICON_STATUS="󰁽"
elif [[ $percentage -ge 60 ]] && [[ $percentage -le 79 ]]; then
  ICON_STATUS="󰁿"
elif [[ $percentage -ge 80 ]] && [[ $percentage -le 100 ]]; then
  ICON_STATUS="󰂁"
fi

# Charging Status
if [[ $status = *"Charging"* ]]; then
  ICON_STATUS="󰂄"
elif [[ $status = *"Full"* ]]; then
  ICON_STATUS="󰁹"
fi

# Current profile
ICON_PROFILE="??"
if [[ "$current_profile" == "power-saver" ]]; then
  ICON_PROFILE="󰌪"
elif [[ "$current_profile" == "balanced" ]]; then
  ICON_PROFILE=""
elif [[ "$current_profile" == "performance" ]]; then
  ICON_PROFILE="󰓅"
fi

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

# Handle flags: --status | --profile | --time (default = --all)
mode="${1:---all}"

case "$mode" in
--status)
  echo "${percentage}% ${ICON_STATUS}"
  ;;
--profile)
  echo "${ICON_PROFILE} ${current_profile}"
  ;;
--time)
  echo "${time}"
  ;;
--all)
  echo "${ICON_STATUS} ${percentage}% | ${ICON_PROFILE} ${current_profile} | ${time}"
  ;;
--help | -h)
  usage
  ;;
*)
  echo "Error: Unknown option '$mode'"
  usage
  exit 1
  ;;
esac
