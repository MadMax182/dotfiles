#!/bin/bash

#sets the working directory to the scripts directory
cd "$(dirname "$0")"

echo "Current working directory is now: $(pwd)"

echo "setting keybinds"
sudo cp ./hypr/keybinds.conf $HOME/.config/hypr/conf/keybindings/default.conf

