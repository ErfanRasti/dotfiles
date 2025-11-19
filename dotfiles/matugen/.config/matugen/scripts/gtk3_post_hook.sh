#!/usr/bin/env bash

set +e # ignore the script if it raises an error

gsettings set org.gnome.desktop.interface gtk-theme ""

if grep -q '^post_command.*dark' ~/.config/waypaper/config.ini; then
  gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
else
  gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3
fi

gsettings set org.gnome.desktop.interface icon-theme "Adwaita"

~/.config/gtk-3.0/scripts/generate_bookmarks.sh ~/.config/gtk-3.0/bookmarks-template
