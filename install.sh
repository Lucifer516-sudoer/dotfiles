#!/usr/bin/env bash
# install.sh — bootstrap your dotfiles on Arch-like systems (Paru/pacman)
# Drop into your dotfiles repo (e.g. ~/dev/dotfiles) and run.
# Usage:
#   ./install.sh           -> normal run (will ask to continue on destructive steps)
#   ./install.sh --yes     -> noninteractive, assume yes
#   ./install.sh --dry     -> dry-run (shows actions but doesn't change files)

set -euo pipefail
IFS=$'\n\t'

#####################
# Configuration
#####################
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dev/dotfiles}"   # where your repo lives
STOW_TARGET="${STOW_TARGET:-$HOME}"                  # where stow will place symlinks
BACKUP_DIR="${BACKUP_DIR:-$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)}"
PKG_MANAGER=""
NONINTERACTIVE=0
DRY_RUN=0

# list packages you want installed by default (adjust for your workflow)
# keep package names generic; user may need to edit to match their AUR/package names
PACKAGES=(
  "hyprland"      # hyprland compositor
  "wl-clipboard"  # wl-copy wl-paste
  "wlroots"       # if needed by your compositor (name may vary)
  "kitty"         # terminal
  "thunar"        # file manager
  "fuzzel"        # launcher used in examples
  "cliphist"      # clipboard manager used in examples
  "grim"          # screenshots
  "slurp"         # selection
  "brightnessctl"
  "playerctl"
  "pipewire"      # audio (if not present)
  "pipewire-pulse"
  "wireplumber"
  "stow"
  "git"
  "bash"
)

# packages that are AUR-only (paru installs AUR) — adjust if you use different AUR names
AUR_PACKAGES=(
  "caelestia-cli" # Caelestia CLI (may be AUR package name; adjust if different)
  "calestia-shell-git"
  # Place AUR names here if you want to install via paru
  # e.g. "caelestia-cli" if it's AUR; else keep empty
)

#####################
# Helpers
#####################
echoinfo(){ printf '\e[1;36m%s\e[0m\n' "$*"; }
echowarn(){ printf '\e[1;33m%s\e[0m\n' "$*"; }
echoerr(){ printf '\e[1;31m%s\e[0m\n' "$*"; }

confirm_or_die(){
  if [ "$NONINTERACTIVE" -eq 1 ]; then
    return 0
  fi
  read -r -p "$1 [y/N] " ans
  case "$ans" in
    [Yy]*) return 0 ;;
    *) echo "Aborted."; exit 1 ;;
  esac
}

detect_pkg_manager(){
  if command -v paru >/dev/null 2>&1; then
    PKG_MANAGER="paru"
  elif command -v yay >/dev/null 2>&1; then
    PKG_MANAGER="yay"
  elif command -v pacman >/dev/null 2>&1; then
    PKG_MANAGER="pacman"
  else
    echoerr "No supported package manager found (paru/yay/pacman). Install one first."
    exit 1
  fi
  echoinfo "Using package manager: $PKG_MANAGER"
}

install_packages(){
  echoinfo "Installing packages (may ask for sudo)..."
  if [ "$DRY_RUN" -eq 1 ]; then
    printf "DRY RUN: would install: %s\n" "${PACKAGES[*]}"
    return
  fi

  if [ "$PKG_MANAGER" = "paru" ] || [ "$PKG_MANAGER" = "yay" ]; then
    "$PKG_MANAGER" -S --noconfirm --needed "${PACKAGES[@]}" || echowarn "Some packages failed to install — check output"
    if [ "${#AUR_PACKAGES[@]}" -gt 0 ]; then
      "$PKG_MANAGER" -S --noconfirm --needed "${AUR_PACKAGES[@]}" || echowarn "Some AUR packages failed"
    fi
  else
    # pacman
    sudo pacman -Syu --noconfirm --needed "${PACKAGES[@]}" || echowarn "pacman install failed for some packages"
    if [ "${#AUR_PACKAGES[@]}" -gt 0 ]; then
      echowarn "AUR packages present but no AUR helper found. Install manually: ${AUR_PACKAGES[*]}"
    fi
  fi
}

ensure_dotfiles_repo(){
  if [ ! -d "$DOTFILES_DIR/.git" ]; then
    echoinfo "No dotfiles repo found at $DOTFILES_DIR"
    if [ "$DRY_RUN" -eq 1 ]; then
      echoinfo "DRY RUN: Would git clone your repo into $DOTFILES_DIR"
    else
      read -r -p "Clone your dotfiles repo into $DOTFILES_DIR? (enter Git URL or leave empty to abort) " url
      if [ -z "$url" ]; then
        echo "No URL provided. Exiting."
        exit 1
      fi
      git clone "$url" "$DOTFILES_DIR"
    fi
  else
    echoinfo "Dotfiles repo present: $DOTFILES_DIR"
  fi
}

