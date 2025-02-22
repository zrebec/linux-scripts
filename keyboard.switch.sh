#!/bin/bash

# Nastavenie prepínača klávesnice pomocou gsettings (bez potreby reštartu)

# 1. Vypnutie predvolenej skratky (Super+Space)
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "[]"

# 2. Nastavenie Alt+Shift pre prepínanie klávesnice
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['<Alt>Shift_L']"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "['<Shift>Alt_L']"

# Alternatívny spôsob, ak hore uvedený nefunguje
# gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['<Alt>Shift_R']"

# Pre overenie nastavenia
echo "Aktuálne nastavenie prepínania klávesnice:"
gsettings get org.gnome.desktop.wm.keybindings switch-input-source
