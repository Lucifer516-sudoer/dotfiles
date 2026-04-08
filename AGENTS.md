# AGENTS.md — Dotfiles Repository
> Steering file for you. YES you.
## Overview
Personal dotfiles for an Arch Linux system, managed with GNU Stow and version-controlled on GitHub.
Shell: zsh. Package manager: pacman (+ yay/paru for AUR).

---

## Repository Structure

```
dotfiles/
├── zsh/
│   └── .zshrc, .zprofile, .zshenv, .zsh_aliases
├── git/
│   └── .gitconfig, .gitignore_global
├── nvim/                        # or vim/
│   └── .config/nvim/
├── tmux/
│   └── .tmux.conf
├── scripts/
│   └── any utility scripts
├── .stow-global-ignore          # patterns stow should never symlink
└── AGENTS.md
```

Each top-level directory is a **stow package**.
Stow is run from the repo root: `stow <package>` — it symlinks contents into `$HOME`.

---

## How Stow Works Here

```bash
# Symlink zsh configs into $HOME
stow zsh

# Remove symlinks
stow -D zsh

# Simulate (dry run) — always do this first
stow --simulate zsh
```

The directory structure inside each package **mirrors** the target.
Example: `zsh/.zshrc` → symlinked to `~/.zshrc`
Example: `nvim/.config/nvim/init.lua` → symlinked to `~/.config/nvim/init.lua`

---

## Core Rules for Agents

### 1. Always Simulate Before Stowing
Never run `stow <pkg>` directly. Always run `stow --simulate <pkg>` first
and confirm there are no conflicts before proceeding.

### 2. Respect Stow Package Boundaries
Each top-level directory is one stow package. Do not place files from one
concern (e.g., git config) inside another package's folder (e.g., zsh/).

### 3. No Hardcoded Paths
Use `$HOME`, `$XDG_CONFIG_HOME`, or `$ZDOTDIR` — never `/home/harish`.

### 4. zsh-Specific Awareness
- Load order: `.zshenv` → `.zprofile` → `.zshrc` → `.zlogin`
- `.zshenv` is sourced for ALL zsh sessions (including scripts) — keep it minimal
- `.zshrc` is for interactive shells only — aliases, prompt, completions go here
- Do not add heavy logic or slow commands to `.zshenv`

### 5. Arch Linux Awareness
- Do not run `pacman`, `yay`, or `paru` autonomously
- Do not assume any AUR helper is present — suggest both `yay` and `paru` variants
- Systemd is the init system — use `systemctl --user` for user services
- XDG base dirs are standard on Arch; prefer `~/.config/` over `~/` where possible

### 6. Secret Hygiene
- Never write tokens, SSH keys, or passwords into tracked files
- Use a `.secrets` or `.env.local` file that is listed in `.gitignore`
- Stubs are acceptable: `# export GITHUB_TOKEN=your_token_here`
- Verify `.stow-global-ignore` excludes sensitive files before any commit

### 7. GitHub Hygiene
- Do not commit machine-specific state (hostname, IP, hardware IDs)
- The repo should be safely cloneable on any Arch machine without breakage
- Keep a `README.md` updated if agent adds a new stow package

---

## What Agents Are Allowed To Do

- Add or modify files within existing stow packages
- Create new stow packages for new tools (e.g., `alacritty/`, `starship/`)
- Add aliases or exports to `zsh/.zshrc` or `zsh/.zsh_aliases`
- Update `.stow-global-ignore` to exclude new junk patterns
- Improve inline comments in any config file
- Suggest pacman/AUR install commands (never run them)

## What Agents Must NOT Do

- Run `stow` without `--simulate` first
- Delete or restructure existing stow packages without explicit instruction
- Modify `.git/` in any way
- Commit anything containing credentials, tokens, or machine-specific secrets
- Run `pacman`, `yay`, or `paru`
- Rewrite `.zshenv` in a way that adds latency to all zsh sessions

---

## Validating Changes

### Syntax check zsh files before committing:
```bash
zsh -n zsh/.zshrc
zsh -n zsh/.zshenv
```

### Dry-run stow before applying:
```bash
stow --simulate <package>
```

### Check for broken symlinks in $HOME:
```bash
find ~ -maxdepth 3 -type l ! -exec test -e {} \; -print
```

---

## Commit Style

Follow conventional commits:
```
feat(zsh): add fzf tab completion plugin
fix(git): correct GPG signing key reference  
chore(stow): add alacritty as new stow package
docs(readme): document new tmux keybindings
```

---

## Bootstrap on a Fresh Arch Install

```bash
git clone https://github.com/<your-username>/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow --simulate zsh git nvim tmux   # dry run first
stow zsh git nvim tmux              # apply
```

---

## Notes for AI Agents

- This is a live environment repo — a bad change can break the user's shell on next login
- Always prefer additive changes; avoid editing existing blocks unless specifically asked
- If restructuring is needed, discuss first — stow package layout is deliberate
- When adding a new tool's config, create a proper stow package, not a loose file
- `zsh` is the only shell — no bash compatibility shims needed
