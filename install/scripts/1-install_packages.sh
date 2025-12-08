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

echo "Updating database and installing with pacman..."
sudo pacman -Sy --noconfirm $PACKAGES_TO_INSTALL

# Check which packages failed to install (likely not in official repos)
FAILED_PACKAGES=""
for pkg in $PACKAGES_TO_INSTALL; do
  if ! pacman -Q "$pkg" &>/dev/null; then
    FAILED_PACKAGES="$FAILED_PACKAGES $pkg"
  fi
done

# If any packages failed, try installing with yay
if [ -n "$FAILED_PACKAGES" ]; then
  FAILED_PACKAGES=$(echo "$FAILED_PACKAGES" | xargs)
  echo
  echo "⚠️  Some packages not found in official repos: $FAILED_PACKAGES"

  if command -v yay &>/dev/null; then
    echo "Attempting to install with yay (AUR)..."
    yay -S --noconfirm $FAILED_PACKAGES
  else
    echo "❌ yay not found. Please install yay to access AUR packages."
    echo "   Packages not installed: $FAILED_PACKAGES"
    exit 1
  fi
fi

echo "✓ Installation complete!"
exit 0
