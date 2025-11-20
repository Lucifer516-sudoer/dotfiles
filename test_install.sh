#!/bin/bash
# test_install.sh - Smoke test for the dotfiles installer
# Runs a dry-run of install.sh and verifies planned actions are sound.
# Usage: ./test_install.sh [--verbose]

set -euo pipefail

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

VERBOSE=false
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dev/dotfiles}"
ERRORS=0
WARNINGS=0

# ============================================================================
# Test functions
# ============================================================================

test_info() {
    echo -e "${BLUE}[TEST]${NC} $*"
}

test_pass() {
    echo -e "${GREEN}[PASS]${NC} $*"
}

test_fail() {
    echo -e "${RED}[FAIL]${NC} $*"
    ((ERRORS++))
}

test_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
    ((WARNINGS++))
}

# ============================================================================
# Structural tests
# ============================================================================

test_repo_structure() {
    test_info "Checking repository structure..."
    
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        test_fail "Dotfiles directory not found: $DOTFILES_DIR"
        return
    fi
    test_pass "Dotfiles directory exists: $DOTFILES_DIR"
    
    # Check for required scripts
    if [[ ! -f "$DOTFILES_DIR/install.sh" ]]; then
        test_fail "install.sh not found"
    else
        test_pass "install.sh found"
    fi
    
    if [[ ! -f "$DOTFILES_DIR/uninstall.sh" ]]; then
        test_fail "uninstall.sh not found"
    else
        test_pass "uninstall.sh found"
    fi
    
    if [[ ! -f "$DOTFILES_DIR/README.md" ]]; then
        test_warn "README.md not found (recommended)"
    else
        test_pass "README.md found"
    fi
}

test_packages() {
    test_info "Checking for stow packages..."
    
    local packages=()
    while IFS= read -r -d '' pkg_dir; do
        local pkg_name
        pkg_name=$(basename "$pkg_dir")
        [[ "$pkg_name" == .* ]] && continue
        [[ ! -d "$pkg_dir" ]] && continue
        
        # Check for stow-relevant content
        if [[ -d "$pkg_dir/.config" ]] || [[ -d "$pkg_dir/bin" ]] || [[ -d "$pkg_dir/.local" ]] || \
           find "$pkg_dir" -maxdepth 1 -type f -name ".*" 2>/dev/null | grep -q .; then
            packages+=("$pkg_name")
        fi
    done < <(find "$DOTFILES_DIR" -maxdepth 1 -type d -print0 2>/dev/null | grep -zv "^\.$")
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        test_fail "No stow packages found"
    else
        test_pass "Found ${#packages[@]} packages: ${packages[*]}"
    fi
    
    # Verify specific expected packages
    local expected_packages=("zshrc" "hypr" "kitty" "starship")
    for pkg in "${expected_packages[@]}"; do
        if [[ -d "$DOTFILES_DIR/$pkg" ]]; then
            test_pass "Package '$pkg' found"
        else
            test_warn "Expected package '$pkg' not found (may be OK)"
        fi
    done
}

test_package_content() {
    test_info "Verifying package contents..."
    
    local issues=0
    
    # zshrc package
    if [[ -f "$DOTFILES_DIR/zshrc/.zshrc" ]]; then
        test_pass "zshrc/.zshrc found"
        if ! grep -q "oh-my-zsh" "$DOTFILES_DIR/zshrc/.zshrc"; then
            test_warn "zshrc/.zshrc does not reference oh-my-zsh"
        fi
    else
        test_fail "zshrc/.zshrc not found"
    fi
    
    # hypr config
    if [[ -d "$DOTFILES_DIR/hypr/.config/hypr" ]]; then
        test_pass "hypr/.config/hypr found"
        if [[ ! -f "$DOTFILES_DIR/hypr/.config/hypr/hyprland.conf" ]]; then
            test_warn "hyprland.conf not found in hypr/.config/hypr"
        fi
    else
        test_fail "hypr/.config/hypr directory not found"
    fi
    
    # kitty config
    if [[ -d "$DOTFILES_DIR/kitty/.config/kitty" ]]; then
        test_pass "kitty/.config/kitty found"
        if [[ ! -f "$DOTFILES_DIR/kitty/.config/kitty/kitty.conf" ]]; then
            test_warn "kitty.conf not found in kitty/.config/kitty"
        fi
    else
        test_fail "kitty/.config/kitty directory not found"
    fi
    
    # starship config
    if [[ -d "$DOTFILES_DIR/starship/.config" ]]; then
        test_pass "starship/.config found"
        if [[ ! -f "$DOTFILES_DIR/starship/.config/starship.toml" ]]; then
            test_warn "starship.toml not found in starship/.config"
        fi
    else
        test_fail "starship/.config directory not found"
    fi
}

