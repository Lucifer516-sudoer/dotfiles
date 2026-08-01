#!/bin/bash
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE}")" &> /dev/null && pwd)

# Loop and load everything in this directory
for file in "$SCRIPT_DIR"/*.sh; do
    # Skip sourcer.sh and logger.sh so we don't get infinite loops
    if [ -f "$file" ] && [[ "$file" != *"sourcer.sh"* ]] && [[ "$file" != *"logger.sh"* ]]; then
        source "$file"
    fi
done
echo "All configuration files loaded successfully!"
