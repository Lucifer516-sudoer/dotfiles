#!/usr/bin/env bash
# install.sh - GNU Stow-based dotfiles installer (with VS Code support)
# Safely deploys user dotfiles from repo to home directory with backup, safety checks, and idempotency.
# Usage: ./install.sh [--dry-run] [--target <home|config|both>] [--pkg-install yes|no] [--force] [--yes] [--log <file>]

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
FORCE=false
YES_FLAG=false
PKG_INSTALL=false
LOG_FILE=""
BACKUP_DIR="$HOME/.local/share/dotfiles-backups"
LOG_DIR="$HOME/.local/share/dotfiles-installer/logs"
PKG_MGR=""
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Arrays to track actions
PACKAGES_TO_STOW=()
BACKUPS_MADE=()

# ============================================================================
# Logging and output functions
# ============================================================================

log() {
    local msg="$1"
    echo -e "${BLUE}[INFO]${NC} $msg"
    if [[ -n "$LOG_FILE" ]]; then
        printf '[%s] [INFO] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$msg" >> "$LOG_FILE"
    fi
}

log_success() {
    local msg="$1"
    echo -e "${GREEN}[✓]${NC} $msg"
    if [[ -n "$LOG_FILE" ]]; then
        printf '[%s] [SUCCESS] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$msg" >> "$LOG_FILE"
    fi
}

log_warn() {
    local msg="$1"
    echo -e "${YELLOW}[WARN]${NC} $msg"
    if [[ -n "$LOG_FILE" ]]; then
        printf '[%s] [WARN] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$msg" >> "$LOG_FILE"
    fi
}

log_error() {
    local msg="$1"
    echo -e "${RED}[ERROR]${NC} $msg"
    if [[ -n "$LOG_FILE" ]]; then
        printf '[%s] [ERROR] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$msg" >> "$LOG_FILE"
    fi
}

# ============================================================================
# Utility functions
# ============================================================================

# Prompt user for confirmation (respects --yes flag)
prompt_confirm() {
    local msg="$1"
    if [[ "$YES_FLAG" == true ]]; then
        log "$msg - auto-confirmed with --yes"
        return 0
    fi
    read -p "$(echo -e "${YELLOW}?${NC} $msg (y/n) ")" -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Create backup directory and return backup path
create_backup() {
    local backup_subdir="$BACKUP_DIR/$TIMESTAMP"
    mkdir -p "$backup_subdir"
    echo "$backup_subdir"
}

# Back up a file or directory before overwriting
backup() {
    local source_path="$1"

    if [[ ! -e "$source_path" ]]; then
        return 0
    fi

    local backup_path
    backup_path=$(create_backup)

    # Create unique backup filename to avoid collisions
    local unique_name
    unique_name="$(basename "$source_path")_$(date +%s%N)"
    log "Backing up '$source_path' to '$backup_path/$unique_name'"
    cp -a "$source_path" "$backup_path/$unique_name"
    BACKUPS_MADE+=("$source_path -> $backup_path/$unique_name")
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
        log_warn "GNU stow is not installed."
        if [[ "$PKG_INSTALL" == true ]]; then
            log "Attempting to install stow..."
            install_stow
        else
            log_error "stow is required. Please install it or use --pkg-install yes"
            exit 1
        fi
    else
        log_success "stow is installed"
    fi

    # Detect package manager
    detect_pkg_mgr
    log_success "Package manager: ${PKG_MGR:-none}"

    # Log file setup
    if [[ -n "$LOG_FILE" ]]; then
        safe_mkdirp "$(dirname "$LOG_FILE")"
        printf '[%s] Install script started\n' "$(date '+%Y-%m-%d %H:%M:%S')" >"$LOG_FILE"
        log "Logging to: $LOG_FILE"
    fi
}

# Detect which package manager is available
detect_pkg_mgr() {
    if command_exists paru; then
        PKG_MGR="paru"
    elif command_exists yay; then
        PKG_MGR="yay"
    elif command_exists pacman; then
        PKG_MGR="pacman"
    elif command_exists apt; then
        PKG_MGR="apt"
    elif command_exists dnf; then
        PKG_MGR="dnf"
    else
        log_warn "No supported package manager detected: paru, yay, pacman, apt, dnf"
        PKG_MGR=""
    fi
}

# Install stow using detected package manager
install_stow() {
    case "$PKG_MGR" in
        paru|yay)
            log "Installing stow via $PKG_MGR..."
            if [[ "$DRY_RUN" == true ]]; then
                log "  [DRY-RUN] $PKG_MGR -S --noconfirm stow"
            else
                "$PKG_MGR" -S --noconfirm stow || log_error "Failed to install stow"
            fi
            ;;
        pacman)
            log "Installing stow via pacman requires sudo..."
            if [[ "$DRY_RUN" == true ]]; then
                log "  [DRY-RUN] sudo pacman -S --noconfirm stow"
            else
                sudo pacman -S --noconfirm stow || log_error "Failed to install stow"
            fi
            ;;
        apt)
            log "Installing stow via apt requires sudo..."
            if [[ "$DRY_RUN" == true ]]; then
                log "  [DRY-RUN] sudo apt-get install -y stow"
            else
                sudo apt-get update && sudo apt-get install -y stow || log_error "Failed to install stow"
            fi
            ;;
        dnf)
            log "Installing stow via dnf requires sudo..."
            if [[ "$DRY_RUN" == true ]]; then
                log "  [DRY-RUN] sudo dnf install -y stow"
            else
                sudo dnf install -y stow || log_error "Failed to install stow"
            fi
            ;;
        *)
            log_error "Cannot auto-install stow on this system. Please install manually."
            exit 1
            ;;
    esac
}

