#!/bin/bash

# Script to create symbolic links from desktop config folders to ~/.config
# If a folder exists in ~/.config, it will be backed up and replaced with the symlink

# Set working directory to script's location
cd "$(dirname "$0")"

# Set source and destination directories
SOURCE_DIR="../desktop"  # One directory back from script location
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$CONFIG_DIR/.backup_$(date +%Y%m%d_%H%M%S)"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Config Folder Linking Script ===${NC}"
echo ""
echo "Source directory: $SOURCE_DIR"
echo "Target directory: $CONFIG_DIR"
echo ""

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}Error: Source directory $SOURCE_DIR does not exist${NC}"
    echo "Current directory: $(pwd)"
    echo "Looking for: $(readlink -f "$SOURCE_DIR" 2>/dev/null || echo "$SOURCE_DIR")"
    exit 1
fi

# Get absolute path for source directory
SOURCE_DIR=$(readlink -f "$SOURCE_DIR")

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Ask for confirmation
echo -e "${YELLOW}This script will:${NC}"
echo "  1. Find all folders in $SOURCE_DIR"
echo "  2. Back up only conflicting folders to $CONFIG_DIR/.backup_[timestamp]"
echo "  3. Create symbolic links from $SOURCE_DIR to ~/.config"
echo ""
read -p "Do you want to continue? (y/n): " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 0
fi

echo ""
echo -e "${BLUE}--- Processing folders ---${NC}"

# Counter for statistics
linked_count=0
backed_up_count=0
skipped_count=0

# Loop through all directories in the source folder
for folder in "$SOURCE_DIR"/*; do
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

# Print summary
echo ""
echo -e "${BLUE}=== Summary ===${NC}"
echo -e "${GREEN}Linked:${NC} $linked_count folders"
echo -e "${YELLOW}Backed up:${NC} $backed_up_count folders"
echo -e "${BLUE}Skipped:${NC} $skipped_count folders"

if [ $backed_up_count -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Backup location:${NC} $BACKUP_DIR"
    echo "You can restore backups or delete them once you've verified everything works."
fi

echo ""
echo -e "${GREEN}Done!${NC}"
