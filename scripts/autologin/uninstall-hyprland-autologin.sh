#!/bin/bash

# Uninstall Hyprland autologin setup
# Run this script with: bash uninstall-hyprland-autologin.sh

set -e

# Get the user
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    TARGET_USER="$SUDO_USER"
elif [ "$(whoami)" != "root" ]; then
    TARGET_USER=$(whoami)
else
    echo "Error: Cannot determine user. Please run as a non-root user or via sudo."
    exit 1
fi

HOME_DIR=$(eval echo ~"$TARGET_USER")

echo "Uninstalling autologin for user: $TARGET_USER"

# Remove boot entries
if [ -f /boot/loader/entries/hyprland.conf ]; then
    sudo rm -f /boot/loader/entries/hyprland.conf
    echo "Removed /boot/loader/entries/hyprland.conf"
fi

if [ -f /boot/loader/entries/tty.conf ]; then
    sudo rm -f /boot/loader/entries/tty.conf
    echo "Removed /boot/loader/entries/tty.conf"
fi

# Remove default setting from loader.conf
sudo sed -i '/^default hyprland.conf/d' /boot/loader/loader.conf

# Remove delayed autologin script (old method)
sudo rm -f /usr/local/bin/delayed-autologin

# Remove getty override
if [ -d /etc/systemd/system/getty@tty1.service.d ]; then
    sudo rm -rf /etc/systemd/system/getty@tty1.service.d
    echo "Removed getty@tty1 override"
fi

# Disable and remove hyprland services
for SERVICE in hyprland.service hyprland-autologin.service; do
    if [ -f /etc/systemd/system/$SERVICE ]; then
        sudo systemctl disable $SERVICE 2>/dev/null || true
        sudo rm -f /etc/systemd/system/$SERVICE
        echo "Removed $SERVICE"
    fi
done

# Disable getty@tty2
sudo systemctl disable getty@tty2.service 2>/dev/null || true

# Reload systemd
sudo systemctl daemon-reload

# Remove Hyprland autostart from shell profiles
for PROFILE in "$HOME_DIR/.zprofile" "$HOME_DIR/.bash_profile"; do
    if [ -f "$PROFILE" ] && grep -q "exec Hyprland" "$PROFILE"; then
        grep -v -E "(# Start Hyprland|XDG_VTNR|exec Hyprland|/proc/cmdline)" "$PROFILE" > "$PROFILE.tmp"
        mv "$PROFILE.tmp" "$PROFILE"
        echo "Removed Hyprland autostart from $PROFILE"
    fi
done

echo ""
echo "Uninstall complete!"
echo ""
echo "You may want to reinstall a display manager:"
echo "  sudo pacman -S sddm && sudo systemctl enable sddm"
echo ""
echo "Reboot to apply changes: sudo reboot"
