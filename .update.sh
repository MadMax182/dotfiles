#!/bin/bash

# --- Automated Git Push Script (Robust Version) ---

# This script performs git add, git commit, and git push for the current directory.
# It automatically generates a commit message with the current date and time.
# Uses explicit branch pushing for higher reliability and forces execution from the project root.

# Define the commit message using the current date and time
COMMIT_MESSAGE="Automated push from script: $(date +'%Y-%m-%d %H:%M:%S')"

echo "--- Starting Git Automation ---"

# 1. Find the project root and change directory to it
# This ensures all subsequent git commands run from the top-level repository folder.
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

if [ -z "$PROJECT_ROOT" ]; then
  echo "Error: Not a Git repository. Please run this script inside a git project."
  exit 1
fi

# Temporarily change to the project root directory
cd "$PROJECT_ROOT" || {
  echo "Error: Failed to change directory to project root."
  exit 1
}

echo "Successfully moved to project root: $PROJECT_ROOT"

# Get the current branch name
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" == "HEAD" ]; then
  echo "Error: Detached HEAD state. Cannot determine current branch for push."
  exit 1
fi
echo "Current Branch Detected: $CURRENT_BRANCH"

# 2. Stage all changes in the current directory
echo "1. Staging all changes (git add .)..."
git add .

# Check if there are any changes to commit (staged or unstaged)
if git diff-index --quiet HEAD --; then
  echo "Info: No changes detected to commit. Skipping commit and push."
  exit 0
fi

# 3. Commit the changes
echo "2. Committing changes with message: \"$COMMIT_MESSAGE\""
if git commit -m "$COMMIT_MESSAGE"; then
  echo "Commit successful."
else
  # This might happen if there are no staged changes, but we checked above.
  echo "Error: Git commit failed. Aborting push."
  exit 1
fi

# 4. Push the changes to the remote explicitly
echo "3. Pushing changes to remote 'origin' on branch '$CURRENT_BRANCH'..."
if git push origin "$CURRENT_BRANCH"; then
  echo "-----------------------------------"
  echo "Success: Changes pushed successfully via $CURRENT_BRANCH!"
  echo "-----------------------------------"
else
  echo "--- PUSH FAILED ---"
  echo "The push failed. This is often due to one of three reasons:"
  echo "1. AUTHENTICATION: Your SSH key is not loaded (run 'ssh-add -l' to check)."
  echo "2. DIVERGENCE: Remote repository has new commits (You must run 'git pull' manually and resolve conflicts before running this script again)."
  echo "3. BRANCH TRACKING: The remote branch is not set up."
  echo "-------------------"
  exit 1
fi

echo "--- Git Automation Finished ---"
