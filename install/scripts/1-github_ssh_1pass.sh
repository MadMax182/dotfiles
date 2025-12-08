#!/bin/bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Constants
SSH_SOCK="$HOME/.1password/agent.sock"
SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"
KITTY_CONFIG="$HOME/.config/kitty/kitty.conf"

# Helper functions
error() {
  echo -e "${RED}Error: $1${NC}" >&2
  exit 1
}
success() { echo -e "${GREEN}✓ $1${NC}"; }
info() { echo -e "${YELLOW}$1${NC}"; }

check_dependency() {
  command -v "$1" &>/dev/null || error "$1 not found. Install with: $2"
}

# Check dependencies
check_dependency "op" "yay -S 1password-cli"
check_dependency "jq" "sudo pacman -S jq"

echo -e "${GREEN}GitHub SSH Setup with 1Password${NC}\n"

# Ensure 1Password is running
if ! pgrep -x "1password" >/dev/null; then
  info "Starting 1Password..."
  1password &
  disown
  sleep 2
fi

# Sign in to 1Password CLI if needed
if ! op account list &>/dev/null; then
  info "Signing in to 1Password CLI..."
  eval $(op signin) || error "Failed to sign in to 1Password"
fi

# Set SSH agent socket
export SSH_AUTH_SOCK="$SSH_SOCK"
[ -S "$SSH_SOCK" ] || error "1Password SSH agent not found. Enable it in Settings → Developer → 'Use the SSH agent'"

# List and select SSH key
info "Searching for SSH keys in 1Password..."
KEYS_JSON=$(op item list --categories "SSH Key" --format json 2>/dev/null)
[ -n "$KEYS_JSON" ] && [ "$KEYS_JSON" != "[]" ] || error "No SSH keys found in 1Password"

readarray -t KEY_NAMES < <(jq -r '.[].title' <<<"$KEYS_JSON")
[ ${#KEY_NAMES[@]} -gt 0 ] || error "No SSH keys found"

echo -e "${GREEN}Available SSH keys:${NC}"
printf '%s\n' "${KEY_NAMES[@]}" | nl -w2 -s'. '

read -rp $'\nSelect SSH key number (1-'"${#KEY_NAMES[@]}"'): ' selection
[[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#KEY_NAMES[@]} ] || error "Invalid selection"

SELECTED_NAME="${KEY_NAMES[$((selection - 1))]}"
success "Selected: $SELECTED_NAME"

# Retrieve public key
info "Retrieving public key..."
readarray -t ALL_KEYS < <(ssh-add -L 2>/dev/null)
[ ${#ALL_KEYS[@]} -ge "$selection" ] || error "Could not retrieve public key. Ensure SSH agent is enabled in 1Password."
PUBLIC_KEY="${ALL_KEYS[$((selection - 1))]}"

# Configure SSH
info "Configuring SSH..."
mkdir -p "$SSH_DIR" && chmod 700 "$SSH_DIR"

if [ -f "$SSH_CONFIG" ]; then
  [ -f "$SSH_CONFIG.backup" ] || cp "$SSH_CONFIG" "$SSH_CONFIG.backup"
fi

if grep -q "^Host github\.com$" "$SSH_CONFIG" 2>/dev/null; then
  info "GitHub SSH config already exists"
else
  cat >>"$SSH_CONFIG" <<EOF

Host github.com
    HostName github.com
    User git
    IdentityAgent $SSH_SOCK
EOF
  chmod 600 "$SSH_CONFIG"
  success "SSH config created"
fi

# Configure shell
info "Configuring shell environment..."
case "$(basename "$SHELL")" in
bash)
  RC="$HOME/.bashrc"
  LINE="export SSH_AUTH_SOCK=$SSH_SOCK"
  ;;
zsh)
  RC="$HOME/.zshrc"
  LINE="export SSH_AUTH_SOCK=$SSH_SOCK"
  ;;
fish)
  RC="$HOME/.config/fish/config.fish"
  LINE="set -x SSH_AUTH_SOCK $SSH_SOCK"
  ;;
*)
  RC=""
  info "Unknown shell: $(basename "$SHELL")"
  ;;
esac

if [ -n "$RC" ]; then
  if ! grep -qF "SSH_AUTH_SOCK" "$RC" 2>/dev/null; then
    echo "$LINE" >>"$RC"
    success "Added SSH_AUTH_SOCK to $RC"
  else
    info "SSH_AUTH_SOCK already in $RC"
  fi
fi

# Configure Kitty
info "Configuring Kitty terminal..."
mkdir -p "$(dirname "$KITTY_CONFIG")"

if ! grep -qF "SSH_AUTH_SOCK" "$KITTY_CONFIG" 2>/dev/null; then
  echo "env SSH_AUTH_SOCK=$SSH_SOCK" >>"$KITTY_CONFIG"
  success "Kitty config updated"
else
  info "Kitty already configured"
fi

# Display and copy public key
echo -e "\n${GREEN}Public Key:${NC}"
echo "$PUBLIC_KEY"

if command -v xclip &>/dev/null; then
  echo "$PUBLIC_KEY" | xclip -selection clipboard
  success "Copied to clipboard (xclip)"
elif command -v wl-copy &>/dev/null; then
  echo "$PUBLIC_KEY" | wl-copy
  success "Copied to clipboard (wl-copy)"
else
  info "Install xclip or wl-clipboard for auto-copy"
fi

# Test GitHub connection
echo ""
info "Testing GitHub connection..."
if SSH_OUTPUT=$(ssh -T git@github.com 2>&1); then
  : # Successful connection will exit with code 1 but still work
fi

if echo "$SSH_OUTPUT" | grep -q "successfully authenticated"; then
  GH_USER=$(echo "$SSH_OUTPUT" | grep -oP 'Hi \K[^!]+')
  success "Authenticated as: $GH_USER"
else
  info "Not authenticated yet"
  echo -e "\n${YELLOW}Next steps:${NC}"
  echo "1. Go to https://github.com/settings/keys"
  echo "2. Click 'New SSH key'"
  echo "3. Paste the public key above"
  echo "4. Test with: ssh -T git@github.com"
fi

echo -e "\n${GREEN}Setup complete!${NC}"
info "Restart Kitty for changes to take effect"
