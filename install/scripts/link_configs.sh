#!/bin/bash

# Links config folders to ~/.config and home files to $HOME

source "./paths/paths.conf"

# Color codes
RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m' NC='\033[0m'

echo -e "${BLUE}=== Config Folder Linking Script ===${NC}\n"

# Check source directories
[ ! -d "$CONFIG_SOURCE_DIR" ] && echo -e "${RED}Error: $CONFIG_SOURCE_DIR not found${NC}" && exit 1

CONFIG_SOURCE_DIR=$(readlink -f "$CONFIG_SOURCE_DIR")
WALLPAPERS_EXISTS=false
HOME_EXISTS=false

[ -d "$WALLPAPERS_SOURCE_DIR" ] && WALLPAPERS_SOURCE_DIR=$(readlink -f "$WALLPAPERS_SOURCE_DIR") && WALLPAPERS_EXISTS=true && echo -e "${GREEN}✓${NC} Found wallpapers"
[ -d "$HOME_SOURCE_DIR" ] && HOME_SOURCE_DIR=$(readlink -f "$HOME_SOURCE_DIR") && HOME_EXISTS=true && echo -e "${GREEN}✓${NC} Found home files"

mkdir -p "$CONFIG_DIR" "$PICTURES_DIR"

echo -e "${YELLOW}Linking configs and backing up conflicts...${NC}\n"

# Counters
linked=0 backed_up=0 skipped=0 removed=0

# Function to process directory
process_dir() {
  local source_dir=$1
  local prefix=$2

  for folder in "$source_dir"/*; do
    [ ! -d "$folder" ] && continue

    folder_name=$(basename "$folder")
    [[ "$folder_name" == .* ]] && ((skipped++)) && continue

    target="$CONFIG_DIR/$folder_name"

    # Already linked correctly
    if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$folder")" ]; then
      ((skipped++))
      continue
    fi

    # Backup or remove existing
    if [ -e "$target" ] || [ -L "$target" ]; then
      if [ ! -L "$target" ]; then
        mkdir -p "$BACKUP_DIR"
        mv "$target" "$BACKUP_DIR/$folder_name" && echo -e "  ${YELLOW}↻${NC} Backed up $folder_name" && ((backed_up++))
      else
        rm "$target" && echo -e "  ${RED}✗${NC} Removed old link $folder_name" && ((removed++))
      fi
    fi

    # Create link
    ln -s "$folder" "$target" && echo -e "  ${GREEN}✓${NC} Linked $folder_name" && ((linked++))
  done
}

echo -e "${BLUE}--- Processing config folders ---${NC}"
process_dir "$CONFIG_SOURCE_DIR" "config"

# Link home files
if [ "$HOME_EXISTS" = true ]; then
  echo -e "\n${BLUE}--- Processing home files ---${NC}"

  # Enable dotglob to match hidden files
  shopt -s dotglob
  shopt -s nullglob

  for item in "$HOME_SOURCE_DIR"/*; do
    item_name=$(basename "$item")

    # Skip . and .. directories
    [[ "$item_name" == "." || "$item_name" == ".." ]] && continue

    target="$HOME/$item_name"

    # Already linked correctly
    if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$item")" ]; then
      ((skipped++))
      continue
    fi

    # Backup or remove existing
    if [ -e "$target" ] || [ -L "$target" ]; then
      if [ ! -L "$target" ]; then
        mkdir -p "$HOME_BACKUP_DIR"
        mv "$target" "$HOME_BACKUP_DIR/$item_name" && echo -e "  ${YELLOW}↻${NC} Backed up $item_name" && ((backed_up++))
      else
        rm "$target" && echo -e "  ${RED}✗${NC} Removed old link $item_name" && ((removed++))
      fi
    fi

    # Create link
    ln -s "$item" "$target" && echo -e "  ${GREEN}✓${NC} Linked $item_name" && ((linked++))
  done

  # Disable dotglob after use
  shopt -u dotglob
  shopt -u nullglob
fi

# Link wallpapers
if [ "$WALLPAPERS_EXISTS" = true ]; then
  echo -e "\n${BLUE}--- Processing wallpapers ---${NC}"

  if [ -L "$WALLPAPERS_DIR" ] && [ "$(readlink -f "$WALLPAPERS_DIR")" = "$WALLPAPERS_SOURCE_DIR" ]; then
    echo -e "  ${BLUE}ℹ${NC} Already linked"
  else
    [ -e "$WALLPAPERS_DIR" ] && [ ! -L "$WALLPAPERS_DIR" ] && mkdir -p "$PICTURES_BACKUP_DIR" && mv "$WALLPAPERS_DIR" "$PICTURES_BACKUP_DIR/wallpapers"
    [ -L "$WALLPAPERS_DIR" ] && rm "$WALLPAPERS_DIR"
    ln -s "$WALLPAPERS_SOURCE_DIR" "$WALLPAPERS_DIR" && echo -e "  ${GREEN}✓${NC} Linked wallpapers"
  fi
fi

# Summary
echo -e "\n${BLUE}=== Summary ===${NC}"
echo -e "${GREEN}Linked:${NC} $linked | ${YELLOW}Backed up:${NC} $backed_up | ${RED}Removed:${NC} $removed | ${BLUE}Skipped:${NC} $skipped"
[ -d "$BACKUP_DIR" ] && echo -e "\n${YELLOW}Config Backups:${NC} $BACKUP_DIR"
[ -d "$HOME_BACKUP_DIR" ] && echo -e "${YELLOW}Home Backups:${NC} $HOME_BACKUP_DIR"
echo -e "\n${GREEN}Done!${NC}"
exit 0
