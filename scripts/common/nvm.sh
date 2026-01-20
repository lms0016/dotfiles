#!/usr/bin/env bash
# nvm installation script (Node Version Manager)
# https://github.com/nvm-sh/nvm
#
# Supports: Linux, macOS

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

source "$DOTFILES_DIR/lib/utils.sh"

# ============================================================================
# Configuration
# ============================================================================
NODE_VERSION="22"

# ============================================================================
# nvm Installation
# ============================================================================

install_nvm() {
    echo ""
    echo "======================================"
    echo "  nvm Installation"
    echo "======================================"
    echo ""

    # Check if nvm is already installed
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        source "$NVM_DIR/nvm.sh"
        local current_version
        current_version=$(nvm --version 2>/dev/null)
        success "nvm is already installed (version: $current_version)"
    else
        info "Installing nvm..."

        # Get latest version from GitHub API
        local latest_version
        latest_version=$(curl -s "https://api.github.com/repos/nvm-sh/nvm/releases/latest" | grep -Po '"tag_name": "\K[^"]*' || echo "v0.40.1")

        info "Latest nvm version: $latest_version"

        # Install nvm
        curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${latest_version}/install.sh" | bash

        # Load nvm for current session
        export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
        [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

        if [ -s "$NVM_DIR/nvm.sh" ]; then
            local installed_version
            installed_version=$(nvm --version 2>/dev/null)
            success "nvm installed successfully (version: $installed_version)"
        else
            error "nvm installation failed"
            exit 1
        fi
    fi
}

install_node() {
    echo ""
    echo "======================================"
    echo "  Node.js Installation"
    echo "======================================"
    echo ""

    # Ensure nvm is loaded
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

    info "Installing Node.js ${NODE_VERSION}..."
    nvm install "$NODE_VERSION"

    info "Setting Node.js ${NODE_VERSION} as default..."
    nvm use "$NODE_VERSION"
    nvm alias default "$NODE_VERSION"

    local node_version
    node_version=$(node -v 2>/dev/null)
    success "Node.js installed: $node_version"
}

update_npm() {
    echo ""
    echo "======================================"
    echo "  npm Update"
    echo "======================================"
    echo ""

    info "Updating npm to latest version..."
    npm install -g npm@latest

    local npm_version
    npm_version=$(npm -v 2>/dev/null)
    success "npm updated: $npm_version"
}

# ============================================================================
# Main
# ============================================================================

main() {
    local os_family
    os_family=$(detect_os_family)

    if [[ "$os_family" != "linux" && "$os_family" != "macos" ]]; then
        error "This script only supports Linux and macOS"
        error "For Windows, use nvm-windows: https://github.com/coreybutler/nvm-windows"
        exit 1
    fi

    install_nvm
    install_node
    update_npm

    echo ""
    echo "======================================"
    echo "  Installation Complete"
    echo "======================================"
    echo ""
    success "nvm, Node.js ${NODE_VERSION}, and npm are ready!"
    info "Please restart your shell or run:"
    info "  source ~/.bashrc  (for bash)"
    info "  source ~/.zshrc   (for zsh)"
}

main "$@"
