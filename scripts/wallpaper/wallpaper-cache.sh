#!/usr/bin/env bash
cache_folder="$HOME/.cache/hypr"
generated_versions="$cache_folder/wallpaper-generated"
rm $generated_versions/*
echo ":: Wallpaper cache cleared"
notify-send "Wallpaper cache cleared"
