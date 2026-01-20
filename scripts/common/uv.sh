#!/usr/bin/env bash
# uv installation script (Python package manager)
# https://docs.astral.sh/uv/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

source "$DOTFILES_DIR/lib/utils.sh"

# ============================================================================
# uv Installation
# ============================================================================

install_uv() {
    echo ""
    echo "======================================"
    echo "  uv Installation"
    echo "======================================"
    echo ""

    if is_command_exists uv; then
        local current_version
        current_version=$(uv -V 2>/dev/null | awk '{print $2}')
        success "uv is already installed (version: $current_version)"
        info "To upgrade, run: uv self update"
        return 0
    fi

    info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh

    # Source the shell config to update PATH
    if [ -f "$HOME/.local/bin/env" ]; then
        source "$HOME/.local/bin/env"
    fi

    if is_command_exists uv; then
        local installed_version
        installed_version=$(uv -V 2>/dev/null | awk '{print $2}')
        success "uv installed successfully (version: $installed_version)"
    else
        warning "uv installed but not in PATH. Please restart your shell or add ~/.local/bin to PATH"
    fi
}

# ============================================================================
# Main
# ============================================================================

install_uv
