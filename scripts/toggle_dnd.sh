#!/bin/bash
# Toggle DND mode with notification

# Check current DND status
dnd_status=$(swaync-client -D)

if [[ "$dnd_status" == "true" ]]; then
    # DND is currently ON, notify before turning OFF
    swaync-client -d
    sleep 0.5
    notify-send -u normal "Do Not Disturb" "Turning OFF DND mode" -t 2000
else
    # DND is currently OFF, notify before turning ON
    notify-send -u normal "Do Not Disturb" "Turning ON DND mode" -t 2000
    sleep 0.5
    swaync-client -d
fi
