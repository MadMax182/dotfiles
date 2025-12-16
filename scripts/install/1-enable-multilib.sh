#!/bin/bash

# Enable multilib repository in pacman.conf

PACMAN_CONF="/etc/pacman.conf"

# Check if multilib is already enabled
if grep -q "^\[multilib\]" "$PACMAN_CONF"; then
    echo "Multilib is already enabled."
    exit 0
fi

# Check if multilib section exists (commented out)
if ! grep -q "#\[multilib\]" "$PACMAN_CONF"; then
    echo "Error: Could not find [multilib] section in $PACMAN_CONF"
    exit 1
fi

echo "Enabling multilib repository..."

# Uncomment the [multilib] section and the Include line below it
sudo sed -i '/^#\[multilib\]$/,/^#Include/ s/^#//' "$PACMAN_CONF"

# Verify it was enabled
if grep -q "^\[multilib\]" "$PACMAN_CONF"; then
    echo "Multilib enabled successfully."
    echo "Updating package database..."
    sudo pacman -Sy
else
    echo "Error: Failed to enable multilib."
    exit 1
fi
