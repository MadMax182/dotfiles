#!/bin/bash

# Installs applications from apps.list using pacman/yay and flatpak

# Source paths configuration with absolute path
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.userconfig}"
source "$DOTFILES_DIR/paths/paths.conf"

FULL_APP_PATH="$DEPENDENCY_DIR/$APP_FILE"

# Exit if no app file
[ ! -f "$FULL_APP_PATH" ] && echo "No apps file found. Skipping." && exit 0

echo "Reading apps from: $FULL_APP_PATH"

# Separate flatpak apps from regular apps
FLATPAK_APPS=""
REGULAR_APPS=""

while IFS= read -r line; do
  # Remove comments and trim whitespace
  line=$(echo "$line" | sed 's/#.*//;s/^[[:space:]]*//;s/[[:space:]]*$//')

  # Skip empty lines
  [ -z "$line" ] && continue

  # Check if line starts with flatpak:
  if [[ "$line" =~ ^flatpak: ]]; then
    app_name="${line#flatpak:}"
    app_name=$(echo "$app_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    FLATPAK_APPS="$FLATPAK_APPS $app_name"
  else
    REGULAR_APPS="$REGULAR_APPS $line"
  fi
done < "$FULL_APP_PATH"

# Trim leading/trailing spaces
FLATPAK_APPS=$(echo "$FLATPAK_APPS" | xargs)
REGULAR_APPS=$(echo "$REGULAR_APPS" | xargs)

[ -z "$FLATPAK_APPS" ] && [ -z "$REGULAR_APPS" ] && echo "No apps found." && exit 0

echo "Total regular apps found: $(echo "$REGULAR_APPS" | wc -w)"
echo "Total flatpak apps found: $(echo "$FLATPAK_APPS" | wc -w)"

# Process regular apps (pacman/yay)
if [ -n "$REGULAR_APPS" ]; then
  echo
  echo "=== Installing regular apps with pacman/yay ==="

  # Filter uninstalled apps
  APPS_TO_INSTALL=$(echo "$REGULAR_APPS" | tr ' ' '\n' | while read app; do
    pacman -Q "$app" &>/dev/null || echo "$app"
  done | xargs)

  if [ -z "$APPS_TO_INSTALL" ]; then
    echo "🎉 All regular apps already installed."
  else
    echo "Regular apps to install: $APPS_TO_INSTALL"
    echo

    # Try installing with pacman first
    echo "Updating database and installing with pacman..."
    sudo pacman -Sy --noconfirm $APPS_TO_INSTALL

    # Check for apps that failed (not found in official repos)
    FAILED_APPS=$(echo "$APPS_TO_INSTALL" | tr ' ' '\n' | while read app; do
      pacman -Q "$app" &>/dev/null || echo "$app"
    done | xargs)

    if [ -n "$FAILED_APPS" ]; then
      echo
      echo "⚠️  Some apps not found in official repos: $FAILED_APPS"
      echo "These may be available in the AUR (Arch User Repository)."

      # Try installing failed apps with yay if available
      if command -v yay &>/dev/null; then
        echo
        echo "Installing AUR apps with yay..."
        yay -S --noconfirm $FAILED_APPS
      else
        echo
        echo "yay is not installed. Skipping AUR apps."
        echo "Run the dependencies script first to install yay."
      fi
    fi
  fi
fi

# Process flatpak apps
if [ -n "$FLATPAK_APPS" ]; then
  echo
  echo "=== Installing flatpak apps ==="

  # Check if flatpak is installed
  if ! command -v flatpak &>/dev/null; then
    echo "flatpak is not installed."
    read -p "Do you want to install flatpak? (y/n): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo "Installing flatpak..."
      sudo pacman -S --needed --noconfirm flatpak

      echo "Adding Flathub repository..."
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

      echo "✓ flatpak installed successfully!"
    else
      echo "Skipping flatpak apps."
      exit 0
    fi
  fi

  # Filter uninstalled flatpak apps
  FLATPAKS_TO_INSTALL=""
  for app in $FLATPAK_APPS; do
    if ! flatpak list --app | grep -q "$app"; then
      FLATPAKS_TO_INSTALL="$FLATPAKS_TO_INSTALL $app"
    fi
  done

  FLATPAKS_TO_INSTALL=$(echo "$FLATPAKS_TO_INSTALL" | xargs)

  if [ -z "$FLATPAKS_TO_INSTALL" ]; then
    echo "🎉 All flatpak apps already installed."
  else
    echo "Flatpak apps to install: $FLATPAKS_TO_INSTALL"
    echo

    for app in $FLATPAKS_TO_INSTALL; do
      echo "Installing $app..."
      flatpak install -y flathub "$app"
    done
  fi
fi

echo
echo "✓ Installation complete!"
exit 0
