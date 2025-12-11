#!/bin/sh

# Setup Hyprland autologin on tty1
# Run this script with: bash setup-hyprland-autologin.sh

set -e

USER=$(whoami)

echo "Setting up autologin for user: $USER"

# Create getty service override directory
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d

# Create autologin configuration
sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf > /dev/null << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\\\u' --noclear --autologin $USER %I \$TERM
EOF

echo "Autologin configuration created successfully!"
echo "Reboot your system to enable autologin with Hyprland."
echo ""
echo "To reboot now, run: sudo reboot"
