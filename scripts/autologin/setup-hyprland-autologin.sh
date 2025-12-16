#!/bin/bash

# Setup Hyprland autologin on tty1 with 5-second delay
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

# Create the delayed autologin script
sudo tee /usr/local/bin/delayed-autologin > /dev/null << 'SCRIPT_EOF'
#!/bin/bash
USER_TO_LOGIN="__USER_PLACEHOLDER__"

clear
echo ""
echo "╔════════════════════════════════════════════╗"
echo "║  Auto-login in 5 seconds...                ║"
echo "║                                            ║"
echo "║  ENTER  → Start Hyprland immediately       ║"
echo "║  ESC    → Manual login (TTY)               ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# Read single keypress with timeout, checking each second
for remaining in 5 4 3 2 1; do
    printf "\r  [%d] Waiting... " "$remaining"

    if read -t 1 -n 1 -s key 2>/dev/null; then
        if [ "$key" = "" ]; then
            # Enter pressed (empty string with -n 1)
            printf "\n\n  Starting Hyprland...\n\n"
            exec /bin/login -f "$USER_TO_LOGIN"
        elif [ "$key" = $'\e' ]; then
            # Escape pressed
            printf "\n\n  Manual login:\n\n"
            exec /bin/login
        fi
        # Any other key - ignore and continue countdown
    fi
done

# Timeout reached - auto login
printf "\n\n  Starting Hyprland...\n\n"
exec /bin/login -f "$USER_TO_LOGIN"
SCRIPT_EOF

# Replace placeholder with actual username
sudo sed -i "s/__USER_PLACEHOLDER__/$TARGET_USER/" /usr/local/bin/delayed-autologin
sudo chmod +x /usr/local/bin/delayed-autologin

echo "Delayed autologin script created at /usr/local/bin/delayed-autologin"

# Create getty service override directory
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d

# Create autologin configuration using the delayed login script
sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf > /dev/null << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --noclear -l /usr/local/bin/delayed-autologin %I $TERM
EOF

echo "Getty autologin configuration created."

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
echo ""
echo "On boot you will see a 5-second countdown:"
echo "  - Press ENTER to skip and start Hyprland immediately"
echo "  - Press ESC for manual login (TTY access)"
echo "  - Wait 5 seconds for automatic Hyprland start"
echo ""
echo "To reboot now, run: sudo reboot"
