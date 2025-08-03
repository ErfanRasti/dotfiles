#!/bin/bash

# Update rofi colors

## Define rofi dir
rofi_dir="$HOME/.config/rofi"

## Source the generate_colors.sh
source "$rofi_dir/scripts/generate_colors.sh"

# Create rofi colors
rofi_settings_dir="$rofi_dir/settings"

echo $rofi_settings_dir

colors="$rofi_settings_dir/colors.rasi"
mkdir -p "$rofi_settings_dir"
envsubst <"$rofi_settings_dir/colors-template.rasi" >$colors
