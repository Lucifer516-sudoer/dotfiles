#!/usr/bin/env bash

WALL_DIR="$HOME/Pictures/Wallpapers"

WALL=$(find "$WALL_DIR" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' \
    -o -iname '*.png' -o -iname '*.webp' \) |
    sort |
    while IFS= read -r img; do
        name=$(basename "$img")
        name="${name%.*}"
        
        printf '%s\0icon\x1f%s\n' "$name" "$img"
    done |
    rofi -dmenu -i -show-icons -p "Choose Wallpaper" |
cut -f1)

[[ -z "$WALL" ]] && exit 0

# Resolve selected stem to its full image path
WALL=$(find "$WALL_DIR" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' \
    -o -iname '*.png' -o -iname '*.webp' \) |
    while IFS= read -r img; do
        name=$(basename "$img")
        name="${name%.*}"
        [[ "$name" == "$WALL" ]] && printf '%s\n' "$img" && break
done)

[[ -z "$WALL" ]] && exit 1

TRANSITIONS=(
    fade
    grow
    outer
    center
    wipe
    wave
    random
)

TRANSITION=${TRANSITIONS[$RANDOM % ${#TRANSITIONS[@]}]}

awww img "$WALL" \
--transition-type "$TRANSITION" \
--transition-duration 1.2 \
--transition-fps 60


matugen image "$WALL"
