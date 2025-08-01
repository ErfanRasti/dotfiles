#!/bin/bash

# Update rofi applets

## Define variables
dir="$HOME/.config/rofi"
style="$dir/tmp/rofi-apps-style.rasi"

## Source the generate_colors.sh
source "$dir/scripts/generate_colors.sh"

## Create tmp style
mkdir -p "$dir/tmp"
envsubst <$HOME/.config/rofi/applets/style.rasi >$style

# Update rofi cliphist

## Define variables
dir="$HOME/.config/rofi"
style="$dir/tmp/rofi-cliphist-style.rasi"

## Source the generate_colors.sh
source "$dir/scripts/generate_colors.sh"

## Create tmp style
mkdir -p "$dir/tmp"
envsubst <$dir/cliphist/style.rasi >$style

# Update rofi launcher

## Define variables
dir="$HOME/.config/rofi"
style="$dir/tmp/rofi-launcher-style.rasi"

## Source the generate_colors.sh
source "$dir/scripts/generate_colors.sh"

## Create tmp style
mkdir -p "$dir/tmp"
envsubst <$dir/launcher/style.rasi >$style

# Update rofi powermenu

## Define variables
dir="$HOME/.config/rofi"
style="$dir/tmp/rofi-powermenu-style.rasi"

## Source the generate_colors.sh
source "$dir/scripts/generate_colors.sh"

## Create tmp style
mkdir -p "$dir/tmp"
envsubst <$dir/powermenu/style.rasi >$style
