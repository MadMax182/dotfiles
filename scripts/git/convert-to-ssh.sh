#!/bin/bash

# Convert git remote from HTTPS to SSH

REMOTE="${1:-origin}"

# Get current remote URL
CURRENT_URL=$(git remote get-url "$REMOTE" 2>/dev/null)

if [ -z "$CURRENT_URL" ]; then
    echo "Error: Remote '$REMOTE' not found"
    exit 1
fi

# Check if already using SSH
if [[ "$CURRENT_URL" == git@* ]]; then
    echo "Remote '$REMOTE' is already using SSH: $CURRENT_URL"
    exit 0
fi

# Convert HTTPS to SSH
# https://github.com/user/repo.git -> git@github.com:user/repo.git
if [[ "$CURRENT_URL" =~ ^https://([^/]+)/(.+)$ ]]; then
    HOST="${BASH_REMATCH[1]}"
    PATH_PART="${BASH_REMATCH[2]}"
    SSH_URL="git@${HOST}:${PATH_PART}"

    echo "Converting remote '$REMOTE':"
    echo "  From: $CURRENT_URL"
    echo "  To:   $SSH_URL"

    git remote set-url "$REMOTE" "$SSH_URL"
    echo "Done!"
else
    echo "Error: Unrecognized URL format: $CURRENT_URL"
    exit 1
fi
