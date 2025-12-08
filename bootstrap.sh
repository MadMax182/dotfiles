#!/bin/bash

# Bootstrap script - Clones repository and runs installation

set -e

# Colors
B='\033[0;34m' G='\033[0;32m' Y='\033[1;33m' R='\033[0;31m' N='\033[0m'

# Configuration
REPO_URL="https://github.com/YOUR_USERNAME/YOUR_REPO.git" # Change this!
INSTALL_DIR="$HOME/.userconfig"

echo -e "${B}=== Dotfiles Bootstrap ===${N}\n"

# Check and install git if needed
if ! command -v git &>/dev/null; then
  echo -e "${Y}Git not found, installing...${N}"
  sudo pacman -Sy --noconfirm git || {
    echo -e "${R}Error: Failed to install git${N}"
    exit 1
  }
  echo -e "${G}✓ Git installed${N}\n"
fi

# Clone or update repository
if [ -d "$INSTALL_DIR/.git" ]; then
  echo -e "${Y}Repository exists, updating...${N}"
  cd "$INSTALL_DIR"
  git pull || echo -e "${Y}Warning: Failed to update${N}"
else
  echo -e "${G}Cloning repository to $INSTALL_DIR...${N}"
  git clone "$REPO_URL" "$INSTALL_DIR" || {
    echo -e "${R}Error: Failed to clone repository${N}"
    exit 1
  }
  cd "$INSTALL_DIR"
fi

echo -e "${G}✓ Repository ready${N}\n"

# Run main installer
if [ -f "./install/install.sh" ]; then
  echo -e "${B}Starting installation...${N}\n"
  bash ./install/install.sh
else
  echo -e "${R}Error: install.sh not found${N}"
  exit 1
fi

echo -e "\n${G}=== Bootstrap Complete! ===${N}"
exit 0
