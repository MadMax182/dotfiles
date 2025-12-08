#!/bin/bash

# Converts the current git repository from HTTPS to SSH

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Git Remote HTTPS to SSH Converter ===${NC}\n"

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo -e "${RED}Error: Not a git repository${NC}"
  exit 1
fi

# Get current remote URL
current_url=$(git remote get-url origin 2>/dev/null)

if [ -z "$current_url" ]; then
  echo -e "${RED}Error: No 'origin' remote found${NC}"
  exit 1
fi

echo -e "Current remote URL: ${YELLOW}$current_url${NC}\n"

# Check if already SSH
if [[ "$current_url" =~ ^git@.*\.git$ ]]; then
  echo -e "${GREEN}✓ Already using SSH${NC}"
  exit 0
fi

# Check if it's an HTTPS GitHub URL
if [[ ! "$current_url" =~ ^https://github\.com/ ]]; then
  echo -e "${RED}Error: Not a GitHub HTTPS URL${NC}"
  echo "This script only converts GitHub HTTPS URLs to SSH"
  exit 1
fi

# Convert HTTPS to SSH
# https://github.com/user/repo.git -> git@github.com:user/repo.git
ssh_url=$(echo "$current_url" | sed 's|https://github\.com/|git@github.com:|')

echo -e "New SSH URL: ${GREEN}$ssh_url${NC}\n"

# Confirm
read -p "Convert to SSH? (Y/n): " -n 1 -r
echo
[[ $REPLY =~ ^[Nn]$ ]] && echo "Cancelled." && exit 0

# Update remote
if git remote set-url origin "$ssh_url"; then
  echo -e "\n${GREEN}✓ Successfully converted to SSH${NC}"
  echo -e "\nVerify with: ${BLUE}git remote -v${NC}"
else
  echo -e "\n${RED}✗ Failed to update remote${NC}"
  exit 1
fi

exit 0
