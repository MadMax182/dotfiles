#!/bin/bash
# Monitor detection script for Hyprland
# Switches between docked (external monitor) and 1080p60 (laptop only) configs

LAPTOP_CONF="$HOME/.config/hypr/config/laptop.conf"
MONITOR_DIR="$HOME/.config/hypr/settings/monitor"

# Get all connected monitors
monitors=$(hyprctl monitors -j)

# Check if any external monitor is connected (not eDP-*)
external_count=$(echo "$monitors" | jq '[.[] | select(.name | startswith("eDP") | not)] | length')

if [[ "$external_count" -gt 0 ]]; then
  # External monitor connected - use docked config
  sed -i 's|source = ~/.config/hypr/settings/monitor/.*\.conf|source = ~/.config/hypr/settings/monitor/docked.conf|' "$LAPTOP_CONF"
  echo "docked"
else
  # No external monitor - use laptop 1080p60
  sed -i 's|source = ~/.config/hypr/settings/monitor/.*\.conf|source = ~/.config/hypr/settings/monitor/1080p60.conf|' "$LAPTOP_CONF"
  echo "undocked"
fi
