#!/bin/bash

# Function to run the main script
update_art() {

    CACHE_DIR="$HOME/.cache/spotify/cover"

    # OUTPUT_FILE: The full path and filename for the saved image.
    OUTPUT_FILE="$CACHE_DIR/current_spotify_art.jpg"
    # PLAYER_NAME: The player instance to target.
    PLAYER_NAME="spotify"

    # --- Main Logic ---

    # 1. Check if the player is available
    if ! playerctl -p "$PLAYER_NAME" status 2>/dev/null; then
        echo "Error: Spotify is not running or not detected by playerctl." >&2
        # Optional: Delete the output file if nothing is playing
        [ -f "$OUTPUT_FILE" ] && rm -f "$OUTPUT_FILE"
        sleep 10
        return 1
    fi

    # 2. Ensure the cache directory exists
    mkdir -p "$CACHE_DIR" 2>/dev/null

    # 3. CRITICAL: Clear existing JPEG images in the cache directory
    # This command lists .jpg files (redirecting errors/output to suppress them)
    # and if any are found, it deletes them.
    if ls "$CACHE_DIR"/*.jpg 1> /dev/null 2>&1; then
        rm -f "$CACHE_DIR"/*.jpg
    fi

    #4. Get the raw image URL from MPRIS metadata
    RAW_URL=$(playerctl -p "$PLAYER_NAME" metadata mpris:artUrl 2>/dev/null)

    if [ -z "$RAW_URL" ]; then
        echo "Error: Could not retrieve album art URL. Is a song playing?" >&2
        sleep 10x
        return 1
    fi

    # 5. FIX THE URL
    # Spotify often reports an incorrect URL prefix (e.g., [open.spotify.com/image/](https://open.spotify.com/image/)).
    # This sed command substitutes the incorrect prefix with the working image host (i.scdn.co/image/).
    FIXED_URL=$(echo "$RAW_URL" | sed 's|^http[s]*://[^/]*[spotify.com/image/](https://spotify.com/image/)|[https://i.scdn.co/image/](https://i.scdn.co/image/)|')

    # 6. Download the image
    # The -q flag is for silent operation. -O specifies the exact output path.
    wget -q -O "$OUTPUT_FILE" "$FIXED_URL"

    # 7. Check for success and report path
    if [ $? -eq 0 ]; then
        echo "$OUTPUT_FILE"
    else
        echo "Error: Failed to download the image from $FIXED_URL." >&2
        sleep 10
        return 1
    fi
}

echo "$(date): Starting album art listener. Output redirected to terminal."

# 1. Run once on startup to ensure current track art is available
update_art

# 2. Use playerctl --follow to watch for metadata changes (track changes)
# The metadata command outputs a line on change, triggering the while loop.
playerctl --follow metadata --format '{{title}}' 2>/dev/null | while read -r line; do
    echo "$(date): Track change detected: $line"
    update_art
    pkill -SIGUSR2 waybar
done

echo "$(date): Listener stopped."
#
