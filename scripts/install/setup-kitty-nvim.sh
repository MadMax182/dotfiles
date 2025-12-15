#!/bin/bash

DESKTOP_FILE="$HOME/.local/share/applications/kitty-nvim.desktop"
mkdir -p "${DESKTOP_FILE%/*}"

[[ -f "$DESKTOP_FILE" ]] && ACTION="Updated" || ACTION="Created"

cat > "$DESKTOP_FILE" << 'EOF'
[Desktop Entry]
Name=Neovim (Kitty)
Comment=Edit files with Neovim in Kitty terminal
Exec=kitty -e nvim -- %F
Icon=nvim
Terminal=false
Type=Application
Categories=Utility;TextEditor;
MimeType=application/javascript;application/json;application/toml;application/x-shellscript;application/xml;application/x-yaml;application/yaml;inode/directory;text/css;text/html;text/markdown;text/plain;text/x-c;text/x-c++;text/x-chdr;text/x-csrc;text/x-go;text/x-java;text/x-lua;text/x-python;text/x-rust;text/x-script.python;
EOF

update-desktop-database "${DESKTOP_FILE%/*}" 2>/dev/null
echo "$ACTION: $DESKTOP_FILE"
