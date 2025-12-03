#!/bin/sh

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/waybar.conf"

# Function to start/reload waybar
start_waybar() {
    [ ! -f "$CONFIG_FILE" ] && echo "Error: Config file not found" && return 1

    # Read settings from config file
    THEME_NAME=$(awk -F= '/^theme=/ {gsub(/ /, "", $2); print $2}' "$CONFIG_FILE")
    CUSTOM_CONFIG=$(awk -F= '/^config=/ {gsub(/ /, "", $2); print $2}' "$CONFIG_FILE")
    ENABLED=$(awk -F= '/^enabled=/ {gsub(/ /, "", $2); print $2}' "$CONFIG_FILE")

    # Default enabled to 1 if not specified
    : ${ENABLED:=1}

    # Kill any existing waybar instances first
    killall -q waybar
    sleep 0.2

    # Check if waybar should be disabled
    if [ "$ENABLED" != "1" ]; then
        echo "Waybar is disabled"
        return 0
    fi

    # Check if theme was found
    [ -z "$THEME_NAME" ] && echo "Error: No 'theme=' setting found" && return 1

    THEME_DIR="$SCRIPT_DIR/themes/$THEME_NAME"
    [ ! -d "$THEME_DIR" ] && echo "Error: Theme directory not found" && return 1

    # Determine which config file to use
    if [ -n "$CUSTOM_CONFIG" ]; then
        WAYBAR_CONFIG="$SCRIPT_DIR/$CUSTOM_CONFIG"
    else
        WAYBAR_CONFIG="$THEME_DIR/config"
    fi

    [ ! -f "$WAYBAR_CONFIG" ] && echo "Error: Waybar config not found" && return 1
    [ ! -f "$THEME_DIR/style.css" ] && echo "Error: style.css not found" && return 1

    # Start waybar
    waybar -c "$WAYBAR_CONFIG" -s "$THEME_DIR/style.css" >/dev/null 2>&1 &
    echo "Waybar started with theme: $THEME_NAME"
}

# Kill any existing waybar instances and start fresh
start_waybar