# ============================================================================
# Package detection and stow logic
# ============================================================================

# Detect all packages in DOTFILES_DIR that should be stowed
detect_packages() {
    log "Detecting packages in $DOTFILES_DIR..."
    local packages=()

    # List top-level directories in DOTFILES_DIR
    while IFS= read -r -d '' pkg_dir; do
        local pkg_name
        pkg_name=$(basename "$pkg_dir")

        # Skip hidden files and non-directories
        [[ "$pkg_name" == .* ]] && continue
        [[ ! -d "$pkg_dir" ]] && continue

        # Check if package has stow-relevant content: .config, bin, .local, or top-level dotfiles
        if has_stow_content "$pkg_dir"; then
            packages+=("$pkg_name")
            log "Detected package: $pkg_name"
        fi
    done < <(find "$DOTFILES_DIR" -maxdepth 1 -type d -print0 | grep -zv "^\.$")

    PACKAGES_TO_STOW=("${packages[@]}")
}

# Check if a package directory has stow-relevant content
has_stow_content() {
    local pkg_dir="$1"

    # Check for .config subdirectory (most common)
    [[ -d "$pkg_dir/.config" ]] && return 0

    # Check for bin directory
    [[ -d "$pkg_dir/bin" ]] && return 0

    # Check for .local directory
    [[ -d "$pkg_dir/.local" ]] && return 0

    # Check for top-level dotfiles (e.g., .zshrc, .gitconfig)
    local has_dotfile=false
    while IFS= read -r -d '' file; do
        [[ -f "$file" && "${file##*/}" == .* ]] && has_dotfile=true && break
    done < <(find "$pkg_dir" -maxdepth 1 -type f -print0 2>/dev/null)
    [[ "$has_dotfile" == true ]] && return 0

    # Special-case: vscode package with settings or extensions
    if [[ -f "$pkg_dir/.config/vscode/settings.json" || -f "$pkg_dir/vscode/extensions.txt" ]]; then
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

    # Default
    echo "$HOME"
}

