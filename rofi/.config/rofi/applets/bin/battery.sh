#!/usr/bin/env bash

# Import Current Theme
source "$HOME"/.config/rofi/applets/shared/theme.bash
theme="$type/$style"

# Battery Info
battery="$(acpi -b | cut -d',' -f1 | cut -d':' -f1)"
status="$(acpi -b | cut -d',' -f1 | cut -d':' -f2 | tr -d ' ')"
percentage="$(acpi -b | cut -d',' -f2 | tr -d ' ',\%)"
time="$(acpi -b | cut -d',' -f3)"

if [[ -z "$time" ]]; then
  time=' Fully Charged'
fi

# Theme Elements
prompt="$status"
mesg="${battery}: ${percentage}%,${time}"

list_col='6'
list_row='1'
win_width='600px'

# Charging Status
active=""
urgent=""
if [[ $status = *"Charging"* ]]; then
  active="-a 1"
  ICON_CHRG="󰂄"
elif [[ $status = *"Full"* ]]; then
  active="-u 1"
  ICON_CHRG="󰁹"
else
  urgent="-u 1"
  ICON_CHRG=""
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

power_profile="$(powerprofilesctl get)"
profile_icon=""
if [[ $power_profile = *"performance"* ]]; then
  profile_icon="󰓅"
elif [[ $power_profile = *"balanced"* ]]; then
  profile_icon=""
elif [[ $power_profile = *"power-saver"* ]]; then
  profile_icon="󰌪"
fi

# Options
option_1="$ICON_DISCHRG"
option_2="$ICON_CHRG"
option_3=""
option_4="󰂑"
option_5="󱈏"
option_6="$profile_icon"

# Rofi CMD
rofi_cmd() {
  rofi -theme-str "window {width: $win_width;}" \
    -theme-str "listview {columns: $list_col; lines: $list_row;}" \
    -theme-str "textbox-prompt-colon {str: \"$ICON_DISCHRG\";}" \
    -dmenu \
    -p "$prompt" \
    -mesg "$mesg" \
    ${active} ${urgent} \
    -markup-rows \
    -theme ${theme}
}

# Pass variables to rofi dmenu
run_rofi() {
  echo -e "$option_1\n$option_2\n$option_3\n$option_4\n$option_5\n$option_6" | rofi_cmd
}

# Execute Command
run_cmd() {
  if [[ "$1" == '--opt1' ]]; then
    notify-send -u low "󰂑 Remaining : ${percentage}%"
  elif [[ "$1" == '--opt2' ]]; then
    notify-send -u low "$ICON_CHRG Status : $status"
  elif [[ "$1" == '--opt3' ]]; then
    env XDG_CURRENT_DESKTOP=GNOME gnome-control-center power
  elif [[ "$1" == '--opt4' ]]; then
    kitty pkexec powertop
  elif [[ "$1" == '--opt5' ]]; then
    exec ~/.config/rofi/applets/bin/battery_charge_threshold.sh
  elif [[ "$1" == '--opt6' ]]; then
    exec ~/.config/rofi/applets/bin/power_profile.sh
  fi
}

# Actions
chosen="$(run_rofi)"
case ${chosen} in
$option_1)
  run_cmd --opt1
  ;;
$option_2)
  run_cmd --opt2
  ;;
$option_3)
  run_cmd --opt3
  ;;
$option_4)
  run_cmd --opt4
  ;;
$option_5)
  run_cmd --opt5
  ;;
$option_6)
  run_cmd --opt6
  ;;
esac
