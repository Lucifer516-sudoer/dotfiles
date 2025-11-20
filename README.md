# Dotfiles Installer

A safe, idempotent GNU Stow-based dotfiles installer for Arch Linux machines running Hyprland, Kitty, Zsh + Oh My Zsh, and Starship.

## Overview

This installer automates deployment of dotfiles from your git repository into your home directory using **GNU Stow** for symlink management. It provides:

- **Safety-first approach**: backups before any destructive operation
- **Idempotency**: running multiple times does not create duplicates
- **Per-package detection**: automatically determines which packages to stow
- **Oh My Zsh setup**: optional automatic installation and plugin setup
- **Font management**: detects and optionally installs JetBrains Mono Nerd Font
- **Dry-run mode**: preview all changes before applying them
- **Comprehensive logging**: optional log files for troubleshooting

## Repository Structure

Your dotfiles repository should follow this layout:

```
dotfiles/
├── install.sh              # Main installer
├── uninstall.sh            # Uninstaller
├── test_install.sh         # Smoke test
├── README.md               # This file
├── zshrc/                  # Zsh configuration
│   └── .zshrc
├── hypr/                   # Hyprland configuration
│   └── .config/
│       └── hypr/
│           ├── hyprland.conf
│           ├── keybindings.conf
│           └── ...
├── kitty/                  # Kitty terminal configuration
│   └── .config/
│       └── kitty/
│           ├── kitty.conf
│           └── ...
└── starship/               # Starship prompt configuration
    └── .config/
        └── starship.toml
```

**Layout Detection**: The installer automatically detects each package's structure:
- If `<package>/.config/<package>/...` exists → stow to `$HOME` (creates `~/.config/<package>/...`)
- If `<package>/.<dotfile>` exists → stow to `$HOME` (creates `~/.<dotfile>`)
- If `<package>/bin/` exists → stow to `$HOME` (creates `~/bin/...`)
- If `<package>/.local/` exists → stow to `$HOME` (creates `~/.local/...`)

## Quick Start

### Prerequisites

Ensure you have:
- **GNU Stow** (install: `paru -S stow` or `pacman -S stow`)
- **Git** (for cloning plugins and Oh My Zsh)
- **Bash** 4.0+

### Installation

```bash
# Navigate to your dotfiles repository
cd ~/dev/dotfiles

# Dry-run to preview changes
./install.sh --dry-run

# Full installation with automatic package installs
./install.sh --pkg-install yes --log ~/dotfiles-install.log

# Force reinstall (overwrites existing files after backup)
./install.sh --force --yes
```

### After Installation

```bash
# Reload your shell to pick up new configuration
exec zsh

# Reload Hyprland (if using Hyprland)
hyprctl reload

# Restart Kitty or open a new window for terminal updates
```

## Command-Line Flags

### install.sh

```
--dry-run              Show what would be done without making changes
--force                Overwrite existing files after creating backups
--yes                  Non-interactive mode; auto-confirm all prompts
--pkg-install yes|no   Whether to install missing system packages (default: no)
--target home|config|both
                       Stow target: home (~), config (~/.config), or both (default: home)
--log <file>           Append runtime logs to specified file
--help, -h             Show help message
```

### uninstall.sh

```
--dry-run              Show what would be done without making changes
--restore-last         Restore files from the most recent backup after unstowing
--yes                  Non-interactive mode; auto-confirm all prompts
--log <file>           Append runtime logs to specified file
--help, -h             Show help message
```

### test_install.sh

```
--verbose, -v          Show full output from dry-run test
--help, -h             Show help message
```

## Usage Examples

### Example 1: Safe initial install (dry-run first)

```bash
cd ~/dev/dotfiles

# Preview what will be done
./install.sh --dry-run --target both

# Execute the install
./install.sh --target both --pkg-install yes --log ~/install-$(date +%s).log
```

### Example 2: Reinstall with package updates

```bash
# Full reinstall, skipping prompts, with package manager updates
./install.sh --force --yes --pkg-install yes
```

### Example 3: Install specific target (home or config)

