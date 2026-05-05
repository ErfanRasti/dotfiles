#!/usr/bin/env bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
modi_script="$0 --modi"

# Import Current Theme
. "$script_dir/../shared/theme.sh"

run_rofi_modi() {

  get_info() {
    # Find the current player
    ~/.config/rofi/applets/bin/current_player.sh

    current_player=$(cat "/tmp/last_player" 2>/dev/null)

    # Theme Elements
    status="$(playerctl -p "$current_player" status)"
    mesg=$("$HOME"/.config/hypr/scripts/song_detail.sh)

    # Options
    if [[ ${status} == "Playing" ]]; then
      option_1=""
    else
      option_1=""
    fi

    option_2=""
    option_3="󰙣"
    option_4="󰙡"
    option_5=""
    option_6="󰑗"

    repeat_status=$(playerctl -p "$current_player" loop)
    repeat_next_state="None"
    if [[ ${repeat_status} == "None" ]]; then
      option_6="󰒞"
      repeat_next_state="Track"
    elif [[ ${repeat_status} == "Track" ]]; then
      option_6="󰑘"
      repeat_next_state="Playlist"
    elif [[ ${repeat_status} == "Playlist" ]]; then
      option_6=""
      repeat_next_state="None"
    fi
  }

  run_cmd() {
    case "$1" in
    opt1) playerctl -p "$current_player" play-pause >/dev/null ;;
    opt2) playerctl -p "$current_player" stop >/dev/null ;;
    opt3) playerctl -p "$current_player" previous >/dev/null ;;
    opt4) playerctl -p "$current_player" next >/dev/null ;;
    opt5) playerctl -p "$current_player" shuffle "Toggle" >/dev/null ;;
    opt6) playerctl -p "$current_player" loop "$repeat_next_state" >/dev/null ;;
    esac
  }

  print_menu() {
    get_info

    printf '\0message\x1f%s\n' "$mesg"
    printf '\0markup-rows\x1ftrue\n'
    printf '\0keep-selection\x1ftrue\n'
    printf '\0keep-filter\x1ftrue\n'

    # rows
    if [[ ${status} == "Playing" ]]; then
      printf '%s\0info\x1fopt1\x1factive\x1ftrue\n' "$option_1"
    else
      printf '%s\0info\x1fopt1\n' "$option_1"
    fi

    printf '%s\0info\x1fopt2\n' "$option_2"
    printf '%s\0info\x1fopt3\n' "$option_3"
    printf '%s\0info\x1fopt4\n' "$option_4"

    random_status=$(playerctl -p "$current_player" shuffle)
    if [[ ${random_status} == "On" ]]; then
      printf '%s\0info\x1fopt5\x1factive\x1ftrue\n' "$option_5"
    else
      printf '%s\0info\x1fopt5\n' "$option_5"
    fi

    if [[ ${repeat_status} == "Track" || ${repeat_status} == "Playlist" ]]; then
      printf '%s\0info\x1fopt6\x1factive\x1ftrue\n' "$option_6"
    elif [[ ${repeat_status} == "None" ]]; then
      printf '%s\0info\x1fopt6\n' "$option_6"
    else
      printf '%s\0info\x1fopt6\x1furgent\x1ftrue\n' "$option_6"
    fi
  }

  # https://man.archlinux.org/man/rofi-script.5.en
  case "$ROFI_RETV" in
  0) ;;
  1)
    # This line is needed to generate the variables for `run_cmd`
    get_info

    run_cmd "$ROFI_INFO"
    ;;
  esac

  print_menu
}

# Rofi CMD
rofi_cmd() {
  list_col='6'
  list_row='1'
  win_width='700px'

  rofi \
    -show volume \
    -modi "volume:${modi_script}" \
    -theme-str "window { width: $win_width; }" \
    -theme-str "listview { columns: $list_col; lines: $list_row; }" \
    -theme-str 'textbox-prompt-colon {str: "";}' \
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
