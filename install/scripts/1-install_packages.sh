#!/bin/bash

# Installs system packages from dependencies.list using pacman, with yay fallback for AUR packages

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

# Try installing with pacman first
echo "Updating database and installing with pacman..."
sudo pacman -Sy --noconfirm $PACKAGES_TO_INSTALL

# Check for packages that failed (not found in official repos)
FAILED_PACKAGES=$(echo "$PACKAGES_TO_INSTALL" | tr ' ' '\n' | while read pkg; do
  pacman -Q "$pkg" &>/dev/null || echo "$pkg"
done | xargs)

if [ -n "$FAILED_PACKAGES" ]; then
  echo
  echo "⚠️  Some packages not found in official repos: $FAILED_PACKAGES"
  echo "These may be available in the AUR (Arch User Repository)."

  # Check if yay is installed
  if ! command -v yay &>/dev/null; then
    echo
    echo "yay (AUR helper) is not installed."
    read -p "Do you want to install yay to access AUR packages? (y/n): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo "Installing yay..."

      # Install dependencies for building yay
      sudo pacman -S --needed --noconfirm git base-devel

      # Clone and build yay
      TEMP_DIR=$(mktemp -d)
      cd "$TEMP_DIR"
      git clone https://aur.archlinux.org/yay.git
      cd yay
      makepkg -si --noconfirm
      cd -
      rm -rf "$TEMP_DIR"

      echo "✓ yay installed successfully!"
    else
      echo "Skipping AUR packages. Some packages may not be installed."
      exit 0
    fi
  fi

  # Try installing failed packages with yay
  if command -v yay &>/dev/null; then
    echo
    echo "Installing AUR packages with yay..."
    yay -S --noconfirm $FAILED_PACKAGES
  fi
fi

echo
echo "✓ Installation complete!"
exit 0
