#!/bin/bash

# Installs system packages from dependencies.list using pacman

source "./paths/paths.conf"

FULL_DEP_PATH="$DEPENDENCY_DIR/$DEPENDENCY_FILE"

# Exit if no dependency file
[ ! -f "$FULL_DEP_PATH" ] && echo "No dependency file found. Skipping." && exit 0

echo "Reading packages from: $FULL_DEP_PATH"

# Gather and filter packages in one pass
ALL_PACKAGES=$(sed 's/#.*//;s/^[[:space:]]*//;s/[[:space:]]*$//' "$FULL_DEP_PATH" | grep -v "^$" | xargs)

[ -z "$ALL_PACKAGES" ] && echo "No packages found." && exit 0

echo "Total packages found: $(echo "$ALL_PACKAGES" | wc -w)"

# Filter uninstalled packages
PACKAGES_TO_INSTALL=$(echo "$ALL_PACKAGES" | tr ' ' '\n' | while read pkg; do
  pacman -Q "$pkg" &>/dev/null || echo "$pkg"
done | xargs)

[ -z "$PACKAGES_TO_INSTALL" ] && echo "🎉 All packages already installed." && exit 0

echo "Packages to install: $PACKAGES_TO_INSTALL"
echo

echo "Updating database and installing..."
sudo pacman -Sy --noconfirm $PACKAGES_TO_INSTALL

echo "✓ Installation complete!"
exit 0
