#!/bin/bash
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE}")" &> /dev/null && pwd)

# 1. Source the sourcer script to pull in 'current_datetime'
source "$SCRIPT_DIR/sourcer.sh"

log() {
    local CLASS_NAME="${1^^}"
    local MSG="$2"
    local TIMESTAMP="$(current_datetime)" # Now this command exists!
    
    printf "[%s] [%s] %s\n" "$TIMESTAMP" "$CLASS_NAME" "$MSG"
}

log "installer" "Idk testing"
