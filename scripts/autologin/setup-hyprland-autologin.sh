#!/bin/bash

# Setup Hyprland and TTY boot entries
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

echo "Setting up boot entries for user: $TARGET_USER"

# Remove SDDM if installed
if pacman -Qi sddm > /dev/null 2>&1; then
    echo "SDDM detected, removing..."
    sudo systemctl disable sddm --now 2>/dev/null || true
    sudo pacman -Rns --noconfirm sddm
    echo "SDDM removed."
fi

# Clean up old methods
sudo rm -f /usr/local/bin/delayed-autologin
sudo rm -rf /etc/systemd/system/getty@tty1.service.d
sudo rm -f /etc/systemd/system/hyprland.service
sudo systemctl disable hyprland.service 2>/dev/null || true

# Find existing boot entry to use as template
BOOT_ENTRY=$(ls /boot/loader/entries/*.conf 2>/dev/null | head -1)
if [ -z "$BOOT_ENTRY" ]; then
    echo "Error: No existing boot entry found in /boot/loader/entries/"
    exit 1
fi

echo "Using $BOOT_ENTRY as template"

# Extract options from existing entry
LINUX=$(grep "^linux" "$BOOT_ENTRY" | head -1)
INITRD=$(grep "^initrd" "$BOOT_ENTRY")
OPTIONS=$(grep "^options" "$BOOT_ENTRY" | sed 's/^options\s*//')

# Create Hyprland boot entry
sudo tee /boot/loader/entries/hyprland.conf > /dev/null << EOF
title   Hyprland
$LINUX
$INITRD
options $OPTIONS hyprland
EOF

echo "Created /boot/loader/entries/hyprland.conf"

# Create TTY boot entry
sudo tee /boot/loader/entries/tty.conf > /dev/null << EOF
title   Arch Linux (TTY)
$LINUX
$INITRD
options $OPTIONS
EOF

echo "Created /boot/loader/entries/tty.conf"

# Set Hyprland as default
sudo sed -i '/^default/d' /boot/loader/loader.conf
echo "default hyprland.conf" | sudo tee -a /boot/loader/loader.conf > /dev/null

echo "Set hyprland.conf as default boot entry"

# Create getty override for autologin when hyprland kernel param is present
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf > /dev/null << EOF
[Service]
ExecStartPre=/bin/sh -c '! grep -q hyprland /proc/cmdline || exit 0'
EOF

# Create hyprland-autologin service
sudo tee /etc/systemd/system/hyprland-autologin.service > /dev/null << EOF
[Unit]
Description=Hyprland Autologin
ConditionKernelCommandLine=hyprland
After=systemd-user-sessions.service
Conflicts=getty@tty1.service

[Service]
Type=simple
ExecStart=/sbin/agetty -o '-p -f -- \\u' --noclear --autologin $TARGET_USER tty1 \$TERM
Restart=always
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
sudo systemctl enable hyprland-autologin.service

echo "hyprland-autologin.service: Enabled"

# Setup Hyprland autostart in shell profile (only when hyprland param present)
HYPRLAND_AUTOSTART='# Start Hyprland on tty1 if booted with hyprland kernel param
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ] && grep -q hyprland /proc/cmdline; then
    exec Hyprland
fi'

# Determine shell profile to use
if [ -f "$HOME_DIR/.zprofile" ] || command -v zsh > /dev/null 2>&1; then
    PROFILE="$HOME_DIR/.zprofile"
else
    PROFILE="$HOME_DIR/.bash_profile"
fi

# Remove old Hyprland autostart block if present
if grep -q "exec Hyprland" "$PROFILE" 2>/dev/null; then
    grep -v -E "(# Start Hyprland|XDG_VTNR|exec Hyprland)" "$PROFILE" > "$PROFILE.tmp"
    mv "$PROFILE.tmp" "$PROFILE"
fi

# Add new Hyprland autostart
echo "" >> "$PROFILE"
echo "$HYPRLAND_AUTOSTART" >> "$PROFILE"
echo "Hyprland autostart added to $PROFILE"

echo ""
echo "Setup complete!"
echo ""
echo "Boot entries:"
echo "  Hyprland        - Autologin + starts Hyprland (default)"
echo "  Arch Linux (TTY) - Normal TTY login"
echo ""
echo "To reboot now, run: sudo reboot"
