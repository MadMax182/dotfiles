#!/bin/bash

# Removed 'set -e' to allow commands to fail without the script immediately exiting
# This ensures the final exit status is 0, as requested, even if installation steps fail.

# sets the working directory to the scripts directory
# This ensures the script can find the dependency file regardless of where it is executed from.
cd "$(dirname "$0")"
echo "Current working directory is now: $(pwd)"

# --- Configuration ---
DEPENDENCY_DIR="./dependencies"
SCRIPTS_DIR="./install-scripts"
DEPENDENCY_FILE="dependencies.list"
FONT_FILE="fonts.list"
NERD_FONTS_DIR="$HOME/.local/share/fonts/NerdFonts"

FULL_DEP_PATH="$DEPENDENCY_DIR/$DEPENDENCY_FILE"
FULL_FONT_PATH="$DEPENDENCY_DIR/$FONT_FILE"
ALL_PACKAGES=""
PACKAGES_TO_INSTALL="" # New variable to hold only the packages that need installation

# Check if the single dependency file exists
if [ ! -f "$FULL_DEP_PATH" ]; then
  echo "Error: Dependency file not found at $FULL_DEP_PATH" >&2
  echo "Please create a 'dependencies' folder and a file named 'dependencies.list' inside it." >&2
  # Changed from exit 1 to exit 0 to ensure a non-zero exit code is never returned
  exit 0
fi

echo "--- Installing dependencies from single list: $FULL_DEP_PATH ---"

# --- 1. Auto-Detect Package Manager ---

# Function to check for package manager and set variables
detect_pkg_manager() {
  if command -v apt-get &>/dev/null; then
    PKG_MANAGER="apt-get"
    INSTALL_CMD="install -y"
    UPDATE_CMD="update"
  elif command -v dnf &>/dev/null; then
    PKG_MANAGER="dnf"
    INSTALL_CMD="install -y"
    UPDATE_CMD="check-update"
  elif command -v yum &>/dev/null; then
    PKG_MANAGER="yum"
    INSTALL_CMD="install -y"
    UPDATE_CMD="check-update"
  elif command -v pacman &>/dev/null; then
    PKG_MANAGER="pacman"
    # pacman requires confirmation, use --noconfirm
    INSTALL_CMD="-S --noconfirm"
    UPDATE_CMD="-Sy" # Synchronize package databases
  else
    echo "Error: No supported package manager (apt-get, dnf, yum, pacman) found." >&2
    # Changed from exit 1 to exit 0 to ensure a non-zero exit code is never returned
    exit 0
  fi
  echo "Using package manager: $PKG_MANAGER"
}

# --- 2. Gather All Packages from List ---

gather_packages() {
  echo "Reading $DEPENDENCY_FILE..."

  # Read the file contents, remove inline comments, filter out full-line comments and empty lines
  # sed removes everything after # (inline comments) and leading/trailing spaces
  ALL_PACKAGES=$(sed 's/#.*//;s/^[ \t]*//;s/[ \t]*$//' "$FULL_DEP_PATH" | grep -v "^$" | tr '\n' ' ')

  # Use xargs to ensure packages are cleanly separated by single spaces
  ALL_PACKAGES=$(echo "$ALL_PACKAGES" | xargs)

  if [ -z "$ALL_PACKAGES" ]; then
    echo "Warning: No packages found in $DEPENDENCY_FILE after filtering comments. Exiting installation."
    exit 0
  fi

  echo "Total unique packages found: $(echo "$ALL_PACKAGES" | wc -w)"
}

# --- 3. Check Installation Status and Filter Packages ---

# Function to check if a single package is installed based on the detected package manager
is_installed() {
  local pkg_name="$1"

  case "$PKG_MANAGER" in
  apt-get)
    # Use dpkg -s (status) which is efficient and reliable on Debian/Ubuntu
    dpkg -s "$pkg_name" &>/dev/null
    return $? # Returns 0 if installed, non-zero otherwise
    ;;
  dnf | yum)
    # Use rpm -q (query) for RHEL/Fedora/CentOS
    rpm -q "$pkg_name" &>/dev/null
    return $?
    ;;
  pacman)
    # Use pacman -Q (query) for Arch Linux
    pacman -Q "$pkg_name" &>/dev/null
    return $?
    ;;
  *)
    # Fallback: cannot check status, assume not installed to proceed with installation attempt
    return 1
    ;;
  esac
}

# Function to filter the full list of packages
filter_packages() {
  local packages_found=0
  PACKAGES_TO_INSTALL=""

  echo ""
  echo "--- Checking for packages to install ---"

  for pkg in $ALL_PACKAGES; do
    if is_installed "$pkg"; then
      # Package already installed, skip silently
      :
    else
      PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL $pkg"
      packages_found=1
    fi
  done

  # Clean up whitespace
  PACKAGES_TO_INSTALL=$(echo "$PACKAGES_TO_INSTALL" | xargs)

  if [ $packages_found -eq 0 ]; then
    echo "🎉 All required packages are already installed. Skipping installation phase."
  else
    echo "Packages to install: $PACKAGES_TO_INSTALL"
  fi
}

# --- 4. Run the Installation ---

detect_pkg_manager
gather_packages
filter_packages # New step: filter the list