# Check for conflicts before stowing
check_stow_conflicts() {
    local pkg_name="$1"
    local target="$2"
    local pkg_dir="$DOTFILES_DIR/$pkg_name"

    # Simulate stow to find conflicts (grep output)
    if stow -n -t "$target" -d "$DOTFILES_DIR" "$pkg_name" 2>&1 | grep -i "conflict" >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# Perform stow for a single package
stow_one_pkg() {
    local pkg_name="$1"
    local target="$2"
    local pkg_dir="$DOTFILES_DIR/$pkg_name"

    if [[ ! -d "$pkg_dir" ]]; then
        log_warn "Package directory not found: $pkg_dir"
        return 1
    fi

    # Special-case: vscode package (link settings.json and optionally install extensions)
    if [[ "$pkg_name" == "vscode" ]]; then
        handle_vscode_pkg "$pkg_dir"
        return $?
    fi

    log "Stowing package '$pkg_name' to '$target'..."

    # Check for conflicts
    if check_stow_conflicts "$pkg_name" "$target"; then
        log_warn "Potential conflicts detected for package '$pkg_name'"
        if [[ "$FORCE" == false ]]; then
            if ! prompt_confirm "Proceed with stowing '$pkg_name' - may overwrite existing files?"; then
                log "Skipping $pkg_name"
                return 1
            fi
        fi

        # Backup conflicting files (best effort: check files under package)
        find "$pkg_dir" -type f -print0 2>/dev/null | while IFS= read -r -d '' file; do
            local rel_path
            rel_path="${file#$pkg_dir/}"
            local target_file="$target/$rel_path"

            if [[ -e "$target_file" && ! -L "$target_file" ]]; then
                backup "$target_file"
            fi
        done
    fi

    # Use stow -R (restow) for idempotency
    if [[ "$DRY_RUN" == true ]]; then
        log "  [DRY-RUN] stow -R -t '$target' -d '$DOTFILES_DIR' '$pkg_name'"
        stow -n -R -t "$target" -d "$DOTFILES_DIR" "$pkg_name" 2>&1 | sed 's/^/    /'
    else
        stow -R -t "$target" -d "$DOTFILES_DIR" "$pkg_name"
        log_success "Package '$pkg_name' stowed successfully"
    fi
}

# ============================================================================
# Special handling: VS Code
# - Symlink settings.json -> ~/.config/Code/User/settings.json
# - Optionally install extensions from vscode/extensions.txt using `code --install-extension`
# ============================================================================

handle_vscode_pkg() {
    local pkg_dir="$1"
    local repo_settings="$pkg_dir/.config/vscode/settings.json"
    local alt_repo_settings="$pkg_dir/.config/Code/User/settings.json"
    local repo_extensions="$pkg_dir/vscode/extensions.txt"
    local repo_extensions_alt="$pkg_dir/extensions.txt"
    local target_settings="$HOME/.config/Code/User/settings.json"
    local target_dir
    target_dir="$(dirname "$target_settings")"

    # Choose repo settings path
    if [[ -f "$repo_settings" ]]; then
        repo_settings="$repo_settings"
    elif [[ -f "$alt_repo_settings" ]]; then
        repo_settings="$alt_repo_settings"
    else
        repo_settings=""
    fi

    # Prefer explicit extensions file locations inside package
    if [[ -f "$repo_extensions" ]]; then
        repo_extensions="$repo_extensions"
    elif [[ -f "$repo_extensions_alt" ]]; then
        repo_extensions="$repo_extensions_alt"
    else
        repo_extensions=""
    fi

    log "Handling VS Code package..."

    # Ensure target dir exists
    if [[ "$DRY_RUN" == true ]]; then
        log "  [DRY-RUN] mkdir -p '$target_dir'"
    else
        mkdir -p "$target_dir"
    fi

    # If repo provides a settings.json, symlink it into ~/.config/Code/User/settings.json
    if [[ -n "$repo_settings" ]]; then
        if [[ -L "$target_settings" || -e "$target_settings" ]]; then
            # If exists and not the same link, back it up (unless it's already pointing at the same source)
            if [[ "$(readlink -f "$target_settings" 2>/dev/null || true)" != "$(readlink -f "$repo_settings" 2>/dev/null || true)" ]]; then
                if [[ "$DRY_RUN" == true ]]; then
                    log "  [DRY-RUN] backup existing $target_settings"
                else
                    backup "$target_settings"
                    rm -f "$target_settings"
                fi
            else
                log "Existing settings.json already points to repository file."
            fi
        fi

        if [[ "$DRY_RUN" == true ]]; then
            log "  [DRY-RUN] ln -sfn '$repo_settings' '$target_settings'"
        else
            ln -sfn "$repo_settings" "$target_settings"
            log_success "Linked $target_settings -> $repo_settings"
        fi
    else
        log_warn "No settings.json found in package. Skipping settings link."
    fi

    # Install extensions if requested and file present
    if [[ -n "$repo_extensions" ]]; then
        log "Extensions list found at $repo_extensions"
        if [[ "$PKG_INSTALL" == true ]]; then
            if ! command_exists code; then
                log_warn "VS Code 'code' CLI not found. Extensions cannot be installed automatically."
            else
                # Install each extension
                while IFS= read -r ext || [[ -n "$ext" ]]; do
                    ext="${ext%%#*}"   # strip comments after #
                    ext="$(echo -n "$ext" | tr -d '[:space:]')"
                    [[ -z "$ext" ]] && continue
                    if [[ "$DRY_RUN" == true ]]; then
                        log "  [DRY-RUN] code --install-extension $ext"
                    else
                        log "Installing extension: $ext"
                        if code --install-extension "$ext" --force >/dev/null 2>&1; then
                            log_success "Installed $ext"
                        else
                            log_warn "Failed to install $ext (continuing)"
                        fi
                    fi
                done < "$repo_extensions"
            fi
        else
            log "Skipping extension install (use --pkg-install yes to enable)."
        fi
    else
        log "No extensions.txt found for VS Code."
    fi

    return 0
}

# ============================================================================
# Oh My Zsh setup
# ============================================================================

setup_oh_my_zsh() {
    log "Setting up Oh My Zsh..."

    local zsh_dir="$HOME/.oh-my-zsh"

    if [[ -d "$zsh_dir" ]]; then
        log_success "Oh My Zsh already installed at $zsh_dir"
    else
        log "Cloning Oh My Zsh..."
        if [[ "$DRY_RUN" == true ]]; then
            log "  [DRY-RUN] git clone https://github.com/ohmyzsh/ohmyzsh.git $zsh_dir"
        else
            git clone https://github.com/ohmyzsh/ohmyzsh.git "$zsh_dir" || log_error "Failed to clone Oh My Zsh"
            log_success "Oh My Zsh cloned"
        fi
    fi

    # Install plugins
    install_zsh_plugins
}

# Install Oh My Zsh plugins
install_zsh_plugins() {
    local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    local plugins_dir="$zsh_custom/plugins"

    mkdir -p "$plugins_dir"

    local plugins=("zsh-autosuggestions" "zsh-syntax-highlighting")

    for plugin in "${plugins[@]}"; do
        local plugin_dir="$plugins_dir/$plugin"

        if [[ -d "$plugin_dir" ]]; then
            log_success "Plugin '$plugin' already installed"
        else
            log "Installing plugin '$plugin'..."
            if [[ "$DRY_RUN" == true ]]; then
                log "  [DRY-RUN] git clone https://github.com/zsh-users/$plugin.git $plugin_dir"
            else
                git clone "https://github.com/zsh-users/$plugin.git" "$plugin_dir" || log_error "Failed to install plugin '$plugin'"
                log_success "Plugin '$plugin' installed"
            fi
        fi
    done
}

# ============================================================================
# Font setup
# ============================================================================

check_and_install_fonts() {
    log "Checking for JetBrains Mono Nerd Font..."

    if fc-list 2>/dev/null | grep -i "jetbrains" > /dev/null 2>&1; then
        log_success "JetBrains Mono Nerd Font is installed"
        return 0
    fi

    log_warn "JetBrains Mono Nerd Font not found"

    if [[ "$PKG_INSTALL" != true ]]; then
        log_warn "Skipping font installation - use --pkg-install yes to install"
        return 0
    fi

    log "Attempting to install JetBrains Mono Nerd Font..."

    case "$PKG_MGR" in
        paru|yay)
            if [[ "$DRY_RUN" == true ]]; then
                log "  [DRY-RUN] $PKG_MGR -S --noconfirm nerd-fonts-jetbrains-mono"
            else
                "$PKG_MGR" -S --noconfirm nerd-fonts-jetbrains-mono || log_warn "Failed to install font via $PKG_MGR"
            fi
            ;;
        *)
            log_warn "Automatic font installation not supported for $PKG_MGR. Please install manually."
            ;;
    esac

    if ! [[ "$DRY_RUN" == true ]]; then
        log "Rebuilding font cache..."
        fc-cache -f || log_warn "Failed to rebuild font cache"
        log_success "Font cache rebuilt"
    fi
}

