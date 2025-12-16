#!/bin/bash

set -e

USER_NAME=$(whoami)
OVERRIDE_DIR="/etc/systemd/system/getty@tty1.service.d"
OVERRIDE_FILE="$OVERRIDE_DIR/autologin.conf"

if [[ $EUID -eq 0 ]]; then
    echo "Do not run this script as root. Run as your regular user."
    exit 1
fi

echo "Setting up autologin for user: $USER_NAME"

# Create getty override for autologin
sudo mkdir -p "$OVERRIDE_DIR"
sudo tee "$OVERRIDE_FILE" > /dev/null << EOF
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $USER_NAME --noclear %I \$TERM
EOF

echo "Created autologin override at $OVERRIDE_FILE"

# Add Hyprland autostart to shell profile
PROFILE_FILE="$HOME/.bash_profile"
HYPR_START='[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec Hyprland'

if [[ -f "$HOME/.zprofile" ]]; then
    PROFILE_FILE="$HOME/.zprofile"
fi

if ! grep -qF "exec Hyprland" "$PROFILE_FILE" 2>/dev/null; then
    echo "" >> "$PROFILE_FILE"
    echo "# Auto-start Hyprland on tty1" >> "$PROFILE_FILE"
    echo "$HYPR_START" >> "$PROFILE_FILE"
    echo "Added Hyprland autostart to $PROFILE_FILE"
else
    echo "Hyprland autostart already configured in $PROFILE_FILE"
fi

# Reload systemd
sudo systemctl daemon-reload

echo ""
echo "Setup complete! Autologin and Hyprland autostart configured."
echo "Reboot to test the configuration."
