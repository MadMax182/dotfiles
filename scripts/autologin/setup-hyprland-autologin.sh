#!/bin/bash

# Setup Hyprland autologin on tty1, manual login on tty2
# Run this script with: bash setup-hyprland-autologin.sh

set -e

# Get the user - if run as root via sudo, get the actual user
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    TARGET_USER="$SUDO_USER"
elif [ "$(whoami)" != "root" ]; then
    TARGET_USER=$(whoami)
else
    echo "Error: Cannot determine user. Please run as a non-root user or via sudo."
    exit 1
fi

HOME_DIR=$(eval echo ~"$TARGET_USER")

echo "Setting up autologin for user: $TARGET_USER"

# Remove SDDM if installed
if pacman -Qi sddm > /dev/null 2>&1; then
    echo "SDDM detected, removing..."
    sudo systemctl disable sddm --now 2>/dev/null || true
    sudo pacman -Rns --noconfirm sddm
    echo "SDDM removed."
fi

# Remove old delayed-autologin script if it exists
sudo rm -f /usr/local/bin/delayed-autologin

# Remove old getty override if it exists
sudo rm -rf /etc/systemd/system/getty@tty1.service.d

# Disable getty on tty1 (hyprland.service will use it)
sudo systemctl disable getty@tty1.service 2>/dev/null || true

# Create hyprland.service for autologin + Hyprland on tty1
sudo tee /etc/systemd/system/hyprland.service > /dev/null << EOF
[Unit]
Description=Hyprland (tty1)
After=systemd-user-sessions.service plymouth-quit-wait.service
After=getty@tty1.service
Conflicts=getty@tty1.service

[Service]
Type=simple
ExecStart=/sbin/agetty -o '-p -f -- \\u' --noclear --autologin $TARGET_USER tty1 \$TERM
Restart=always
RestartSec=0
UtmpIdentifier=tty1
TTYPath=/dev/tty1
TTYReset=yes
TTYVHangup=yes
TTYVTDisallocate=yes
StandardInput=tty
StandardOutput=tty

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable hyprland.service

echo "hyprland.service: Enabled (tty1)"

# Enable getty on tty2 for manual login
sudo systemctl enable getty@tty2.service

echo "getty@tty2.service: Enabled (manual login)"

# Setup Hyprland autostart on tty1
HYPRLAND_AUTOSTART='# Start Hyprland on tty1
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
    exec Hyprland
fi'

# Determine shell profile to use
if [ -f "$HOME_DIR/.zprofile" ] || command -v zsh > /dev/null 2>&1; then
    PROFILE="$HOME_DIR/.zprofile"
else
    PROFILE="$HOME_DIR/.bash_profile"
fi

# Add Hyprland autostart if not already present
if ! grep -q "exec Hyprland" "$PROFILE" 2>/dev/null; then
    echo "" >> "$PROFILE"
    echo "$HYPRLAND_AUTOSTART" >> "$PROFILE"
    echo "Hyprland autostart added to $PROFILE"
else
    echo "Hyprland autostart already configured in $PROFILE"
fi

echo ""
echo "Setup complete!"
echo ""
echo "  hyprland.service  (tty1): Hyprland starts automatically on boot"
echo "  getty@tty2.service (tty2): Manual TTY login (Ctrl+Alt+F2)"
echo ""
echo "To reboot now, run: sudo reboot"
