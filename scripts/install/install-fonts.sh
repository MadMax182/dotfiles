#!/bin/bash

# Install fonts from zip files in ~/.userconfig/fonts

FONT_SOURCE="$HOME/.userconfig/fonts"
FONT_DEST="$HOME/.local/share/fonts"
TEMP_DIR=$(mktemp -d)

# Check if source directory exists
if [[ ! -d "$FONT_SOURCE" ]]; then
    echo "Error: Font source directory not found: $FONT_SOURCE"
    exit 1
fi

# Create destination directory if it doesn't exist
mkdir -p "$FONT_DEST"

# Extract and install fonts from each zip file
echo "Installing fonts from $FONT_SOURCE..."
for zip in "$FONT_SOURCE"/*.zip; do
    [[ -e "$zip" ]] || continue
    echo "Extracting: $(basename "$zip")"
    unzip -o -q "$zip" -d "$TEMP_DIR"
done

# Find and copy all font files
find "$TEMP_DIR" -type f \( -iname "*.ttf" -o -iname "*.otf" -o -iname "*.woff" -o -iname "*.woff2" \) -exec cp -v {} "$FONT_DEST/" \;

# Cleanup
rm -rf "$TEMP_DIR"

# Update font cache
echo "Updating font cache..."
fc-cache -fv

echo "Done! Fonts installed."
