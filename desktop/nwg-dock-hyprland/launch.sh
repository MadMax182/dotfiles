#!/usr/bin/env bash
#    ___           __
#   / _ \___  ____/ /__
#  / // / _ \/ __/  '_/
# /____/\___/\__/_/\_\
#

cd "$(dirname "$0")"
echo "Current working directory is now: $(pwd)"

DOCK_THEME="modern"
if [ -f ./theme.conf ]; then
    DOCK_THEME=$(cat ./themes/theme.conf)
fi
echo ":: Using Dock Theme $DOCK_THEME"
echo ":: Dock Autohide $DOCK_AUTOHIDE"
if [ ! -f ./dock-disabled ]; then
    killall nwg-dock-hyprland
    sleep 0.5
    if [ -f ./dock-autohide ]; then
        nwg-dock-hyprland -d -i 32 -w 5 -mb 10 -x -s themes/$DOCK_THEME/style.css -c "$HOME/.config/hypr/scripts/launcher.sh"
    else
        nwg-dock-hyprland -i 32 -w 5 -mb 10 -x -s themes/$DOCK_THEME/style.css -c "$HOME/.config/hypr/scripts/launcher.sh"
    fi
else
    echo ":: Dock disabled"
fi
