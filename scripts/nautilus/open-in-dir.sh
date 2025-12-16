#!/bin/bash
# Opens kitty terminal in the current Nautilus directory if Nautilus is focused
# Otherwise opens kitty in the default directory

# Get active window info from Hyprland
window_info=$(hyprctl activewindow -j)
window_class=$(echo "$window_info" | jq -r '.class // empty')

# Check if the focused window is Nautilus
if [[ "$window_class" == *"nautilus"* || "$window_class" == *"Nautilus"* ]]; then
    dir=""

    # Get current location from Nautilus via D-Bus (most reliable)
    # OpenLocations returns URIs like "file:///home/user/folder"
    location=$(gdbus call --session \
        --dest org.freedesktop.FileManager1 \
        --object-path /org/freedesktop/FileManager1 \
        --method org.freedesktop.DBus.Properties.Get \
        org.freedesktop.FileManager1 OpenLocations 2>/dev/null \
        | grep -oP "file://[^']*" | head -1)

    if [[ -n "$location" ]]; then
        # Decode URI to path (handle %20 spaces, etc.)
        dir=$(python3 -c "from urllib.parse import unquote, urlparse; print(unquote(urlparse('$location').path))" 2>/dev/null)
    fi

    # Verify directory exists
    if [[ -n "$dir" && -d "$dir" ]]; then
        kitty --directory "$dir" &
    else
        kitty &
    fi
else
    # Not Nautilus, just open kitty normally
    kitty &
fi
