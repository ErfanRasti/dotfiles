#!/bin/sh
# Usage: gtk3_theme.sh MODE   (dark or light)
#
# GTK 3 reads ~/.config/gtk-3.0/gtk.css only at startup but re-reads its theme whenever
# gtk-theme changes. So the matugen colors live in two themes, adw-gtk3-matugen(-dark) =
# adw-gtk3 + ~/.config/gtk-3.0/colors.css, and switching to one recolors running GTK 3 apps
# and Chrome/Chromium (GTK mode) without a restart.
set -eu

for dir in $(echo "${XDG_DATA_DIRS:-/usr/local/share:/usr/share}" | tr ':' ' '); do
    [ -f "$dir/themes/adw-gtk3/gtk-3.0/gtk.css" ] && adw=$dir/themes && break
done
: "${adw:?adw-gtk3 not found in XDG_DATA_DIRS}"

for variant in "" -dark; do
    theme=${XDG_DATA_HOME:-$HOME/.local/share}/themes/adw-gtk3-matugen$variant
    mkdir -p "$theme/gtk-3.0" "$theme/gtk-4.0"
    printf '@import url("file://%s");\n@import url("file://%s");\n' \
        "$adw/adw-gtk3$variant/gtk-3.0/gtk.css" "${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/colors.css" \
        >"$theme/gtk-3.0/gtk.css"
    # GTK 4 apps without libadwaita use the theme too (colors from ~/.config/gtk-4.0/gtk.css)
    printf '@import url("file://%s");\n' "$adw/adw-gtk3$variant/gtk-4.0/gtk.css" >"$theme/gtk-4.0/gtk.css"
done

[ "$1" = dark ] && name=adw-gtk3-matugen-dark || name=adw-gtk3-matugen
gsettings set org.gnome.desktop.interface gtk-theme '' # forces a reload of the same name
gsettings set org.gnome.desktop.interface gtk-theme "$name"
