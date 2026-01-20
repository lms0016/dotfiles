#!/usr/bin/env bash
# AI Agents CLI tools installation script
# Installs: GitHub Copilot CLI, OpenAI Codex, Google Gemini CLI, Claude Code
#
# Supports: Linux, macOS

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

source "$DOTFILES_DIR/lib/utils.sh"

# ============================================================================
# Configuration
# ============================================================================
NPM_PACKAGES=(
    "@github/copilot"
    "@openai/codex"
    "@google/gemini-cli"
)

# Track installation results
declare -A INSTALL_RESULTS

# ============================================================================
# Helper Functions
# ============================================================================

check_npm() {
    if ! is_command_exists npm; then
        error "npm is not installed"
        info "Please run 'make nvm' first to install Node.js and npm"
        exit 1
    fi
    success "npm found: $(npm -v)"
}

install_npm_package() {
    local package="$1"
    local package_name="${package##*/}"  # Get name after last /

    info "Installing $package..."

    if npm install -g "$package" 2>/dev/null; then
        INSTALL_RESULTS["$package"]="success"
        success "$package installed"
    else
        INSTALL_RESULTS["$package"]="failed"
        warning "Failed to install $package"
    fi
}

install_claude_code() {
    echo ""
    echo "======================================"
    echo "  Claude Code Installation"
    echo "======================================"
    echo ""

    if is_command_exists claude; then
        local current_version
        current_version=$(claude --version 2>/dev/null || echo "unknown")
        success "Claude Code is already installed (version: $current_version)"
        INSTALL_RESULTS["claude-code"]="success"
        return
    fi

    info "Installing Claude Code..."

    if curl -fsSL https://claude.ai/install.sh | bash; then
        INSTALL_RESULTS["claude-code"]="success"
        success "Claude Code installed"
    else
        INSTALL_RESULTS["claude-code"]="failed"
        warning "Failed to install Claude Code"
    fi
}

print_summary() {
    echo ""
    echo "======================================"
    echo "  Installation Summary"
    echo "======================================"
    echo ""

    local success_count=0
    local fail_count=0

    for package in "${!INSTALL_RESULTS[@]}"; do
        if [ "${INSTALL_RESULTS[$package]}" = "success" ]; then
            success "$package"
            ((success_count++))
        else
            error "$package"
            ((fail_count++))
        fi
    done

    echo ""
    if [ $fail_count -eq 0 ]; then
        success "All AI agents installed successfully!"
    else
        warning "$success_count succeeded, $fail_count failed"
    fi
}

# ============================================================================
# Main Installation
# ============================================================================

install_npm_packages() {
    echo ""
    echo "======================================"
    echo "  npm Global Packages Installation"
    echo "======================================"
    echo ""

    for package in "${NPM_PACKAGES[@]}"; do
        install_npm_package "$package"
    done
}

# ============================================================================
# Main
# ============================================================================

main() {
    local os_family
    os_family=$(detect_os_family)

    if [[ "$os_family" != "linux" && "$os_family" != "macos" ]]; then
        error "This script only supports Linux and macOS"
        exit 1
    fi

    echo ""
    echo "======================================"
    echo "  AI Agents Installation"
    echo "======================================"
    echo ""

    check_npm
    install_npm_packages
    install_claude_code
    print_summary

    echo ""
    info "You may need to restart your shell or run:"
    info "  source ~/.bashrc  (for bash)"
    info "  source ~/.zshrc   (for zsh)"
}

main "$@"