# ============================================================================
# Starship setup
# ============================================================================

setup_starship() {
    log "Setting up Starship..."

    if ! command_exists starship; then
        log_warn "starship is not installed"
        if [[ "$PKG_INSTALL" == true ]]; then
            log "Installing starship..."
            case "$PKG_MGR" in
                paru|yay|pacman)
                    if [[ "$PKG_MGR" == "pacman" ]]; then
                        if [[ "$DRY_RUN" == true ]]; then
                            log "  [DRY-RUN] sudo pacman -S --noconfirm starship"
                        else
                            sudo pacman -S --noconfirm starship || log_warn "Failed to install starship"
                        fi
                    else
                        if [[ "$DRY_RUN" == true ]]; then
                            log "  [DRY-RUN] $PKG_MGR -S --noconfirm starship"
                        else
                            "$PKG_MGR" -S --noconfirm starship || log_warn "Failed to install starship"
                        fi
                    fi
                    ;;
                apt)
                    if [[ "$DRY_RUN" == true ]]; then
                        log "  [DRY-RUN] sudo apt-get install -y starship"
                    else
                        sudo apt-get update && sudo apt-get install -y starship || log_warn "Failed to install starship"
                    fi
                    ;;
                dnf)
                    if [[ "$DRY_RUN" == true ]]; then
                        log "  [DRY-RUN] sudo dnf install -y starship"
                    else
                        sudo dnf install -y starship || log_warn "Failed to install starship"
                    fi
                    ;;
                *)
                    log_warn "Cannot auto-install starship on this system"
                    return 1
                    ;;
            esac
        else
            log_warn "Skipping starship installation - use --pkg-install yes to install"
            return 1
        fi
    fi

    log_success "starship is available"

    # Validate Starship config if present
    if [[ -f "$HOME/.config/starship.toml" ]]; then
        log "Starship config found at ~/.config/starship.toml"
    fi
}

