#!/bin/bash

# Generates package list section in README.md from dependency files

# Get script directory and change to it
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || { echo "Error: Failed to change to script directory"; exit 1; }

# Source paths configuration with absolute path
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.userconfig}"
source "$DOTFILES_DIR/paths/paths.conf"

README_FILE="README.md"
TEMP_FILE="${README_FILE}.tmp"
INIT_SCRIPT="init.sh"

[ ! -f "$README_FILE" ] && echo "Error: README.md not found" && exit 1

# Extract GitHub URL from init.sh
REPO_URL=""
if [ -f "$INIT_SCRIPT" ]; then
  REPO_URL=$(grep '^REPO_URL=' "$INIT_SCRIPT" | sed 's/REPO_URL="\(.*\)"/\1/')
fi

# Extract username and repo name from URL
if [ -n "$REPO_URL" ]; then
  # Extract from https://github.com/username/repo.git
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
    # Remove comments for clean display
    clean_line=$(echo "$line" | sed 's/#.*//;s/^[[:space:]]*//;s/[[:space:]]*$//')

    # Skip empty lines
    [ -z "$clean_line" ] && continue

    # Extract comment for description
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
    # Skip comment-only lines and empty lines
    clean_line=$(echo "$line" | sed 's/#.*//;s/^[[:space:]]*//;s/[[:space:]]*$//')
    [ -z "$clean_line" ] && continue

    # Extract comment
    comment=$(echo "$line" | grep -o '#.*' | sed 's/^#[[:space:]]*//')

    # Check if flatpak
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

# Ensure final newline
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
    # Replace GitHub URLs - both placeholders and existing URLs
    gsub(/https:\/\/raw\.githubusercontent\.com\/[^\/]+\/[^\/]+\/main\/init\.sh/, "https://raw.githubusercontent.com/" gh_user "/" gh_repo "/main/init.sh")
    gsub(/https:\/\/github\.com\/[^\/]+\/[^\/]+\.git/, "https://github.com/" gh_user "/" gh_repo ".git")
    gsub(/YOUR_USERNAME\/YOUR_REPO/, gh_user "/" gh_repo)
    gsub(/YOUR_USERNAME/, gh_user)
    gsub(/YOUR_REPO/, gh_repo)
    print
  }
' "$README_FILE" > "$TEMP_FILE"

# Clean up
rm -f "$CONTENT_FILE"

# Replace original
mv "$TEMP_FILE" "$README_FILE"

echo "✓ README.md updated with package lists"
[ -n "$REPO_URL" ] && echo "✓ GitHub URLs updated: $GITHUB_USER/$GITHUB_REPO"
exit 0