if [ -n "$PACKAGES_TO_INSTALL" ]; then
  echo ""
  read -p "Do you want to install packages? (y/n): " install_packages

  if [[ "$install_packages" =~ ^[Yy]$ ]]; then
    echo "--- Running installation commands (might require password for sudo) ---"

    # Step 1: Update package list (Always good practice before installing)
    echo "Updating package index..."
    # Added '|| true' to ignore potential failure and ensure a zero exit status
    sudo "$PKG_MANAGER" "$UPDATE_CMD" || true

    # Step 2: Install packages
    echo "Installing packages..."

    # Note: Use PACKAGES_TO_INSTALL instead of ALL_PACKAGES
    if [ "$PKG_MANAGER" == "pacman" ]; then
      # Added '|| true' to ignore potential failure and ensure a zero exit status
      sudo "$PKG_MANAGER" $INSTALL_CMD $PACKAGES_TO_INSTALL || true
    else
      # Standard apt/dnf/yum structure. Added '|| true'
      sudo "$PKG_MANAGER" $INSTALL_CMD $PACKAGES_TO_INSTALL || true
    fi

    echo "--- Dependency installation complete! ---"
  else
    echo "Skipping package installation."
  fi
fi

# --- 5. Nerd Fonts Installation ---

install_nerd_fonts() {
  if [ ! -f "$FULL_FONT_PATH" ]; then
    echo ""
    echo "No fonts.list file found in dependencies folder. Skipping Nerd Fonts installation."
    return 0
  fi

  echo ""
  echo "--- Installing Nerd Fonts from list: $FULL_FONT_PATH ---"

  # Read fonts from file, filter out comments and empty lines
  # sed removes inline comments (everything after #) and trims whitespace
  local fonts_to_install=$(sed 's/#.*//;s/^[ \t]*//;s/[ \t]*$//' "$FULL_FONT_PATH" | grep -v "^$" | xargs)

  if [ -z "$fonts_to_install" ]; then
    echo "No fonts found in $FONT_FILE. Skipping font installation."
    return 0
  fi

  # Create fonts directory if it doesn't exist
  mkdir -p "$NERD_FONTS_DIR" || true

  # Base URL for Nerd Fonts releases
  local NERD_FONTS_RELEASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"

  # Check which fonts need to be installed
  local fonts_needed=""
  for font in $fonts_to_install; do
    local font_path="$NERD_FONTS_DIR/$font"
    if [ ! -d "$font_path" ] || [ ! "$(ls -A "$font_path" 2>/dev/null)" ]; then
      fonts_needed="$fonts_needed $font"
    fi
  done

  fonts_needed=$(echo "$fonts_needed" | xargs)

  if [ -z "$fonts_needed" ]; then
    echo "🎉 All required fonts are already installed."
    return 0
  fi

  echo "Fonts to install: $fonts_needed"
  echo ""
  read -p "Do you want to install Nerd Fonts? (y/n): " install_fonts

  if [[ ! "$install_fonts" =~ ^[Yy]$ ]]; then
    echo "Skipping Nerd Fonts installation."
    return 0
  fi

  # Install each font
  for font in $fonts_needed; do
    echo ""
    echo "Installing $font..."

    local font_zip="${font}.zip"
    local font_path="$NERD_FONTS_DIR/$font"

    # Create font-specific directory
    mkdir -p "$font_path" || true

    # Download the font
    echo "  Downloading $font_zip..."
    if wget -q --show-progress -O "/tmp/$font_zip" "$NERD_FONTS_RELEASE_URL/$font_zip" 2>/dev/null || curl -L -o "/tmp/$font_zip" "$NERD_FONTS_RELEASE_URL/$font_zip" 2>/dev/null; then
      echo "  Extracting $font_zip..."
      unzip -q -o "/tmp/$font_zip" -d "$font_path" || true
      rm -f "/tmp/$font_zip" || true
      echo "  ✓ $font installed successfully"
    else
      echo "  ✗ Failed to download $font. Please check the font name and try again."
      echo "    Valid names can be found at: https://github.com/ryanoasis/nerd-fonts/releases"
    fi
  done

  # Update font cache
  echo ""
  echo "Updating font cache..."
  if command -v fc-cache &>/dev/null; then
    fc-cache -fv "$NERD_FONTS_DIR" || true
    echo "✓ Font cache updated"
  else
    echo "Warning: fc-cache not found. You may need to update font cache manually."
  fi

  echo ""
  echo "--- Nerd Fonts installation complete! ---"
  echo "Fonts installed in: $NERD_FONTS_DIR"
}

# Run Nerd Fonts installation
install_nerd_fonts

# --- 6. Link Config Folders ---

link_configs() {
  if [ ! -f "$SCRIPTS_DIR/link-configs.sh" ]; then
    echo ""
    echo "No link-configs.sh script found. Skipping config linking."
    return 0
  fi

  echo ""
  echo "--- Config Linking ---"
  read -p "Do you want to link config folders? (y/n): " link_configs

  if [[ "$link_configs" =~ ^[Yy]$ ]]; then
    echo "Running link-configs.sh..."
    bash ./link-configs.sh || true
  else
    echo "Skipping config linking."
  fi
}

# Run config linking
link_configs

# Explicitly ensure the script exits with status 0
exit 0