# ============================================================================
# Post-install verification
# ============================================================================

verify_installation() {
    log "Verifying installation..."

    # Check stowed files
    log "Checking symlinks..."

    local check_paths=(
        "$HOME/.zshrc"
        "$HOME/.config/starship.toml"
        "$HOME/.config/kitty/kitty.conf"
        "$HOME/.config/hypr/hyprland.conf"
        "$HOME/.config/Code/User/settings.json"
    )

    for path in "${check_paths[@]}"; do
        if [[ -L "$path" ]]; then
            log_success "✓ $path - symlink"
        elif [[ -e "$path" ]]; then
            log "  $path - regular file"
        else
            log_warn "  $path - missing"
        fi
    done

    # Test shell integration
    if command_exists zsh; then
        log "Testing Zsh integration..."
        if [[ "$DRY_RUN" == true ]]; then
            log "  [DRY-RUN] zsh check"
        else
            if zsh -ic 'echo $ZSH' 2>&1 | grep -q "oh-my-zsh"; then
                log_success "Zsh and Oh My Zsh integration OK"
            fi
        fi
    fi

    # Check fonts
    if fc-list 2>/dev/null | grep -i "jetbrains" > /dev/null 2>&1; then
        log_success "JetBrains Mono Nerd Font is installed"
    else
        log_warn "JetBrains Mono Nerd Font not found - optional"
    fi
}

# ============================================================================
# Main installation flow
# ============================================================================

