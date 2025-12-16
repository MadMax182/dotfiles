#!/bin/bash

# Install Nerd Fonts from fonts.list
# Fonts are downloaded from GitHub releases and installed to ~/.local/share/fonts

set -e

FONTS_LIST="$HOME/.userconfig/dependencies/fonts.list"
FONTS_DIR="$HOME/.local/share/fonts/NerdFonts"
NERD_FONTS_VERSION="v3.3.0"
DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if fonts list exists
if [[ ! -f "$FONTS_LIST" ]]; then
    log_error "Fonts list not found: $FONTS_LIST"
    exit 1
fi

# Create fonts directory
mkdir -p "$FONTS_DIR"

# Create temporary directory for downloads
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

log_info "Installing Nerd Fonts (version: $NERD_FONTS_VERSION)"
log_info "Fonts directory: $FONTS_DIR"
echo

# Read fonts list and install each font
while IFS= read -r font || [[ -n "$font" ]]; do
    # Skip empty lines and comments
    [[ -z "$font" || "$font" =~ ^# ]] && continue

    # Trim whitespace
    font=$(echo "$font" | xargs)
    [[ -z "$font" ]] && continue

    log_info "Downloading $font..."

    ZIP_FILE="$TEMP_DIR/${font}.zip"
    FONT_URL="${DOWNLOAD_URL}/${font}.zip"

    if curl -fL --progress-bar -o "$ZIP_FILE" "$FONT_URL"; then
        log_info "Extracting $font..."

        # Create font-specific directory and extract
        FONT_DIR="$FONTS_DIR/$font"
        mkdir -p "$FONT_DIR"

        # Extract only font files (ttf, otf)
        unzip -qo "$ZIP_FILE" "*.ttf" "*.otf" -d "$FONT_DIR" 2>/dev/null || \
        unzip -qo "$ZIP_FILE" -d "$FONT_DIR"

        # Remove LICENSE and README files if extracted
        find "$FONT_DIR" -type f \( -name "LICENSE*" -o -name "README*" -o -name "*.md" -o -name "*.txt" \) -delete 2>/dev/null || true

        log_info "$font installed successfully"
    else
        log_error "Failed to download $font from $FONT_URL"
    fi

    echo
done < "$FONTS_LIST"

# Update font cache
log_info "Updating font cache..."
if command -v fc-cache &> /dev/null; then
    fc-cache -f "$FONTS_DIR"
    log_info "Font cache updated"
else
    log_warn "fc-cache not found, font cache not updated"
fi

log_info "Nerd Fonts installation complete!"
