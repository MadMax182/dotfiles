#!/bin/bash

PROXY_HOST="192.168.49.1"
PROXY_PORT="8282"
PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"

# Pacman config backup
PACMAN_CONF="/etc/pacman.conf"
PACMAN_BACKUP="/etc/pacman.conf.noproxy"

# Auto-detect shell config file
if [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
else
    case "$SHELL" in
        */zsh) SHELL_CONFIG="$HOME/.zshrc" ;;
        */bash) SHELL_CONFIG="$HOME/.bashrc" ;;
        *) SHELL_CONFIG="$HOME/.bashrc" ;;
    esac
fi

setup_pacman_proxy() {
    # Backup original if not already backed up
    if [ ! -f "$PACMAN_BACKUP" ]; then
        sudo cp "$PACMAN_CONF" "$PACMAN_BACKUP"
    fi
    
    # Check if XferCommand already exists
    if grep -q "^XferCommand" "$PACMAN_CONF"; then
        # Replace existing XferCommand with fallback
        sudo sed -i "s|^XferCommand.*|XferCommand = /usr/bin/curl --proxy http://192.168.49.1:8282 -C - -f -o %o %u \|\| /usr/bin/curl -C - -f -o %o %u|" "$PACMAN_CONF"
    else
        # Add XferCommand with fallback after [options] section
        sudo sed -i '/^\[options\]/a XferCommand = /usr/bin/curl --proxy http://192.168.49.1:8282 -C - -f -o %o %u || /usr/bin/curl -C - -f -o %o %u' "$PACMAN_CONF"
    fi
    
    echo "  ✓ Pacman/yay configured for proxy (with direct fallback)"
}

remove_pacman_proxy() {
    if [ -f "$PACMAN_BACKUP" ]; then
        sudo cp "$PACMAN_BACKUP" "$PACMAN_CONF"
        echo "  ✓ Pacman/yay proxy removed (restored from backup)"
    else
        # Just comment out XferCommand
        sudo sed -i 's|^XferCommand|#XferCommand|' "$PACMAN_CONF"
        echo "  ✓ Pacman/yay proxy disabled"
    fi
}

launch_steam() {
    export http_proxy="http://192.168.49.1:8282"
    export https_proxy="http://192.168.49.1:8282"
    export HTTP_PROXY="$http_proxy"
    export HTTPS_PROXY="$https_proxy"
    export no_proxy="localhost,127.0.0.1,::1"
    export NO_PROXY="$no_proxy"
    
    echo "Launching Steam with proxy: $http_proxy"
    steam "$@"
}

set_proxy() {
    echo "Setting up proxy environment variables..."
    echo "Using config file: $SHELL_CONFIG"
    
    # Check if already added
    if grep -q "# Proxy settings (added by proxy-toggle.sh)" "$SHELL_CONFIG" 2>/dev/null; then
        echo "⚠ Proxy settings already exist in $SHELL_CONFIG"
        echo "  (Skipping shell config, but will update pacman)"
    else
        # Add to shell config
        cat >> "$SHELL_CONFIG" << EOL

# Proxy settings (added by proxy-toggle.sh)
export http_proxy="http://192.168.49.1:8282"
export https_proxy="http://192.168.49.1:8282"
export ftp_proxy="http://192.168.49.1:8282"
export no_proxy="localhost,127.0.0.1,::1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12"
export HTTP_PROXY="\$http_proxy"
export HTTPS_PROXY="\$https_proxy"
export FTP_PROXY="\$ftp_proxy"
export NO_PROXY="\$no_proxy"
EOL
        echo "  ✓ Added to $SHELL_CONFIG"
    fi

    # Set for current session
    export http_proxy="http://192.168.49.1:8282"
    export https_proxy="http://192.168.49.1:8282"
    export ftp_proxy="http://192.168.49.1:8282"
    export no_proxy="localhost,127.0.0.1,::1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12"
    export HTTP_PROXY="$http_proxy"
    export HTTPS_PROXY="$https_proxy"
    export FTP_PROXY="$ftp_proxy"
    export NO_PROXY="$no_proxy"
    
    # Setup pacman/yay
    setup_pacman_proxy
    
    echo ""
    echo "✓ Proxy enabled: http://192.168.49.1:8282"
    echo "✓ Applied to current session"
    echo ""
    echo "  Launch Steam with proxy: $0 steam"
    echo "  Open new terminals for automatic proxy, or run:"
    echo "  source $SHELL_CONFIG"
}

remove_proxy() {
    echo "Removing proxy environment variables..."
    echo "Using config file: $SHELL_CONFIG"
    
    # Remove from shell config
    if grep -q "# Proxy settings (added by proxy-toggle.sh)" "$SHELL_CONFIG" 2>/dev/null; then
        sed -i '/# Proxy settings (added by proxy-toggle.sh)/,/^export NO_PROXY/d' "$SHELL_CONFIG"
        echo "  ✓ Removed from $SHELL_CONFIG"
    else
        echo "  ⚠ No proxy settings found in $SHELL_CONFIG"
    fi
    
    # Unset for current session
    unset http_proxy https_proxy ftp_proxy no_proxy
    unset HTTP_PROXY HTTPS_PROXY FTP_PROXY NO_PROXY
    echo "  ✓ Disabled for current session"
    
    # Remove pacman/yay proxy
    remove_pacman_proxy
    
    echo ""
    echo "✓ Proxy disabled"
    echo ""
    echo "  Open new terminals for changes to take effect, or run:"
    echo "  source $SHELL_CONFIG"
}

status_proxy() {
    echo "=== Shell Detection ==="
    echo "  Detected shell config: $SHELL_CONFIG"
    echo ""
    echo "=== Current Session ==="
    if env | grep -qi "http_proxy"; then
        env | grep -i proxy
    else
        echo "  No proxy variables set"
    fi
    
    echo ""
    echo "=== Shell Config ($SHELL_CONFIG) ==="
    if grep -q "# Proxy settings (added by proxy-toggle.sh)" "$SHELL_CONFIG" 2>/dev/null; then
        echo "  Proxy settings found (will be applied to new terminals)"
    else
        echo "  No proxy settings found"
    fi
    
    echo ""
    echo "=== Pacman/Yay ==="
    if grep -q "^XferCommand.*--proxy" "$PACMAN_CONF" 2>/dev/null; then
        echo "  Proxy configured"
        grep "^XferCommand" "$PACMAN_CONF"
    else
        echo "  No proxy configured"
    fi
}

case "$1" in
    on|enable|set)
        set_proxy
        ;;
    off|disable|remove)
        remove_proxy
        ;;
    status|check)
        status_proxy
        ;;
    steam)
        shift  # Remove 'steam' from arguments
        launch_steam "$@"
        ;;
    *)
        echo "Usage: $0 {on|off|status|steam}"
        echo ""
        echo "  on/enable/set     - Enable proxy (shell + pacman/yay)"
        echo "  off/disable/remove - Disable proxy"
        echo "  status/check       - Show current proxy settings"
        echo "  steam              - Launch Steam with proxy"
        exit 1
        ;;
esac
