#!/usr/bin/env bash
# uninstall.sh - GNU Stow-based dotfiles uninstaller (updated)
# Safely removes dotfiles installed by install.sh and optionally restores backups.
# Usage: ./uninstall.sh [--dry-run] [--restore-last] [--yes] [--log <file>] [--package <name>]

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global configuration
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dev/dotfiles}"
STOW_TARGET="${STOW_TARGET:-$HOME}"
DRY_RUN=false
RESTORE_LAST=false
YES_FLAG=false
LOG_FILE=""
PACKAGE_TO_UNSTOW=""  # single package to unstow if provided
BACKUP_DIR="$HOME/.local/share/dotfiles-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Arrays to track actions
PACKAGES_TO_UNSTOW=()

# ============================================================================
# Logging and output functions
# ============================================================================

log() {
    local msg="$1"
    echo -e "${BLUE}[INFO]${NC} $msg"
    if [[ -n "$LOG_FILE" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $msg" >> "$LOG_FILE"
    fi
}

log_success() {
    local msg="$1"
    echo -e "${GREEN}[✓]${NC} $msg"
    if [[ -n "$LOG_FILE" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $msg" >> "$LOG_FILE"
    fi
}

log_warn() {
    local msg="$1"
    echo -e "${YELLOW}[WARN]${NC} $msg"
    if [[ -n "$LOG_FILE" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $msg" >> "$LOG_FILE"
    fi
}

log_error() {
    local msg="$1"
    echo -e "${RED}[ERROR]${NC} $msg"
    if [[ -n "$LOG_FILE" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $msg" >> "$LOG_FILE"
    fi
}

# ============================================================================
# Utility functions
# ============================================================================

# Prompt user for confirmation (respects --yes flag)
prompt_confirm() {
    local msg="$1"
    if [[ "$YES_FLAG" == true ]]; then
        log "$msg (auto-confirmed with --yes)"
        return 0
    fi
    read -p "$(echo -e "${YELLOW}?${NC} $msg (y/n) ")" -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Safely create a directory
safe_mkdirp() {
    local dir="$1"
    if [[ "$DRY_RUN" == true ]]; then
        log "  [DRY-RUN] mkdir -p '$dir'"
    else
        mkdir -p "$dir"
    fi
}

# Create a temporary backup of a path before removal
backup_before_remove() {
    local path="$1"
    if [[ ! -e "$path" ]]; then
        return 0
    fi
    safe_mkdirp "$BACKUP_DIR/$TIMESTAMP"
    if [[ "$DRY_RUN" == true ]]; then
        log "  [DRY-RUN] cp -a '$path' '$BACKUP_DIR/$TIMESTAMP/'"
    else
        cp -a "$path" "$BACKUP_DIR/$TIMESTAMP/"
        log "Backed up '$path' to '$BACKUP_DIR/$TIMESTAMP/'"
    fi
}

# List available backups
list_backups() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        log "No backups directory found: $BACKUP_DIR"
        return 1
    fi

    log "Available backups (most recent first):"
    find "$BACKUP_DIR" -maxdepth 1 -type d -name "*_*" 2>/dev/null | sort -r | head -20 | while read -r backup; do
        local ts
        ts=$(basename "$backup")
        local files
        files=$(find "$backup" -type f 2>/dev/null | wc -l)
        log "  $ts ($files files)"
    done
}

# Get the most recent backup
get_latest_backup() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        return 1
    fi

    find "$BACKUP_DIR" -maxdepth 1 -type d -name "*_*" 2>/dev/null | sort -r | head -1
}

# Restore files from backup path
restore_backup() {
    local backup_path="$1"
    if [[ ! -d "$backup_path" ]]; then
        log_error "Backup directory not found: $backup_path"
        return 1
    fi

    log "Restoring from backup: $backup_path"

    find "$backup_path" -type f | while read -r file; do
        # Preserve original relative layout by copying to $HOME
        local rel
        rel="${file#$backup_path/}"
        local target="$HOME/$rel"
        log "Restoring $rel -> $target"
        if [[ "$DRY_RUN" == true ]]; then
            log "  [DRY-RUN] mkdir -p '$(dirname "$target")' && cp -a '$file' '$target'"
        else
            mkdir -p "$(dirname "$target")"
            cp -a "$file" "$target"
        fi
    done
}

# ============================================================================
# Preflight checks
# ============================================================================

preflight_checks() {
    log "Running preflight checks..."

    # Ensure not running as root
    if [[ $EUID -eq 0 ]]; then
        log_error "This script must not be run as root. Exiting."
        exit 1
    fi
    log_success "Not running as root"

    # Verify dotfiles directory exists
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log_error "Dotfiles directory not found: $DOTFILES_DIR"
        exit 1
    fi
    log_success "Dotfiles directory found: $DOTFILES_DIR"

    # Check if stow is installed
    if ! command_exists stow; then
        log_error "GNU stow is not installed. Cannot uninstall."
        exit 1
    fi
    log_success "stow is installed"

    # Log file setup
    if [[ -n "$LOG_FILE" ]]; then
        safe_mkdirp "$(dirname "$LOG_FILE")"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Uninstall script started" >> "$LOG_FILE"
        log "Logging to: $LOG_FILE"
    fi
}

# ============================================================================
# Package detection
# ============================================================================

detect_packages() {
    log "Detecting packages to unstow..."
    local packages=()

    local repo_base
    repo_base=$(basename "$DOTFILES_DIR")

    # List top-level directories in DOTFILES_DIR
    while IFS= read -r -d '' pkg_dir; do
        local pkg_name
        pkg_name=$(basename "$pkg_dir")

        # Skip hidden files and non-directories
        [[ "$pkg_name" == .* ]] && continue
        [[ ! -d "$pkg_dir" ]] && continue

        # Skip if pkg_dir points to the repo root itself (avoid nested same-name folder)
        if [[ "$(realpath "$pkg_dir")" == "$(realpath "$DOTFILES_DIR")" ]]; then
            log "Skipping repo root directory: $pkg_name"
            continue
        fi

        # Skip accidental duplicate package folder named the same as repo (e.g., dev/dotfiles/dotfiles)
        if [[ "$pkg_name" == "$repo_base" ]]; then
            log "Skipping package with same name as repo base: $pkg_name"
            continue
        fi

        # Check if package has stow-relevant content: .config, bin, .local, or top-level dotfiles
        if has_stow_content "$pkg_dir"; then
            packages+=("$pkg_name")
            log "Detected package: $pkg_name"
        fi
    done < <(find "$DOTFILES_DIR" -maxdepth 1 -type d -print0 2>/dev/null | grep -zv "^\.$")

    PACKAGES_TO_UNSTOW=("${packages[@]}")

    # If user specified a single package to uninstall, filter
    if [[ -n "$PACKAGE_TO_UNSTOW" ]]; then
        local found=false
        for p in "${PACKAGES_TO_UNSTOW[@]}"; do
            if [[ "$p" == "$PACKAGE_TO_UNSTOW" ]]; then
                PACKAGES_TO_UNSTOW=("$PACKAGE_TO_UNSTOW")
                found=true
                break
            fi
        done
        if [[ "$found" == false ]]; then
            log_error "Requested package '$PACKAGE_TO_UNSTOW' not found in $DOTFILES_DIR"
            exit 1
        fi
    fi
}

    # If user specified a single package to uninstall, filter
    if [[ -n "$PACKAGE_TO_UNSTOW" ]]; then
        local found=false
        for p in "${PACKAGES_TO_UNSTOW[@]}"; do
            if [[ "$p" == "$PACKAGE_TO_UNSTOW" ]]; then
                PACKAGES_TO_UNSTOW=("$PACKAGE_TO_UNSTOW")
                found=true
                break
            fi
        done
        if [[ "$found" == false ]]; then
            log_error "Requested package '$PACKAGE_TO_UNSTOW' not found in $DOTFILES_DIR"
            exit 1
        fi
    fi


has_stow_content() {
    local pkg_dir="$1"
    [[ -d "$pkg_dir/.config" ]] && return 0
    [[ -d "$pkg_dir/bin" ]] && return 0
    [[ -d "$pkg_dir/.local" ]] && return 0

    local has_dotfile=false
    while IFS= read -r -d '' file; do
        [[ -f "$file" && "${file##*/}" == .* ]] && has_dotfile=true && break
    done < <(find "$pkg_dir" -maxdepth 1 -type f -print0 2>/dev/null)
    [[ "$has_dotfile" == true ]] && return 0

    # VSCode special-case: accept common layouts
    if [[ -f "$pkg_dir/.config/vscode/settings.json" || -f "$pkg_dir/.config/Code/User/settings.json" || -f "$pkg_dir/vscode/extensions.txt" ]]; then
        return 0
    fi

    return 1
}

# Determine stow target for a given package
get_stow_target() {
    local pkg_name="$1"
    local pkg_dir="$DOTFILES_DIR/$pkg_name"

    # If package explicitly contains a .config/ path, stow into $HOME (stow will create .config/)
    if [[ -d "$pkg_dir/.config" ]]; then
        echo "$HOME"
        return
    fi
    echo "$STOW_TARGET"
}

# ============================================================================
# Unstow logic
# ============================================================================

unstow_one_pkg() {
    local pkg_name="$1"
    local target="$2"
    local pkg_dir="$DOTFILES_DIR/$pkg_name"

    if [[ ! -d "$pkg_dir" ]]; then
        log_warn "Package directory not found: $pkg_dir"
        return 1
    fi

    # Special-case: vscode
    if [[ "$pkg_name" == "vscode" ]]; then
        unstow_vscode_pkg "$pkg_dir"
        return $?
    fi

    log "Unstowing package '$pkg_name' from '$target'..."

    if [[ "$DRY_RUN" == true ]]; then
        log "  [DRY-RUN] stow -D -t '$target' -d '$DOTFILES_DIR' '$pkg_name'"
        stow -n -D -t "$target" -d "$DOTFILES_DIR" "$pkg_name" 2>&1 | sed 's/^/    /' || true
    else
        # Backup targets if they exist and are regular files (not symlinks)
        # We'll try to backup files under the package paths
        find "$pkg_dir" -type f -print0 2>/dev/null | while IFS= read -r -d '' file; do
            local rel_path
            rel_path="${file#$pkg_dir/}"
            local target_file="$target/$rel_path"
            if [[ -e "$target_file" && ! -L "$target_file" ]]; then
                backup_before_remove "$target_file"
            fi
        done

        stow -D -t "$target" -d "$DOTFILES_DIR" "$pkg_name" || log_warn "stow -D returned non-zero (may be okay if links missing)"
        log_success "Package '$pkg_name' unstowed"
    fi
}

# ============================================================================
# Special handling: VS Code unstow
# - Remove symlink ~/.config/Code/User/settings.json if it points into the repo
# - Optionally restore settings from the most recent backup
# ============================================================================

unstow_vscode_pkg() {
    local pkg_dir="$1"
    local repo_settings="$pkg_dir/.config/vscode/settings.json"
    local repo_alt="$pkg_dir/.config/Code/User/settings.json"
    local target_settings="$HOME/.config/Code/User/settings.json"

    # determine which repo path exists
    if [[ -f "$repo_alt" ]]; then
        repo_settings="$repo_alt"
    fi

    log "Unstowing VS Code package..."

    # If target_settings exists and is a symlink to our repo file, remove it
    if [[ -L "$target_settings" ]]; then
        local dest
        dest=$(readlink -f "$target_settings" 2>/dev/null || true)
        if [[ -n "$repo_settings" && "$dest" == "$(readlink -f "$repo_settings" 2>/dev/null || true)" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                log "  [DRY-RUN] unlink '$target_settings'"
            else
                backup_before_remove "$target_settings"
                rm -f "$target_settings"
                log_success "Removed symlink $target_settings"
            fi
        else
            # if it's a symlink but not pointing at the repo, backup and remove it optionally
            if [[ "$DRY_RUN" == true ]]; then
                log "  [DRY-RUN] unlink (non-repo) '$target_settings'"
            else
                backup_before_remove "$target_settings"
                rm -f "$target_settings"
                log_success "Removed existing $target_settings"
            fi
        fi
    elif [[ -e "$target_settings" ]]; then
        # regular file: backup and remove
        if [[ "$DRY_RUN" == true ]]; then
            log "  [DRY-RUN] backup and remove '$target_settings'"
        else
            backup_before_remove "$target_settings"
            rm -f "$target_settings"
            log_success "Removed $target_settings"
        fi
    else
        log "No VS Code settings found at $target_settings"
    fi

    # Also run stow -D in case package created other links
    if [[ "$DRY_RUN" == true ]]; then
        log "  [DRY-RUN] stow -D -t '$STOW_TARGET' -d '$DOTFILES_DIR' 'vscode'"
        stow -n -D -t "$STOW_TARGET" -d "$DOTFILES_DIR" "vscode" 2>&1 | sed 's/^/    /' || true
    else
        stow -D -t "$STOW_TARGET" -d "$DOTFILES_DIR" "vscode" || log_warn "stow -D reported issues (may be ok)"
        log_success "VS Code package unstowed (if any links existed)"
    fi

    return 0
}

# ============================================================================
# Main uninstall flow
# ============================================================================

main() {
    log "==============================================="
    log "Dotfiles Uninstall Script (GNU Stow-based) - Updated"
    log "==============================================="
    log "Dotfiles directory: $DOTFILES_DIR"
    log "Stow target: $STOW_TARGET"
    [[ "$DRY_RUN" == true ]] && log "MODE: DRY-RUN (no changes will be made)"
    [[ "$RESTORE_LAST" == true ]] && log "MODE: Will restore last backup after unstowing"
    [[ -n "$PACKAGE_TO_UNSTOW" ]] && log "PACKAGE: $PACKAGE_TO_UNSTOW"
    log ""

    preflight_checks

    detect_packages

    if [[ ${#PACKAGES_TO_UNSTOW[@]} -eq 0 ]]; then
        log_warn "No packages detected to unstow"
        return 0
    fi

    log "Packages to unstow: ${PACKAGES_TO_UNSTOW[*]}"
    log ""

    # Show planned unstow commands
    log "Planned unstow commands (preview):"
    for pkg in "${PACKAGES_TO_UNSTOW[@]}"; do
        local target
        target=$(get_stow_target "$pkg")
        log "  stow -D -t '$target' -d '$DOTFILES_DIR' '$pkg'"
    done
    log ""

    if ! prompt_confirm "Proceed with uninstallation?"; then
        log "Uninstallation cancelled."
        return 0
    fi

    # Unstow all packages
    for pkg in "${PACKAGES_TO_UNSTOW[@]}"; do
        local target
        target=$(get_stow_target "$pkg")
        unstow_one_pkg "$pkg" "$target"
    done

    # Handle backup restoration if requested
    if [[ "$RESTORE_LAST" == true ]]; then
        log "Attempting to restore last backup..."
        local latest_backup
        latest_backup=$(get_latest_backup) || {
            log_error "No backups found"
            return 1
        }

        log "Latest backup: $latest_backup"
        if ! prompt_confirm "Restore from $latest_backup?"; then
            log "Skipping backup restoration"
        else
            restore_backup "$latest_backup"
        fi
    else
        log "To restore a backup later, run: ./uninstall.sh --restore-last"
        list_backups || true
    fi

    # Summary
    log ""
    log "==============================================="
    if [[ "$DRY_RUN" == true ]]; then
        log_success "DRY-RUN completed successfully"
    else
        log_success "Uninstallation completed successfully"
    fi
    log "==============================================="

    log ""
    log "Post-uninstall steps:"
    log "  1. Restart your shell: exec zsh"
    log "  2. Review your config files (may need manual cleanup)"
    log "  3. Check backups at: $BACKUP_DIR"
    log ""

    if [[ -n "$LOG_FILE" ]]; then
        log "Full log available at: $LOG_FILE"
    fi
}

# ============================================================================
# Argument parsing
# ============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --restore-last)
                RESTORE_LAST=true
                shift
                ;;
            --yes)
                YES_FLAG=true
                shift
                ;;
            --package|-p)
                if [[ -z "${2:-}" ]]; then
                    log_error "--package requires a package name"
                    exit 1
                fi
                PACKAGE_TO_UNSTOW="$2"
                shift 2
                ;;
            --log)
                if [[ -z "${2:-}" ]]; then
                    log_error "--log requires a file path"
                    exit 1
                fi
                LOG_FILE="$2"
                shift 2
                ;;
            --help|-h)
                print_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                print_help
                exit 1
                ;;
        esac
    done
}

print_help() {
    cat << 'EOF'
Usage: ./uninstall.sh [OPTIONS]

GNU Stow-based dotfiles uninstaller. Removes symlinks created by install.sh.

OPTIONS:
  --dry-run          Show what would be done without making changes
  --restore-last     Restore files from the most recent backup after unstowing
  --package <name>   Unstow only the named package (e.g., --package vscode)
  --yes              Non-interactive mode; auto-confirm prompts
  --log <file>       Append logs to specified file
  -h, --help         Show this help message

EXAMPLES:
  # Dry-run to preview uninstall
  ./uninstall.sh --dry-run

  # Uninstall only vscode and restore last backup
  ./uninstall.sh --package vscode --restore-last --yes

  # Interactive uninstall with logging
  ./uninstall.sh --log ~/uninstall.log

BACKUP LOCATION:
  ~/.local/share/dotfiles-backups/<YYYYMMDD_HHMMSS>/

EOF
}

# ============================================================================
# Entry point
# ============================================================================

parse_args "$@"
main
