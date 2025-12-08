#!/bin/bash

# Automated Git Sync Script with README generation
# Usage: ./git-sync.sh [commit message]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Repository directory
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.userconfig}"

echo -e "${YELLOW}Starting git sync...${NC}"

# Pull latest changes
echo -e "${YELLOW}Pulling latest changes...${NC}"
git pull

# Update README.md with package lists
echo -e "${BLUE}Updating README.md...${NC}"

# Source paths configuration
source "$DOTFILES_DIR/paths/paths.conf"

README_FILE="$DOTFILES_DIR/README.md"
TEMP_FILE="${README_FILE}.tmp"
INIT_SCRIPT="$DOTFILES_DIR/init.sh"

if [ -f "$README_FILE" ]; then
  # Extract GitHub URL from init.sh
  REPO_URL=""
  if [ -f "$INIT_SCRIPT" ]; then
    REPO_URL=$(grep '^REPO_URL=' "$INIT_SCRIPT" | sed 's/REPO_URL="\(.*\)"/\1/')
  fi

  # Extract username and repo name from URL
  if [ -n "$REPO_URL" ]; then
    GITHUB_PATH=$(echo "$REPO_URL" | sed 's|https://github.com/||;s|\.git$||')
    GITHUB_USER=$(echo "$GITHUB_PATH" | cut -d'/' -f1)
    GITHUB_REPO=$(echo "$GITHUB_PATH" | cut -d'/' -f2)
  else
    GITHUB_USER="YOUR_USERNAME"
    GITHUB_REPO="YOUR_REPO"
  fi

  # Function to parse list files
  parse_list() {
    local file=$1
    local output=""

    while IFS= read -r line; do
      clean_line=$(echo "$line" | sed 's/#.*//;s/^[[:space:]]*//;s/[[:space:]]*$//')
      [ -z "$clean_line" ] && continue

      comment=$(echo "$line" | grep -o '#.*' | sed 's/^#[[:space:]]*//')

      if [ -n "$comment" ]; then
        output+="- **$clean_line** - $comment"$'\n'
      else
        output+="- $clean_line"$'\n'
      fi
    done < "$file"

    printf "%s" "$output"
  }

  # Function to parse apps list (with flatpak support)
  parse_apps_list() {
    local file=$1
    local regular_apps=""
    local flatpak_apps=""

    while IFS= read -r line; do
      clean_line=$(echo "$line" | sed 's/#.*//;s/^[[:space:]]*//;s/[[:space:]]*$//')
      [ -z "$clean_line" ] && continue

      comment=$(echo "$line" | grep -o '#.*' | sed 's/^#[[:space:]]*//')

      if [[ "$clean_line" =~ ^flatpak: ]]; then
        app_name="${clean_line#flatpak:}"
        app_name=$(echo "$app_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [ -n "$comment" ]; then
          flatpak_apps+="- **$app_name** (flatpak) - $comment"$'\n'
        else
          flatpak_apps+="- $app_name (flatpak)"$'\n'
        fi
      else
        if [ -n "$comment" ]; then
          regular_apps+="- **$clean_line** - $comment"$'\n'
        else
          regular_apps+="- $clean_line"$'\n'
        fi
      fi
    done < "$file"

    printf "%s" "${regular_apps}${flatpak_apps}"
  }

  # Generate new content
  NEW_CONTENT="### Dependencies"$'\n\n'
  if [ -f "$DEPENDENCY_DIR/$DEPENDENCY_FILE" ]; then
    NEW_CONTENT+=$(parse_list "$DEPENDENCY_DIR/$DEPENDENCY_FILE")
  else
    NEW_CONTENT+="*No dependencies listed*"$'\n'
  fi

  NEW_CONTENT+=$'\n'"### Applications"$'\n\n'
  if [ -f "$DEPENDENCY_DIR/$APP_FILE" ]; then
    NEW_CONTENT+=$(parse_apps_list "$DEPENDENCY_DIR/$APP_FILE")
  else
    NEW_CONTENT+="*No applications listed*"$'\n'
  fi

  NEW_CONTENT+=$'\n'"### Fonts"$'\n\n'
  if [ -f "$DEPENDENCY_DIR/$FONT_FILE" ]; then
    NEW_CONTENT+=$(parse_list "$DEPENDENCY_DIR/$FONT_FILE")
  else
    NEW_CONTENT+="*No fonts listed*"$'\n'
  fi

  [[ "$NEW_CONTENT" != *$'\n' ]] && NEW_CONTENT+=$'\n'

  # Write new content to temp file
  CONTENT_FILE="${TEMP_FILE}.content"
  printf "%s" "$NEW_CONTENT" > "$CONTENT_FILE"

  # Replace content between markers and GitHub URLs
  awk -v content_file="$CONTENT_FILE" -v gh_user="$GITHUB_USER" -v gh_repo="$GITHUB_REPO" '
    /<!-- PACKAGE_LIST_START -->/ {
      print
      while ((getline line < content_file) > 0) {
        print line
      }
      close(content_file)
      skip=1
      next
    }
    /<!-- PACKAGE_LIST_END -->/ {
      skip=0
    }
    !skip {
      gsub(/https:\/\/raw\.githubusercontent\.com\/[^\/]+\/[^\/]+\/main\/init\.sh/, "https://raw.githubusercontent.com/" gh_user "/" gh_repo "/main/init.sh")
      gsub(/https:\/\/github\.com\/[^\/]+\/[^\/]+\.git/, "https://github.com/" gh_user "/" gh_repo ".git")
      gsub(/YOUR_USERNAME\/YOUR_REPO/, gh_user "/" gh_repo)
      gsub(/YOUR_USERNAME/, gh_user)
      gsub(/YOUR_REPO/, gh_repo)
      print
    }
  ' "$README_FILE" > "$TEMP_FILE"

  # Clean up and replace original
  rm -f "$CONTENT_FILE"
  mv "$TEMP_FILE" "$README_FILE"

  echo -e "${GREEN}✓ README.md updated${NC}"
else
  echo -e "${YELLOW}⚠ README.md not found, skipping update${NC}"
fi

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
