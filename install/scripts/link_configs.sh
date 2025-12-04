#!/bin/bash

# Script to create symbolic links from desktop/apps config folders to ~/.config
# If a folder exists in the target location, it will be backed up and replaced with the symlink

# Set working directory to script's location
cd "$(dirname "$0")"

# Set source and destination directories
DESKTOP_SOURCE_DIR="../../dot-config"  # One directory back from script location
APPS_SOURCE_DIR="../../apps"  # Apps folder
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$CONFIG_DIR/.backup_$(date +%Y%m%d_%H%M%S)"
WALLPAPERS_SOURCE="$DESKTOP_SOURCE_DIR/hypr/wallpapers"
WALLPAPERS_TARGET="$HOME/Pictures/wallpapers"
PICTURES_BACKUP_DIR="$HOME/Pictures/.backup_$(date +%Y%m%d_%H%M%S)"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Config Folder Linking Script ===${NC}"
echo ""
echo "Desktop source directory: $DESKTOP_SOURCE_DIR"
echo "Apps source directory: $APPS_SOURCE_DIR"
echo "Target directory: $CONFIG_DIR"
echo ""

# Check if desktop source directory exists
if [ ! -d "$DESKTOP_SOURCE_DIR" ]; then
    echo -e "${RED}Error: Desktop source directory $DESKTOP_SOURCE_DIR does not exist${NC}"
    echo "Current directory: $(pwd)"
    echo "Looking for: $(readlink -f "$DESKTOP_SOURCE_DIR" 2>/dev/null || echo "$DESKTOP_SOURCE_DIR")"
    exit 1
fi

# Get absolute path for desktop source directory
DESKTOP_SOURCE_DIR=$(readlink -f "$DESKTOP_SOURCE_DIR")

# Update wallpapers source path with absolute path
WALLPAPERS_SOURCE="$DESKTOP_SOURCE_DIR/hypr/wallpapers"

# Check if wallpapers directory exists
WALLPAPERS_EXISTS=false
if [ -d "$WALLPAPERS_SOURCE" ]; then
    WALLPAPERS_EXISTS=true
    echo -e "${GREEN}✓${NC} Found wallpapers directory"
else
    echo -e "${YELLOW}ℹ${NC} Wallpapers directory not found at $WALLPAPERS_SOURCE"
fi

# Check if apps source directory exists (optional - won't fail if missing)
APPS_EXISTS=false
if [ -d "$APPS_SOURCE_DIR" ]; then
    APPS_SOURCE_DIR=$(readlink -f "$APPS_SOURCE_DIR")
    APPS_EXISTS=true
    echo -e "${GREEN}✓${NC} Found apps directory"
else
    echo -e "${YELLOW}ℹ${NC} Apps directory not found, will only process desktop configs"
fi

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"
mkdir -p "$HOME/Pictures"

# Ask for confirmation
echo -e "${YELLOW}This script will:${NC}"
echo "  1. Link all folders in desktop/ to ~/.config"
if [ "$APPS_EXISTS" = true ]; then
    echo "  2. Link all folders in apps/ to ~/.config"
fi
if [ "$WALLPAPERS_EXISTS" = true ]; then
    echo "  3. Link desktop/hypr/wallpapers to ~/Pictures/wallpapers"
fi
echo "  4. Back up only conflicting folders"
echo ""
read -p "Do you want to continue? (y/n): " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 0
fi

echo ""
echo -e "${BLUE}--- Processing desktop config folders ---${NC}"

# Counter for statistics
linked_count=0
backed_up_count=0
skipped_count=0
apps_linked_count=0
apps_backed_up_count=0
apps_skipped_count=0