backup_conf_if_exists(){
  local target="$1"
  if [ -e "$target" ] || [ -L "$target" ]; then
    mkdir -p "$BACKUP_DIR"
    echoinfo "Backing up $target -> $BACKUP_DIR/"
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "DRY RUN: would mv $target $BACKUP_DIR/"
    else
      mv "$target" "$BACKUP_DIR/"
    fi
  fi
}

stow_packages(){
  echoinfo "Stowing packages from $DOTFILES_DIR into $STOW_TARGET"
  pushd "$DOTFILES_DIR" >/dev/null
  for pkg in */; do
    pkg="${pkg%/}"
    # skip .git and README
    if [[ "$pkg" = ".git" || "$pkg" = "README.md" || "$pkg" = "install.sh" ]]; then
      continue
    fi
    # only stow directories that look like packages (has .config or bin)
    if [ -d "$pkg" ]; then
      if [ -d "$pkg/.config" ] || [ -d "$pkg/bin" ] || [ -d "$pkg/.local" ]; then
        echoinfo "-> Stow: $pkg"
        if [ "$DRY_RUN" -eq 1 ]; then
          echo "DRY RUN: stow -t $STOW_TARGET $pkg"
        else
          # ensure no pre-existing path would conflict: if target path exists, back it up
          # get top-level entries inside package to check conflicts
          while read -r entry; do
            # only check top-level entries
            target_path="$STOW_TARGET/${entry#.}"
            if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
              backup_conf_if_exists "$target_path"
            fi
          done < <(find "$pkg" -maxdepth 2 -mindepth 1 -printf "%P\n" | sed -n '1,100p' | awk -F/ '{print $1}' | sort -u)
          stow -t "$STOW_TARGET" "$pkg"
        fi
      fi
    fi
  done
  popd >/dev/null
}

fix_permissions(){
  # make scripts executable
  echoinfo "Making scripts in $DOTFILES_DIR/*/scripts and */bin executable"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY RUN: chmod +x on scripts"
    return
  fi
  find "$DOTFILES_DIR" -type d \( -name "scripts" -o -name "bin" \) -prune -print0 2>/dev/null | while IFS= read -r -d '' d; do
    find "$d" -type f -print0 | xargs -0 chmod +x || true
  done
}

enable_user_services(){
  # optional: enable/popular services. Don't blindly enable critical services — let user confirm.
  echoinfo "User service enabling step. Recommended: enable pipewire/wireplumber if used."
  if [ "$NONINTERACTIVE" -eq 0 ]; then
    read -r -p "Enable pipewire (systemctl --user enable --now pipewire pipewire-pulse wireplumber)? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
      systemctl --user enable --now pipewire pipewire-pulse wireplumber || echowarn "Failed to enable pipewire services (run manually)"
    fi
  fi
}

print_post_install(){
  cat <<'EOF'

INSTALL COMPLETE (partial) — next steps:

1. If you changed autostart or your compositor, restart your session or run:
   hyprctl reload

2. Test Caelestia commands:
   caelestia shell drawers list
   caelestia shell drawers toggle launcher

3. If you mapped a tap->F13 or interception trick, follow the extra setup steps in README.

4. Verify packages and AUR installs manually if anything failed.

EOF
}

#####################
# Parse args
#####################
for arg in "$@"; do
  case "$arg" in
    --yes|-y) NONINTERACTIVE=1 ;;
    --dry) DRY_RUN=1 ;;
    --help|-h) echo "usage: $0 [--yes|-y] [--dry]" ; exit 0 ;;
  esac
done

#####################
# Main
#####################
echoinfo "Dotfiles install starting. DOTFILES_DIR=$DOTFILES_DIR, STOW_TARGET=$STOW_TARGET"
detect_pkg_manager
ensure_dotfiles_repo

# Offer to install base packages
if [ "$NONINTERACTIVE" -eq 0 ]; then
  echo
  echoinfo "Package list preview: ${PACKAGES[*]}"
  confirm_or_die "Install packages listed above? (requires sudo or AUR helper)"
fi

install_packages

# Back up home dotfiles we will override (only high-level)
backup_conf_if_exists "$HOME/.config"
backup_conf_if_exists "$HOME/.local/bin"
backup_conf_if_exists "$HOME/.bashrc" || true
backup_conf_if_exists "$HOME/.profile" || true
backup_conf_if_exists "$HOME/.zshrc" || true

stow_packages
fix_permissions
enable_user_services
print_post_install

echoinfo "Done."
