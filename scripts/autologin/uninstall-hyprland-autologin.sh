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

# Remove delayed autologin script
if [ -f /usr/local/bin/delayed-autologin ]; then
    sudo rm -f /usr/local/bin/delayed-autologin
    echo "Removed /usr/local/bin/delayed-autologin"
fi

# Remove getty override (old method)
if [ -d /etc/systemd/system/getty@tty1.service.d ]; then
    sudo rm -rf /etc/systemd/system/getty@tty1.service.d
    echo "Removed getty@tty1 autologin override"
fi

# Disable and remove hyprland.service
if [ -f /etc/systemd/system/hyprland.service ]; then
    sudo systemctl disable hyprland.service 2>/dev/null || true
    sudo rm -f /etc/systemd/system/hyprland.service
    echo "Removed hyprland.service"
fi

# Re-enable getty@tty1
sudo systemctl enable getty@tty1.service 2>/dev/null || true

# Disable getty@tty2
sudo systemctl disable getty@tty2.service 2>/dev/null || true

# Reload systemd
sudo systemctl daemon-reload

# Remove Hyprland autostart from shell profiles
for PROFILE in "$HOME_DIR/.zprofile" "$HOME_DIR/.bash_profile"; do
    if [ -f "$PROFILE" ] && grep -q "exec Hyprland" "$PROFILE"; then
        # Create temp file without the Hyprland block
        grep -v -E "(# Start Hyprland on tty1|XDG_VTNR|exec Hyprland)" "$PROFILE" > "$PROFILE.tmp"
        # Remove trailing blank lines
        sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$PROFILE.tmp" 2>/dev/null || true
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
