#!/usr/bin/env bash

set +e # ignore the script if it raises an error

gsettings set org.gnome.desktop.interface gtk-theme ""

noctalia_running=false
pgrep -fx 'qs -c noctalia-shell' >/dev/null && noctalia_running=true

if { $noctalia_running &&
  jq -e '.colorSchemes.darkMode' ~/.config/noctalia/settings.json >/dev/null; } ||
  { ! $noctalia_running >/dev/null &&
    grep -q '^post_command.*dark' ~/.config/waypaper/config.ini; }; then
  gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
else
  gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
fi

gsettings set org.gnome.desktop.interface icon-theme "Adwaita"

~/.config/gtk-3.0/scripts/generate_bookmarks.sh ~/.config/gtk-3.0/bookmarks-template
