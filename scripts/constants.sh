#!/bin/bash

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
SNAPSHOT_DIR="$SCRIPT_DIR/../snapshots-$(date +'%Y-%b-%d_%H-%M')"