# ============================================================================
# Script permission tests
# ============================================================================

test_script_permissions() {
    test_info "Checking script permissions..."
    
    for script in install.sh uninstall.sh test_install.sh; do
        if [[ -f "$DOTFILES_DIR/$script" ]]; then
            if [[ -x "$DOTFILES_DIR/$script" ]]; then
                test_pass "$script is executable"
            else
                test_warn "$script is not executable (run: chmod +x $script)"
            fi
        fi
    done
}

# ============================================================================
# Dry-run test
# ============================================================================

test_dry_run() {
    test_info "Running install.sh --dry-run..."
    
    local log_file="/tmp/test_install_dry_run_$$.log"
    
    if cd "$DOTFILES_DIR" && bash ./install.sh --dry-run --yes --log "$log_file" 2>&1 | tee /tmp/test_install_output_$$.log; then
        test_pass "install.sh --dry-run completed without errors"
        
        # Check output for expected content
        if grep -q "Packages to stow" /tmp/test_install_output_$$.log; then
            test_pass "Dry-run identified packages to stow"
        else
            test_warn "Dry-run output may be incomplete"
        fi
        
        if grep -q "stow -R" /tmp/test_install_output_$$.log; then
            test_pass "Dry-run showed stow commands"
        else
            test_warn "No stow commands shown in dry-run"
        fi
        
        if [[ "$VERBOSE" == true ]] && [[ -f "$log_file" ]]; then
            test_info "=== Dry-run log ==="
            cat "$log_file"
            test_info "=== End log ==="
        fi
    else
        test_fail "install.sh --dry-run failed"
    fi
    
    # Cleanup
    rm -f /tmp/test_install_output_$$.log "$log_file"
}

# ============================================================================
# Tool availability tests
# ============================================================================

test_required_tools() {
    test_info "Checking required tools..."
    
    local required_tools=("stow" "git" "bash")
    for tool in "${required_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            test_pass "$tool is available"
        else
            test_warn "$tool is not installed (required for install.sh)"
        fi
    done
    
    local optional_tools=("kitty" "zsh" "starship" "hyprctl" "fc-list")
    for tool in "${optional_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            test_pass "$tool is available (optional)"
        else
            test_warn "$tool is not installed (optional, but recommended)"
        fi
    done
}

# ============================================================================
# Help text test
# ============================================================================

test_help_text() {
    test_info "Checking help text..."
    
    cd "$DOTFILES_DIR" || return
    
    if bash ./install.sh --help 2>&1 | grep -q "Usage:"; then
        test_pass "install.sh --help shows usage"
    else
        test_fail "install.sh --help did not show usage"
    fi
    
    if bash ./uninstall.sh --help 2>&1 | grep -q "Usage:"; then
        test_pass "uninstall.sh --help shows usage"
    else
        test_fail "uninstall.sh --help did not show usage"
    fi
}

# ============================================================================
# Main test flow
# ============================================================================

main() {
    echo "========================================"
    echo "Dotfiles Installer - Smoke Test"
    echo "========================================"
    echo ""
    
    # Run all tests
    test_repo_structure
    echo ""
    
    test_packages
    echo ""
    
    test_package_content
    echo ""
    
    test_script_permissions
    echo ""
    
    test_required_tools
    echo ""
    
    test_help_text
    echo ""
    
    test_dry_run
    echo ""
    
    # Summary
    echo "========================================"
    echo "Test Summary"
    echo "========================================"
    echo -e "Errors:   ${RED}$ERRORS${NC}"
    echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
    echo ""
    
    if [[ $ERRORS -eq 0 ]]; then
        echo -e "${GREEN}All critical tests passed!${NC}"
        echo ""
        echo "Next steps:"
        echo "  1. Review the repository structure and package contents"
        echo "  2. Run install.sh to install dotfiles:"
        echo "     cd $DOTFILES_DIR && ./install.sh --dry-run"
        echo "  3. Then execute without --dry-run when ready"
        return 0
    else
        echo -e "${RED}Some tests failed. Review errors above.${NC}"
        return 1
    fi
}

# ============================================================================
# Argument parsing
# ============================================================================

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            cat << 'EOF'
Usage: ./test_install.sh [--verbose] [--help]

Smoke test for the dotfiles installer (install.sh). Verifies:
  - Repository structure
  - Package detection
  - Script permissions
  - Tool availability
  - Dry-run execution

OPTIONS:
  --verbose, -v    Show full output from dry-run
  --help, -h       Show this help message

EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run tests
main
