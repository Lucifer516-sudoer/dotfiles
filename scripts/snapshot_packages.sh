#!/bin/bash

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
TARGET_DIR="${SCRIPT_DIR}/../snapshots"

# Helper to create the target directory if it doesnt exist
create_snapshot_dir() {
    echo "${TARGET_DIR}"
}


leaves_from_aur() {
    echo "${SCRIPT_DIR}"
    echo "${TARGET_DIR}"
}

leaves_from_aur