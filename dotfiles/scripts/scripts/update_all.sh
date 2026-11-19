#!/bin/zsh

echo "------------------------------- Update system -------------------------------"
paru
echo "------------------------------- Update flatpak -------------------------------"
flatpak update
echo "------------------------------- Update LazyVim -------------------------------"
nvim --headless "+Lazy! sync" +qa
nvim --headless "+Lazy! update" +qa
nvim --headless "+Lazy! clean" +qa

