#!/usr/bin/env bash
# dump_packages.sh
# Exports installed packages to text files for backup.

set -e

OUTPUT_DIR="${1:-.}"
PKG_LIST="$OUTPUT_DIR/pkglist.txt"
AUR_LIST="$OUTPUT_DIR/aurlist.txt"

echo "Exporting package lists to $OUTPUT_DIR..."

# Native packages
if command -v pacman >/dev/null; then
    pacman -Qqe > "$PKG_LIST"
    echo "Saved native packages to $PKG_LIST"
fi

# AUR packages
if command -v pacman >/dev/null; then
    pacman -Qqem > "$AUR_LIST"
    echo "Saved AUR packages to $AUR_LIST"
fi

echo "Done."