```bash
# Install only to home directory (~)
./install.sh --target home --dry-run

# Install only to config directory (~/.config)
./install.sh --target config --dry-run
```

### Example 4: Uninstall and restore last backup

```bash
# Preview uninstall
./uninstall.sh --dry-run

# Uninstall with backup restoration
./uninstall.sh --restore-last --yes
```

### Example 5: Test the installer

```bash
# Run smoke test
./test_install.sh

# Verbose output
./test_install.sh --verbose
```

## Backup & Recovery

### Backup Location

Backups are stored with timestamps in:
```
~/.local/share/dotfiles-backups/<YYYYMMDD_HHMMSS>/
```

Example:
```
~/.local/share/dotfiles-backups/20251118_143025/
├── .zshrc
├── .config/
│   ├── hypr/
│   ├── kitty/
│   └── starship.toml
└── ...
```

### Restore a Backup

```bash
# List available backups
ls -la ~/.local/share/dotfiles-backups/

# Manually restore a specific backup
cp -r ~/.local/share/dotfiles-backups/20251118_143025/* ~/

# Or use uninstall with restore
cd ~/dev/dotfiles && ./uninstall.sh --restore-last
```

## Features

### 1. Idempotent Installation

Running the installer multiple times is safe. It uses `stow -R` (restow) to refresh symlinks gracefully without creating duplicates.

```bash
./install.sh --yes
./install.sh --yes  # Safe to run again
```

### 2. Conflict Detection

If existing files would block stow, the installer:
1. Detects the conflict
2. Creates a backup in `~/.local/share/dotfiles-backups/<timestamp>/`
3. Proceeds only with confirmation (unless `--force` is used)

### 3. Oh My Zsh Setup

The installer automatically:
- Clones Oh My Zsh (if not present): `git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh`
- Installs recommended plugins:
  - `zsh-autosuggestions`
  - `zsh-syntax-highlighting`
- Ensures your `.zshrc` is stowed and sourced

If you have an existing `.zshrc`, it will be backed up before any changes.

### 4. Font Management

The installer checks for **JetBrains Mono Nerd Font** and can automatically install it:

```bash
# Check if font is installed
fc-list | grep -i jetbrains

# Install font (requires --pkg-install yes)
./install.sh --pkg-install yes
```

**Font Installation Details**:
- On Arch/AUR (with `paru` or `yay`): installs `nerd-fonts-jetbrains-mono`
- Runs `fc-cache -f` to rebuild font cache
- Other distros: install manually or copy `.ttf` files to `~/.local/share/fonts/`

### 5. Starship Prompt

The installer:
- Detects if Starship is installed
- Validates `~/.config/starship.toml` configuration
- Optionally installs Starship if `--pkg-install yes` is used

### 6. Package Manager Support

Auto-detects and uses:
- **paru** (AUR helper with pacman)
- **yay** (alternative AUR helper)
- **pacman** (Arch Linux)
- **apt** (Debian/Ubuntu)
- **dnf** (Fedora/RHEL)

## Safety & Best Practices

### Pre-Installation Checklist

- [ ] Backup existing dotfiles manually if needed
- [ ] Review the dry-run output: `./install.sh --dry-run`
- [ ] Ensure `stow` is installed: `pacman -S stow`
- [ ] Verify repository structure matches expected layout
- [ ] Test on a non-critical machine first (if possible)

### Post-Installation Checklist

- [ ] Verify symlinks: `ls -la ~/.config/hypr ~/.config/kitty ~/.zshrc`
- [ ] Check shell integration: `zsh -ic 'echo $ZSH'` (should show `~/.oh-my-zsh`)
- [ ] Test Starship: `starship module all`
- [ ] Reload your shell: `exec zsh`
- [ ] Review logs: `cat ~/dotfiles-install.log`

### Troubleshooting

#### Issue: "stow is not installed"

Solution:
```bash
paru -S stow
# or
pacman -S stow
```

#### Issue: "Conflict detected" during install

The installer will back up the conflicting file and prompt for confirmation. Options:
- Answer `y` to proceed (backup will be created)
- Answer `n` to skip this package
- Use `--force` to auto-proceed with backups

