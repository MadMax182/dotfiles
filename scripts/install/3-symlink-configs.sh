#!/bin/bash

# Script to create symbolic links for config and theme folders

SOURCE_DIR="$HOME/.userconfig/home/config"
TARGET_DIR="$HOME/.config"
THEMES_DIR="$HOME/.userconfig/themes"

[[ -d "$SOURCE_DIR" ]] || { echo "Error: $SOURCE_DIR does not exist"; exit 1; }
mkdir -p "$TARGET_DIR"

echo "Creating config symlinks..."
for folder in "$SOURCE_DIR"/*/; do
    [[ -d "$folder" ]] || continue
    name="${folder%/}" && name="${name##*/}"
    target="$TARGET_DIR/$name"

    if [[ -e "$target" && ! -L "$target" ]]; then
        mv "$target" "${target}.backup.$(date +%Y%m%d%H%M%S)"
        echo "Backed up: $name"
    fi

    ln -sfn "$SOURCE_DIR/$name" "$target"
    echo "Linked: $name"
done

WALLPAPERS_SOURCE="$HOME/.userconfig/wallpapers"
PICTURES="${PICTURES:-$(xdg-user-dir PICTURES)}"

if [[ -d "$WALLPAPERS_SOURCE" && -n "$PICTURES" ]]; then
    echo -e "\nCreating wallpapers symlink..."
    mkdir -p "$PICTURES"
    target="$PICTURES/wallpapers"
    if [[ -e "$target" && ! -L "$target" ]]; then
        mv "$target" "${target}.backup.$(date +%Y%m%d%H%M%S)"
        echo "Backed up: wallpapers"
    fi
    ln -sfn "$WALLPAPERS_SOURCE" "$target"
    echo "Linked: $PICTURES/wallpapers -> $WALLPAPERS_SOURCE"
fi

if [[ -d "$THEMES_DIR" ]]; then
    echo -e "\nCreating theme symlinks..."
    for folder in "$THEMES_DIR"/*/; do
        [[ -d "$folder" ]] || continue
        name="${folder%/}" && name="${name##*/}"
        config_dir="$SOURCE_DIR/$name"

        [[ -d "$config_dir" ]] || { echo "Skipped: $name (no config dir)"; continue; }

        rm -rf "$config_dir/themes" 2>/dev/null
        ln -sfn "$THEMES_DIR/$name" "$config_dir/themes"
        echo "Linked: $name/themes"
    done
fi

echo -e "\nDone!"