# Loop through all directories in the desktop source folder
for folder in "$DESKTOP_SOURCE_DIR"/*; do
    # Check if it's a directory (not a file)
    if [ ! -d "$folder" ]; then
        continue
    fi

    # Get the folder name without the path
    folder_name=$(basename "$folder")

    # Skip if folder name starts with . (hidden folders)
    if [[ "$folder_name" == .* ]]; then
        echo -e "${YELLOW}[SKIP]${NC} $folder_name (hidden folder)"
        ((skipped_count++))
        continue
    fi

    # Target path in .config
    target_path="$CONFIG_DIR/$folder_name"

    echo ""
    echo -e "Processing: ${GREEN}$folder_name${NC}"

    # Check if target already exists
    if [ -e "$target_path" ]; then
        # Check if it's already a symlink pointing to the correct location
        if [ -L "$target_path" ] && [ "$(readlink -f "$target_path")" = "$(readlink -f "$folder")" ]; then
            echo -e "  ${BLUE}[INFO]${NC} Already linked correctly, skipping"
            ((skipped_count++))
            continue
        fi

        # Back up only this specific folder
        echo -e "  ${YELLOW}[BACKUP]${NC} Existing $folder_name found, creating backup..."

        # Create backup directory only when needed (first backup)
        if [ ! -d "$BACKUP_DIR" ]; then
            mkdir -p "$BACKUP_DIR" || {
                echo -e "  ${RED}[ERROR]${NC} Failed to create backup directory"
                continue
            }
        fi

        mv "$target_path" "$BACKUP_DIR/$folder_name" || {
            echo -e "  ${RED}[ERROR]${NC} Failed to backup $folder_name"
            continue
        }
        echo -e "  ${GREEN}✓${NC} Backed up to $BACKUP_DIR/$folder_name"
        ((backed_up_count++))
    fi

    # Create symbolic link
    ln -s "$folder" "$target_path" || {
        echo -e "  ${RED}[ERROR]${NC} Failed to create symlink for $folder_name"
        continue
    }

    echo -e "  ${GREEN}✓${NC} Linked $folder_name -> $target_path"
    ((linked_count++))
done

# --- Process apps folder ---
if [ "$APPS_EXISTS" = true ]; then
    echo ""
    echo -e "${BLUE}--- Processing apps folders ---${NC}"

    # Loop through all directories in the apps folder
    for folder in "$APPS_SOURCE_DIR"/*; do
        # Check if it's a directory (not a file)
        if [ ! -d "$folder" ]; then
            continue
        fi

        # Get the folder name without the path
        folder_name=$(basename "$folder")

        # Skip if folder name starts with . (hidden folders)
        if [[ "$folder_name" == .* ]]; then
            echo -e "${YELLOW}[SKIP]${NC} $folder_name (hidden folder)"
            ((apps_skipped_count++))
            continue
        fi

        # Target path in config directory
        target_path="$CONFIG_DIR/$folder_name"

        echo ""
        echo -e "Processing: ${GREEN}$folder_name${NC}"

        # Check if target already exists
        if [ -e "$target_path" ]; then
            # Check if it's already a symlink pointing to the correct location
            if [ -L "$target_path" ] && [ "$(readlink -f "$target_path")" = "$(readlink -f "$folder")" ]; then
                echo -e "  ${BLUE}[INFO]${NC} Already linked correctly, skipping"
                ((apps_skipped_count++))
                continue
            fi

            # Back up only this specific folder
            echo -e "  ${YELLOW}[BACKUP]${NC} Existing $folder_name found, creating backup..."

            # Create backup directory only when needed (first backup)
            if [ ! -d "$BACKUP_DIR" ]; then
                mkdir -p "$BACKUP_DIR" || {
                    echo -e "  ${RED}[ERROR]${NC} Failed to create backup directory"
                    continue
                }
            fi

            mv "$target_path" "$BACKUP_DIR/$folder_name" || {
                echo -e "  ${RED}[ERROR]${NC} Failed to backup $folder_name"
                continue
            }
            echo -e "  ${GREEN}✓${NC} Backed up to $BACKUP_DIR/$folder_name"
            ((apps_backed_up_count++))
        fi

        # Create symbolic link
        ln -s "$folder" "$target_path" || {
            echo -e "  ${RED}[ERROR]${NC} Failed to create symlink for $folder_name"
            continue
        }

        echo -e "  ${GREEN}✓${NC} Linked $folder_name -> $target_path"
        ((apps_linked_count++))
    done
fi

# --- Process wallpapers folder ---
if [ "$WALLPAPERS_EXISTS" = true ]; then
    echo ""
    echo -e "${BLUE}--- Processing wallpapers folder ---${NC}"

    echo ""
    echo -e "Processing: ${GREEN}wallpapers${NC}"

    # Check if target already exists
    if [ -e "$WALLPAPERS_TARGET" ]; then
        # Check if it's already a symlink pointing to the correct location
        if [ -L "$WALLPAPERS_TARGET" ] && [ "$(readlink -f "$WALLPAPERS_TARGET")" = "$(readlink -f "$WALLPAPERS_SOURCE")" ]; then
            echo -e "  ${BLUE}[INFO]${NC} Wallpapers already linked correctly, skipping"
        else
            # Back up existing wallpapers folder
            echo -e "  ${YELLOW}[BACKUP]${NC} Existing wallpapers folder found, creating backup..."

            # Create backup directory only when needed
            if [ ! -d "$PICTURES_BACKUP_DIR" ]; then
                mkdir -p "$PICTURES_BACKUP_DIR" || {
                    echo -e "  ${RED}[ERROR]${NC} Failed to create backup directory"
                }
            fi

            if [ -d "$PICTURES_BACKUP_DIR" ]; then
                mv "$WALLPAPERS_TARGET" "$PICTURES_BACKUP_DIR/wallpapers" || {
                    echo -e "  ${RED}[ERROR]${NC} Failed to backup wallpapers"
                }

                if [ ! -e "$WALLPAPERS_TARGET" ]; then
                    echo -e "  ${GREEN}✓${NC} Backed up to $PICTURES_BACKUP_DIR/wallpapers"

                    # Create symbolic link
                    ln -s "$WALLPAPERS_SOURCE" "$WALLPAPERS_TARGET" && {
                        echo -e "  ${GREEN}✓${NC} Linked wallpapers -> $WALLPAPERS_TARGET"
                    } || {
                        echo -e "  ${RED}[ERROR]${NC} Failed to create symlink for wallpapers"
                    }
                fi
            fi
        fi
    else
        # Create symbolic link (no backup needed)
        ln -s "$WALLPAPERS_SOURCE" "$WALLPAPERS_TARGET" && {
            echo -e "  ${GREEN}✓${NC} Linked wallpapers -> $WALLPAPERS_TARGET"
        } || {
            echo -e "  ${RED}[ERROR]${NC} Failed to create symlink for wallpapers"
        }
    fi
fi

# Print summary
echo ""
echo -e "${BLUE}=== Summary ===${NC}"
echo ""
echo -e "${BLUE}Desktop configs:${NC}"
echo -e "${GREEN}  Linked:${NC} $linked_count folders"
echo -e "${YELLOW}  Backed up:${NC} $backed_up_count folders"
echo -e "${BLUE}  Skipped:${NC} $skipped_count folders"

if [ "$APPS_EXISTS" = true ]; then
    echo ""
    echo -e "${BLUE}Apps folders:${NC}"
    echo -e "${GREEN}  Linked:${NC} $apps_linked_count folders"
    echo -e "${YELLOW}  Backed up:${NC} $apps_backed_up_count folders"
    echo -e "${BLUE}  Skipped:${NC} $apps_skipped_count folders"
fi

total_backed_up=$((backed_up_count + apps_backed_up_count))

if [ $total_backed_up -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Backup location:${NC} $BACKUP_DIR"
    echo "You can restore backups or delete them once you've verified everything works."
fi

echo ""
echo -e "${GREEN}Done!${NC}"
