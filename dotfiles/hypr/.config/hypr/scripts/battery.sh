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
  ICON_DISCHRG="󰂃"
elif [[ $percentage -ge 20 ]] && [[ $percentage -le 39 ]]; then
  ICON_DISCHRG="󰁻"
elif [[ $percentage -ge 40 ]] && [[ $percentage -le 59 ]]; then
  ICON_DISCHRG="󰁽"
elif [[ $percentage -ge 60 ]] && [[ $percentage -le 79 ]]; then
  ICON_DISCHRG="󰁿"
elif [[ $percentage -ge 80 ]] && [[ $percentage -le 100 ]]; then
  ICON_DISCHRG="󰂁"
fi

# Charging Status
if [[ $status = *"Charging"* ]]; then
  ICON_CHRG="󰂄"
elif [[ $status = *"Full"* ]]; then
  ICON_CHRG="󰁹"
else
  ICON_CHRG=""
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

echo "${ICON_DISCHRG} ${percentage}% | ${ICON_PROFILE} ${current_profile} | ${ICON_CHRG} ${time}"
