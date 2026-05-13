#!/usr/bin/env bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
modi_script="$0 --modi"

# Import Current Theme
. "$script_dir/shared/theme.sh"

run_rofi_modi() {

  get_info() {
    speaker_device=$(wpctl inspect @DEFAULT_AUDIO_SINK@ | awk -F'"' '/device.profile.description/ {print $2}')
    speaker_vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf "%d%%", $2*100}')
    mic_device=$(wpctl inspect @DEFAULT_AUDIO_SOURCE@ | awk -F'"' '/device.profile.description/ {print $2}')
    mic_vol=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | awk '{printf "%d%%", $2*100}')

    speaker_on=1
    stext='Unmute'
    sicon='󰜟'

    mic_on=1
    mtext='Unmute'
    micon=''

    if wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED; then
      speaker_on=0
      stext='Mute'
      sicon='󰓄'
    fi

    if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED; then
      mic_on=0
      mtext='Mute'
      micon=''
    fi

    prompt="S:$stext, M:$mtext"
    mesg="Speaker: $speaker_device $speaker_vol, Mic: $mic_device $mic_vol"

    option_1="󰝝"
    option_2="󰝞"
    option_3="$sicon"
    option_4="$micon"
    option_5="󰓃"
  }

  run_cmd() {
    case "$1" in
    opt1) wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05+ >/dev/null ;;
    opt2) wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05- >/dev/null ;;
    opt3) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle >/dev/null ;;
    opt4) wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle >/dev/null ;;
    opt5)
      pwvucontrol >/dev/null 2>&1 &
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

    if [[ "$speaker_on" -eq 1 ]]; then
      printf '%s\0info\x1fopt3\x1factive\x1ftrue\n' "$option_3"
    else
      printf '%s\0info\x1fopt3\x1furgent\x1ftrue\n' "$option_3"
    fi

    if [[ "$mic_on" -eq 1 ]]; then
      printf '%s\0info\x1fopt4\x1factive\x1ftrue\n' "$option_4"
    else
      printf '%s\0info\x1fopt4\x1furgent\x1ftrue\n' "$option_4"
    fi

    printf '%s\0info\x1fopt5\n' "$option_5"
  }

  # https://man.archlinux.org/man/rofi-script.5.en
  case "$ROFI_RETV" in
  0) ;;
  1) run_cmd "$ROFI_INFO" ;;
  esac

  print_menu
}

rofi_cmd() {
  list_col='5'
  list_row='1'
  win_width='670px'

  rofi \
    -show volume \
    -modi "volume:${modi_script}" \
    -theme-str "window { width: $win_width; }" \
    -theme-str "listview { columns: $list_col; lines: $list_row; }" \
    -theme-str 'textbox-prompt-colon { str: ""; }' \
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
