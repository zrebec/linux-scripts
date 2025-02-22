#!/bin/bash

# === MINIMÁLNE NASTAVENIA PRE PRÍJEMNEJŠÍ GNOME ===

# 1. Zobrazenie sekúnd v hodinách na hornom paneli
gsettings set org.gnome.desktop.interface clock-show-seconds true

# 2. Zobrazenie dátumu v hodinách na hornom paneli
gsettings set org.gnome.desktop.interface clock-show-date true

# 3. Zobrazenie dňa v týždni v hodinách na hornom paneli
gsettings set org.gnome.desktop.interface clock-show-weekday true

# 4. Zapnutie miniatúr na pracovnej ploche (desktop icons)
gsettings set org.gnome.shell.extensions.ding show-home true

# 5. Nastavenie click-to-minimize (minimalizácia okna po kliknutí na jeho ikonu v docku)
gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize'

# 6. Zníženie oneskorenia pre tooltip (keď podržíš myš nad prvkom)
gsettings set org.gnome.desktop.interface tooltip-timeout 500 # v milisekundách (pôvodná hodnota je 1000)

# 7. Úprava rýchlosti dvojitého kliknutia
gsettings set org.gnome.desktop.peripherals.mouse double-click-timeout 400 # v milisekundách

# 8. Zvýšenie rýchlosti kurzora
gsettings set org.gnome.desktop.peripherals.mouse speed 0.5 # hodnoty od -1 do 1

# === VÝKONNOSTNÉ VYLEPŠENIA ===

# 9. Vypnutie animácií (pre staršie počítače)
gsettings set org.gnome.desktop.interface enable-animations false

# 10. Zníženie počtu pracovných plôch (šetrí pamäť)
gsettings set org.gnome.desktop.wm.preferences num-workspaces 2

# === VYLEPŠENIA PRE VÝVOJÁROV ===

# 11. Zobrazenie milisekúnd v hodinách (užitočné pre debugovanie)
gsettings set org.gnome.desktop.interface clock-show-seconds true
gsettings set org.gnome.desktop.interface clock-format '24h'

# 12. Desktopdocker - povolenie drag-and-drop na Dock
gsettings set org.gnome.shell.extensions.dash-to-dock drag-and-drop true

# === VYLEPŠENIA PRE ŠETRENIE BATÉRIE ===

# 13. Nastavenie automatického stmavenia obrazovky pri nečinnosti
gsettings set org.gnome.settings-daemon.plugins.power idle-dim true

# 14. Nastavenie času do uspania na batérii
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 1800 # v sekundách (30 minút)

# === SÚKROMIE A BEZPEČNOSŤ ===

# 15. Vypnutie automatického posielania správ o pádoch
gsettings set org.gnome.desktop.privacy report-technical-problems false

# 16. Vypnutie sledovania používania
gsettings set org.gnome.desktop.privacy send-software-usage-stats false

# === SPRÁVA OKIEN ===

# 17. Maximalizácia okna potiahnutím na horný okraj obrazovky
gsettings set org.gnome.desktop.wm.preferences action-double-click-titlebar 'toggle-maximize'

# 18. Nastavenie kliknutia na Alt+Tab pre prepínanie iba medzi oknami na aktuálnej pracovnej ploche
gsettings set org.gnome.shell.app-switcher current-workspace-only true

# 19. Zapnutie snap to edges (pritiahnutie okna k okraju obrazovky)
gsettings set org.gnome.mutter edge-tiling true

# 20. Nastavenie altu+Tab pre prepínanie iba medzi aplikáciami (nie oknami)
gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Alt>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Super>Tab']"

# === DOCKBAR A PANEL ===

# 21. Nastavenie automatického skrývania docku
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
gsettings set org.gnome.shell.extensions.dash-to-dock autohide true
gsettings set org.gnome.shell.extensions.dash-to-dock intellihide true

# 22. Presun docku na spodok obrazovky
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'

# 23. Zobrazenie indikátorov otvorených aplikácií
gsettings set org.gnome.shell.extensions.dash-to-dock show-running true

# === OSTATNÉ UŽITOČNÉ NASTAVENIA ===

# 24. Zmena ikony home folderu
gsettings set org.gnome.nautilus.icon-view default-zoom-level 'medium'

# 25. Zapnutie natural scrolling (ako na macOS)
gsettings set org.gnome.desktop.peripherals.mouse natural-scroll true

# 26. Nastavenie klávesových skratiek
gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']"  # otvoriť domovský priečinok
gsettings set org.gnome.settings-daemon.plugins.media-keys www "['<Super>w']"   # otvoriť prehliadač
gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "['<Super>t']"  # otvoriť terminál

# 27. Zobrazenie percent batérie namiesto ikony
gsettings set org.gnome.desktop.interface show-battery-percentage true

# Pre overenie aktuálneho nastavenia (príklad)
# gsettings get org.gnome.desktop.interface clock-show-seconds
