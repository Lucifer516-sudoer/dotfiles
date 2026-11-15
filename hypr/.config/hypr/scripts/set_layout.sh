#!/usr/bin/env bash
# hypr/scripts/set_layout.sh
# Usage: set_layout.sh <layout>|cycle

STATE_FILE="$HOME/.config/hypr/layout_choice"
LAYOUTS=(dwindle master scrolling monocle)   # add maclike back only if a plugin provides it
mkdir -p "$(dirname "$STATE_FILE")"

current="$(tr -d '[:space:]' < "$STATE_FILE" 2>/dev/null)"
current="${current:-scrolling}"

if [ "$1" = "cycle" ]; then
    next="${LAYOUTS[0]}"
    for i in "${!LAYOUTS[@]}"; do
        if [ "${LAYOUTS[$i]}" = "$current" ]; then
            next="${LAYOUTS[$(( (i + 1) % ${#LAYOUTS[@]} ))]}"
            break
        fi
    done
else
    next="$1"
fi

# Validate
valid=0
for l in "${LAYOUTS[@]}"; do [ "$l" = "$next" ] && valid=1; done
if [ "$valid" -ne 1 ]; then
    notify-send "Hyprland" "Invalid layout: $next"
    exit 1
fi

# Apply live (no reload needed), then persist for next startup
if hyprctl keyword general:layout "$next" >/dev/null 2>&1; then
    echo "$next" > "$STATE_FILE"
    notify-send "Layout" "$next"
else
    notify-send "Hyprland" "Failed to set layout: $next"
    exit 1
fi