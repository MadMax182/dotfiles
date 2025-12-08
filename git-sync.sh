#!/bin/bash

# Automated Git Sync Script
# Usage: ./git-sync.sh [commit message]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting git sync...${NC}"

# Pull latest changes
echo -e "${YELLOW}Pulling latest changes...${NC}"
git pull

# Stage all changes
echo -e "${YELLOW}Staging all changes...${NC}"
git add .

# Check if there are any changes to commit
if git diff --staged --quiet; then
    echo -e "${GREEN}No changes to commit. Repository is up to date.${NC}"
    exit 0
fi

# Get commit message from argument or use default
COMMIT_MSG="${1:-update}"

# Commit changes
echo -e "${YELLOW}Committing changes...${NC}"
git commit -m "$COMMIT_MSG"

# Push to remote
echo -e "${YELLOW}Pushing to remote...${NC}"
git push

echo -e "${GREEN}✓ Git sync completed successfully!${NC}"
