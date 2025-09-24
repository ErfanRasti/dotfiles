#!/bin/zsh

echo "------------------------------- Update system"
paru
echo "------------------------------- Update flatpak"
flatpak update
echo "------------------------------- Update hyprland plugins"
hyprpm update

