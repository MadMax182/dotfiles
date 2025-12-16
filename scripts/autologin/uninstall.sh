#!/bin/bash

set -e

OVERRIDE_DIR="/etc/systemd/system/getty@tty1.service.d"
OVERRIDE_FILE="$OVERRIDE_DIR/autologin.conf"

if [[ $EUID -eq 0 ]]; then
    echo "Do not run this script as root. Run as your regular user."
    exit 1
fi

echo "Removing autologin configuration..."

# Remove getty override
if [[ -f "$OVERRIDE_FILE" ]]; then
    sudo rm "$OVERRIDE_FILE"
    echo "Removed $OVERRIDE_FILE"

    # Remove directory if empty
    if [[ -z "$(ls -A $OVERRIDE_DIR 2>/dev/null)" ]]; then
        sudo rmdir "$OVERRIDE_DIR"
        echo "Removed empty directory $OVERRIDE_DIR"
    fi
else
    echo "Autologin override not found, skipping..."
fi

# Remove Hyprland autostart from shell profiles
for PROFILE_FILE in "$HOME/.bash_profile" "$HOME/.zprofile"; do
    if [[ -f "$PROFILE_FILE" ]]; then
        if grep -qF "exec Hyprland" "$PROFILE_FILE"; then
            sed -i '/# Auto-start Hyprland on tty1/d' "$PROFILE_FILE"
            sed -i '/exec Hyprland/d' "$PROFILE_FILE"
            # Remove trailing empty lines
            sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$PROFILE_FILE"
            echo "Removed Hyprland autostart from $PROFILE_FILE"
        fi
    fi
done

# Reload systemd
sudo systemctl daemon-reload

echo ""
echo "Uninstall complete! Autologin and Hyprland autostart removed."
echo "Reboot to apply changes."
