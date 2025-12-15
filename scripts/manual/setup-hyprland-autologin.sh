#!/bin/sh

# Setup Hyprland autologin on tty1
# Run this script with: bash setup-hyprland-autologin.sh

set -e

USER=$(whoami)
HOME_DIR=$(eval echo ~$USER)

echo "Setting up autologin for user: $USER"

# Remove SDDM if installed
if pacman -Qi sddm > /dev/null 2>&1; then
    echo "SDDM detected, removing..."
    sudo systemctl disable sddm --now 2>/dev/null || true
    sudo pacman -Rns --noconfirm sddm
    echo "SDDM removed."
fi

# Create getty service override directory
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d

# Create autologin configuration
sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf > /dev/null << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\\\u' --noclear --autologin $USER %I \$TERM
EOF

echo "Autologin configuration created."

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
echo "Setup complete! Reboot your system to start Hyprland automatically."
echo "To reboot now, run: sudo reboot"
