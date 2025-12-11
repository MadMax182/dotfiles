#!/bin/bash

# Links theme directories to config folders as 'themes'
# Example: ./themes/waybar -> ./config/waybar/themes

# Source paths configuration with absolute path
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.userconfig}"
source "$DOTFILES_DIR/paths/paths.conf"

# Colors
RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m' NC='\033[0m'

echo -e "${BLUE}=== Theme Linking Script ===${NC}\n"

# Validate directories
[ ! -d "$THEMES_SOURCE_DIR" ] && echo -e "${RED}Error: $THEMES_SOURCE_DIR not found${NC}" && exit 1
[ ! -d "$CONFIG_SOURCE_DIR" ] && echo -e "${RED}Error: $CONFIG_SOURCE_DIR not found${NC}" && exit 1

THEMES_SOURCE_DIR=$(readlink -f "$THEMES_SOURCE_DIR")
CONFIG_SOURCE_DIR=$(readlink -f "$CONFIG_SOURCE_DIR")

echo "Themes: $THEMES_SOURCE_DIR → Config: $CONFIG_SOURCE_DIR"
echo

# Get theme directories
mapfile -t theme_dirs < <(find "$THEMES_SOURCE_DIR" -maxdepth 1 -type d ! -path "$THEMES_SOURCE_DIR")

[ ${#theme_dirs[@]} -eq 0 ] && echo "No theme directories found" && exit 0

echo "Found ${#theme_dirs[@]} theme(s):"
printf "  - %s\n" "${theme_dirs[@]##*/}"
echo

# Counters
linked=0 skipped=0 backed_up=0 removed=0

# Process themes
for theme_dir in "${theme_dirs[@]}"; do
  theme_name="${theme_dir##*/}"
  target_config="$CONFIG_SOURCE_DIR/$theme_name"
  target_link="$target_config/themes"

  echo -e "Processing: ${GREEN}$theme_name${NC}"

  # Check config exists
  if [ ! -d "$target_config" ]; then
    echo -e "  ${YELLOW}⚠${NC} No config directory, skipping"
    ((skipped++))
    continue
  fi

  # Already linked correctly
  [ -L "$target_link" ] && [ "$(readlink -f "$target_link")" = "$theme_dir" ] && \
    echo -e "  ${BLUE}ℹ${NC} Already linked" && ((skipped++)) && continue

  # Handle existing
  if [ -e "$target_link" ] || [ -L "$target_link" ]; then
    if [ ! -L "$target_link" ]; then
      mv "$target_link" "$target_config/themes.backup_$(date +%Y%m%d_%H%M%S)" && \
        echo -e "  ${YELLOW}↻${NC} Backed up" && ((backed_up++))
    else
      rm "$target_link" && echo -e "  ${RED}✗${NC} Removed old link" && ((removed++))
    fi
  fi

  # Create link
  ln -s "$theme_dir" "$target_link" && \
    echo -e "  ${GREEN}✓${NC} Linked" && ((linked++)) || \
    echo -e "  ${RED}✗${NC} Failed"

  echo
done

# Summary
echo -e "${BLUE}=== Summary ===${NC}"
echo -e "${GREEN}Linked:${NC} $linked | ${YELLOW}Backed up:${NC} $backed_up | ${RED}Removed:${NC} $removed | ${BLUE}Skipped:${NC} $skipped"
echo -e "\n${GREEN}Done!${NC}"

exit 0