main() {
    log "==============================================="
    log "Dotfiles Installation Script - GNU Stow-based"
    log "==============================================="
    log "Dotfiles directory: $DOTFILES_DIR"
    log "Stow target: $STOW_TARGET"
    [[ "$DRY_RUN" == true ]] && log "MODE: DRY-RUN - no changes will be made"
    [[ "$FORCE" == true ]] && log "MODE: FORCE - backups and overwrite enabled"
    log ""
    # Preflight
    preflight_checks

    # Detect packages
    detect_packages

    if [[ ${#PACKAGES_TO_STOW[@]} -eq 0 ]]; then
        log_error "No packages detected to stow in $DOTFILES_DIR"
        exit 1
    fi

    log "Packages to stow: ${PACKAGES_TO_STOW[*]}"
    log ""

    # Show planned stow commands
    log "Planned stow commands:"
    for pkg in "${PACKAGES_TO_STOW[@]}"; do
        local target
        target=$(get_stow_target "$pkg")
        log "  stow -R -t '$target' -d '$DOTFILES_DIR' '$pkg'"
    done
    log ""

    # Prompt before proceeding
    if ! prompt_confirm "Proceed with installation?"; then
        log "Installation cancelled."
        exit 0
    fi

    # Create backup directory
    mkdir -p "$BACKUP_DIR"

    # Stow all packages
    for pkg in "${PACKAGES_TO_STOW[@]}"; do
        local target
        target=$(get_stow_target "$pkg")
        stow_one_pkg "$pkg" "$target"
    done

    log ""
    log "Setting up additional components..."

    # Setup Oh My Zsh
    setup_oh_my_zsh

    # Check and install fonts
    check_and_install_fonts

    # Setup Starship
    setup_starship

    log ""

    # Verify installation
    if [[ "$DRY_RUN" != true ]]; then
        verify_installation
    fi

    # Summary
    log ""
    log "==============================================="
    if [[ "$DRY_RUN" == true ]]; then
        log_success "DRY-RUN completed successfully"
    else
        log_success "Installation completed successfully"
    fi
    log "==============================================="

    if [[ ${#BACKUPS_MADE[@]} -gt 0 ]]; then
        log "Backups created:"
        for backup in "${BACKUPS_MADE[@]}"; do
            log "  - $backup"
        done
        log "Backups stored in: $BACKUP_DIR/$TIMESTAMP"
    fi

    log ""
    log "Post-installation steps:"
    log "  1. Restart your shell: exec zsh"
    log "  2. Reload Hyprland: hyprctl reload - if using Hyprland"
    log "  3. Restart Kitty or open a new window"
    log ""
    log "To uninstall, run: ./uninstall.sh"
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
            --force)
                FORCE=true
                shift
                ;;
            --yes)
                YES_FLAG=true
                shift
                ;;
            --pkg-install)
                if [[ -z "${2:-}" ]]; then
                    log_error "--pkg-install requires an argument: yes or no"
                    exit 1
                fi
                case "$2" in
                    yes) PKG_INSTALL=true ;;
                    no) PKG_INSTALL=false ;;
                    *) log_error "Invalid value for --pkg-install: $2"; exit 1 ;;
                esac
                shift 2
                ;;
            --target)
                if [[ -z "${2:-}" ]]; then
                    log_error "--target requires an argument: home, config, or both"
                    exit 1
                fi
                case "$2" in
                    home) STOW_TARGET="$HOME" ;;
                    config) STOW_TARGET="$HOME/.config" ;;
                    both) STOW_TARGET="$HOME" ;; # "both" is default behavior
                    *) log_error "Invalid value for --target: $2"; exit 1 ;;
                esac
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
    printf '%s\n' \
        'Usage: ./install.sh [OPTIONS]' \
        '' \
        'GNU Stow-based dotfiles installer for Arch Linux + Hyprland/Kitty/Zsh.' \
        '' \
        'OPTIONS:' \
        '  --dry-run              Show what would be done without making changes' \
        '  --force                Overwrite existing files after creating backups' \
        '  --yes                  Non-interactive mode; auto-confirm prompts' \
        '  --pkg-install yes|no   Whether to install missing system packages' \
        '  --target home|config|both' \
        '                          Stow target: home (~), config (~/.config), or both' \
        '  --log <file>           Append logs to specified file' \
        '  -h, --help             Show this help message' \
        '' \
        'EXAMPLES:' \
        '  # Dry-run to preview changes' \
        '  ./install.sh --dry-run' \
        '' \
        '  # Full installation with package installs' \
        '  ./install.sh --target both --pkg-install yes --log ~/install.log' \
        '' \
        '  # Force reinstall with auto-confirm' \
        '  ./install.sh --force --yes' \
        '' \
        'BACKUP LOCATION:' \
        '  ~/.local/share/dotfiles-backups/<YYYYMMDD_HHMMSS>/' \
        '' \
        'UNINSTALL:' \
        '  ./uninstall.sh [--dry-run] [--restore-last] [--yes] [--log <file>]' \
        ''
}

# ============================================================================
# Entry point
# ============================================================================

parse_args "$@"
main