#### Issue: Symlinks not created

Check stow output:
```bash
cd ~/dev/dotfiles
stow -t ~ -n hypr  # Dry-run: shows what would be stowed
stow -t ~ hypr     # Actually stow
```

#### Issue: Oh My Zsh plugins not working

Verify plugins are installed:
```bash
ls ~/.oh-my-zsh/custom/plugins/
```

Add to your `.zshrc` if not already present:
```zsh
plugins=(zsh-autosuggestions zsh-syntax-highlighting git python)
```

#### Issue: Font not detected

```bash
# Rebuild font cache
fc-cache -f

# List available fonts
fc-list | grep -i jetbrains

# If still missing, install manually:
paru -S nerd-fonts-jetbrains-mono
```

## Uninstallation

To safely remove installed dotfiles:

```bash
cd ~/dev/dotfiles

# Dry-run first
./uninstall.sh --dry-run

# Execute uninstall
./uninstall.sh --yes

# Or, uninstall and restore previous backups
./uninstall.sh --restore-last --yes
```

The uninstaller uses `stow -D` (delete) to remove symlinks cleanly. Backups are preserved in `~/.local/share/dotfiles-backups/`.

## Logging

Enable logging for debugging and record-keeping:

```bash
# Log to a specific file
./install.sh --log ~/dotfiles-install-$(date +%Y%m%d_%H%M%S).log

# View logs
tail -f ~/dotfiles-install-20251118_143025.log

# Logs include timestamps, level (INFO/WARN/ERROR), and messages
```

Log format:
```
[2025-11-18 14:30:25] [INFO] Running preflight checks...
[2025-11-18 14:30:25] [SUCCESS] Not running as root
[2025-11-18 14:30:25] [INFO] Stowing package 'zshrc' to '/home/lucifer'...
```

## Advanced Configuration

### Custom Dotfiles Directory

```bash
# Use a different repo location
DOTFILES_DIR=/custom/path/to/dotfiles ./install.sh

# Or export the variable
export DOTFILES_DIR=/custom/path/to/dotfiles
./install.sh
```

### Custom Stow Target

```bash
# Stow to a different location (not typical, use --target flag)
STOW_TARGET=/custom/target ./install.sh
```

## Testing

Run the included smoke test to validate your repository:

```bash
./test_install.sh

# Expected output:
# - Checks repository structure
# - Validates package contents
# - Runs install.sh --dry-run
# - Reports any issues
```

## Contributing

When adding new packages to your dotfiles:

1. Create a new top-level directory: `mkdir mypackage`
2. Add config files following the structure:
   - `mypackage/.config/mypackage/` for XDG config files
   - `mypackage/.myfile` for dotfiles in home
   - `mypackage/bin/` for executable scripts
3. Test stow: `cd dotfiles && stow -n -t ~ mypackage`
4. Run the test script: `./test_install.sh`

## System Requirements

- **OS**: Arch Linux (primary), Debian/Ubuntu/Fedora (secondary)
- **Shell**: Bash 4.0+
- **Tools**: GNU Stow, Git
- **User**: Non-root (script refuses to run as root)

## Support & Debugging

### Enable Verbose Logging

```bash
# Run with full output and log file
bash -x ./install.sh --log ~/debug.log 2>&1 | tee ~/debug_output.log
```

### List Installed Packages

```bash
cd ~/dev/dotfiles
for pkg in */; do
  echo "Package: ${pkg%/}"
  stow -n -t ~ ${pkg%/}
done
```

### Verify Stow Behavior

```bash
# Dry-run all packages
stow -n -t ~ zshrc hypr kitty starship

# List what would be stowed
stow -n -t ~ zshrc | head -20
```

## License

These scripts are provided as-is for personal use. Adjust as needed for your system.

## Changelog

### v1.0 (2025-11-20)

- Initial release
- Comprehensive package detection
- Oh My Zsh automatic setup
- Font management
- Backup & restore functionality
- Dry-run mode
- Full logging support
- Idempotent operations
- Support for Arch/Debian/Fedora package managers
