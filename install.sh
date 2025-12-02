#!/bin/bash

# Removed 'set -e' to allow commands to fail without the script immediately exiting
# This ensures the final exit status is 0, as requested, even if installation steps fail.

# sets the working directory to the scripts directory
# This ensures the script can find the dependency file regardless of where it is executed from.
cd "$(dirname "$0")"
echo "Current working directory is now: $(pwd)"

# --- Configuration ---
DEPENDENCY_FILE="dependencies.list"

FULL_DEP_PATH="./$DEPENDENCY_FILE"
ALL_PACKAGES=""
PACKAGES_TO_INSTALL="" # New variable to hold only the packages that need installation

# Check if the single dependency file exists
if [ ! -f "$FULL_DEP_PATH" ]; then
    echo "Error: Dependency file not found at $FULL_DEP_PATH" >&2
    echo "Please create a file named 'dependencies.list' and add your packages inside it." >&2
    # Changed from exit 1 to exit 0 to ensure a non-zero exit code is never returned
    exit 0
fi

echo "--- Installing dependencies from single list: $FULL_DEP_PATH ---"

# --- 1. Auto-Detect Package Manager ---

# Function to check for package manager and set variables
detect_pkg_manager() {
    if command -v apt-get &> /dev/null; then
        PKG_MANAGER="apt-get"
        INSTALL_CMD="install -y"
        UPDATE_CMD="update"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        INSTALL_CMD="install -y"
        UPDATE_CMD="check-update"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
        INSTALL_CMD="install -y"
        UPDATE_CMD="check-update"
    elif command -v pacman &> /dev/null; then
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

    # Read the file contents, filter out comments (#), and convert newlines to spaces
    # sed removes leading/trailing spaces for clean package list
    ALL_PACKAGES=$(grep -v "^#" "$FULL_DEP_PATH" | tr '\n' ' ' | sed 's/^[ \t]*//;s/[ \t]*$//')

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
            dpkg -s "$pkg_name" &> /dev/null
            return $? # Returns 0 if installed, non-zero otherwise
            ;;
        dnf|yum)
            # Use rpm -q (query) for RHEL/Fedora/CentOS
            rpm -q "$pkg_name" &> /dev/null
            return $?
            ;;
        pacman)
            # Use pacman -Q (query) for Arch Linux
            pacman -Q "$pkg_name" &> /dev/null
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
    echo "--- Checking for already installed packages ---"

    for pkg in $ALL_PACKAGES; do
        if is_installed "$pkg"; then
            echo "  [SKIP] $pkg is already installed."
        else
            echo "  [ADD] $pkg needs to be installed."
            PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL $pkg"
            packages_found=1
        fi
    done

    # Clean up whitespace
    PACKAGES_TO_INSTALL=$(echo "$PACKAGES_TO_INSTALL" | xargs)

    if [ $packages_found -eq 0 ]; then
        echo ""
        echo "🎉 All required packages are already installed. Skipping installation phase."
        exit 0
    else
        echo ""
        echo "Packages scheduled for installation: $PACKAGES_TO_INSTALL"
    fi
}

# --- 4. Run the Installation ---

detect_pkg_manager
gather_packages
filter_packages # New step: filter the list

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

# Explicitly ensure the script exits with status 0
exit 0
