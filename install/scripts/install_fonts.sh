#!/bin/bash

# Installs Nerd Fonts from fonts.list

source "./paths/paths.conf"

FULL_FONT_PATH="$DEPENDENCY_DIR/$FONT_FILE"

[ ! -f "$FULL_FONT_PATH" ] && echo "No fonts.list found. Skipping." && exit 0

echo "Reading fonts from: $FULL_FONT_PATH"

fonts_to_install=$(sed 's/#.*//;s/^[[:space:]]*//;s/[[:space:]]*$//' "$FULL_FONT_PATH" | grep -v "^$" | xargs)

[ -z "$fonts_to_install" ] && echo "No fonts found." && exit 0

mkdir -p "$NERD_FONTS_DIR"

NERD_FONTS_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"

# Check which fonts need installation
fonts_needed=$(echo "$fonts_to_install" | tr ' ' '\n' | while read font; do
  [ ! -d "$NERD_FONTS_DIR/$font" ] || [ -z "$(ls -A "$NERD_FONTS_DIR/$font" 2>/dev/null)" ] && echo "$font"
done | xargs)

[ -z "$fonts_needed" ] && echo "🎉 All fonts already installed." && exit 0

echo "Fonts to install: $fonts_needed"
echo

# Install fonts
for font in $fonts_needed; do
  echo "Installing $font..."
  font_zip="${font}.zip"
  font_path="$NERD_FONTS_DIR/$font"

  mkdir -p "$font_path"

  if curl -fsSL -o "/tmp/$font_zip" "$NERD_FONTS_URL/$font_zip" 2>/dev/null; then
    unzip -qq -o "/tmp/$font_zip" -d "$font_path" && rm -f "/tmp/$font_zip"
    echo "  ✓ $font installed"
  else
    echo "  ✗ Failed to download $font"
  fi
done

# Update font cache
command -v fc-cache &>/dev/null && fc-cache -fv "$NERD_FONTS_DIR" || echo "Warning: fc-cache not found"

echo "✓ Font installation complete!"
exit 0
