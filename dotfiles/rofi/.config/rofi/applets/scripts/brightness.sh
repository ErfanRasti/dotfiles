#!/usr/bin/env bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
modi_script="$0 --modi"

# Import Current Theme
. "$script_dir/shared/theme.sh"

run_rofi_modi() {

  get_info() {
    # Brightness Info
    backlight="$(brightnessctl -m -d intel_backlight | cut -d',' -f4 | tr -d '%')"
    card="$(brightnessctl -m -d intel_backlight | cut -d',' -f2 | cut -d'/' -f3)"

    if [[ $backlight -ge 0 ]] && [[ $backlight -le 29 ]]; then
      level="Low"
    elif [[ $backlight -ge 30 ]] && [[ $backlight -le 49 ]]; then
      level="Optimal"
    elif [[ $backlight -ge 50 ]] && [[ $backlight -le 69 ]]; then
      level="High"
    elif [[ $backlight -ge 70 ]] && [[ $backlight -le 100 ]]; then
      level="Peak"
    fi

    # Theme Elements
    prompt="${backlight}%"
    mesg="Device: ${card}, Level: $level"

    # Options
    option_1="󱩎"
    option_2="󰛨"
    option_3="󱠂"
    option_4="󱧣"
  }

  run_cmd() {
    case "$1" in
    opt1) brightnessctl -d intel_backlight s 5%- >/dev/null ;;
    opt2) brightnessctl -d intel_backlight s 5%+ >/dev/null ;;
    opt3) brightnessctl -d intel_backlight s 25% >/dev/null ;;
    opt4)
      env XDG_CURRENT_DESKTOP=GNOME gnome-control-center display >/dev/null 2>&1 &
      disown
      ;;
    esac
  }

  print_menu() {
    get_info

    printf '\0prompt\x1f%s\n' "$prompt"
    printf '\0message\x1f%s\n' "$mesg"
    printf '\0markup-rows\x1ftrue\n'
    printf '\0keep-selection\x1ftrue\n'
    printf '\0keep-filter\x1ftrue\n'

    # rows
    printf '%s\0info\x1fopt1\n' "$option_1"
    printf '%s\0info\x1fopt2\n' "$option_2"
    printf '%s\0info\x1fopt3\n' "$option_3"
    printf '%s\0info\x1fopt4\n' "$option_4"
  }

  # https://man.archlinux.org/man/rofi-script.5.en
  case "$ROFI_RETV" in
  0) ;;
  1) run_cmd "$ROFI_INFO" ;;
  esac

  print_menu
}

rofi_cmd() {
  list_col='4'
  list_row='1'
  win_width='550px'

  rofi \
    -show brightness \
    -modi "brightness:${modi_script}" \
    -theme-str "window { width: $win_width; }" \
    -theme-str "listview { columns: $list_col; lines: $list_row; }" \
    -theme-str 'textbox-prompt-colon { str: ""; }' \
    -theme "${theme}"
}

if [[ -z "$1" ]]; then
  rofi_cmd
elif [[ "$1" == "--modi" ]]; then
  run_rofi_modi
else
  echo "Error: unknown argument '$1'" >&2
  exit 1
fi
