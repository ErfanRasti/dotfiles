#!/usr/bin/env bash

style="$HOME/.config/rofi/launcher/style.rasi"
alt_style="$HOME/.config/rofi/launcher/style-alt.rasi"

show_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -a, --alt     Use the alternate style (style-alt.rasi)
  -h, --help    Show this help message and exit
EOF
}

# Parse arguments
case "$1" in
-a | --alt)
  style="$alt_style"
  ;;
-h | --help)
  show_help
  exit 0
  ;;
"")
  # No arguments — use default style
  ;;
*)
  echo "Error: Unknown option '$1'"
  show_help
  exit 1
  ;;
esac

## Run
rofi \
  -show drun \
  -theme "$style"
