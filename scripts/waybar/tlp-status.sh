#!/bin/bash
# TLP status script for waybar

if [[ "$1" == "toggle" ]]; then
  current=$(tlp-stat -s 2>/dev/null | grep "Power source" | awk '{print $4}')
  if [[ "$current" == "AC" ]]; then
    sudo tlp bat
  else
    sudo tlp ac
  fi
  exit 0
fi

# Get current mode
mode=$(tlp-stat -s 2>/dev/null | grep "Power source" | awk '{print $4}')

case "$mode" in
AC)
  icon="󰓅"
  tooltip="TLP: AC (Performance)"
  ;;
Battery | battery)
  icon=""
  tooltip="TLP: Battery (Power Saver)"
  ;;
esac

echo "{\"text\": \"$icon\", \"tooltip\": \"$tooltip\", \"alt\": \"$mode\", \"class\": \"$mode\"}"
