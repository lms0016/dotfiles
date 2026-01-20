#!/usr/bin/env bash
# Tmux + TPM (Tmux Plugin Manager) installation script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

source "$DOTFILES_DIR/lib/utils.sh"

# ============================================================================
# Configuration
# ============================================================================
TPM_DIR="$HOME/.tmux/plugins/tpm"

# ============================================================================
# Functions
# ============================================================================

check_tmux() {
    if ! is_command_exists tmux; then
        error "Tmux is not installed. Please install it first via 'make packages'"
        exit 1
    fi
    success "Tmux is installed: $(tmux -V)"
}

install_clipboard_tool() {
    info "Checking clipboard support..."

    # Linux: need xclip or xsel
    if [ "$(detect_os_family)" = "linux" ]; then
        if is_command_exists xclip; then
            success "xclip is already installed"
            return 0
        elif is_command_exists xsel; then
            success "xsel is already installed"
            return 0
        fi

        info "Installing xclip for clipboard support..."
        if is_command_exists apt-get; then
            sudo apt-get update
            sudo apt-get install -y xclip
        elif is_command_exists dnf; then
            sudo dnf install -y xclip
        elif is_command_exists pacman; then
            sudo pacman -Sy --noconfirm xclip
        else
            warning "Could not install xclip. Clipboard integration may not work."
            return 0
        fi
        success "xclip installed"
    fi

    # macOS: pbcopy/pbpaste are built-in
    if [ "$(detect_os_family)" = "macos" ]; then
        success "macOS clipboard (pbcopy/pbpaste) is built-in"
    fi
}

install_tpm() {
    if [ -d "$TPM_DIR" ]; then
        success "TPM is already installed"
        return 0
    fi

    info "Installing TPM (Tmux Plugin Manager)..."
    git clone --depth=1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
    success "TPM installed"
}

setup_config() {
    info "Setting up Tmux configuration..."

    local source="$DOTFILES_DIR/config/tmux/.tmux.conf"
    local target="$HOME/.tmux.conf"

    if [ ! -f "$source" ]; then
        error "Source config not found: $source"
        exit 1
    fi

    copy_config "$source" "$target"
}

install_plugins() {
    info "Installing Tmux plugins..."

    # Run TPM install script in background
    if [ -f "$TPM_DIR/bin/install_plugins" ]; then
        "$TPM_DIR/bin/install_plugins" || true
        success "Plugins installed"
    else
        warning "TPM install script not found. Please run 'prefix + I' inside tmux to install plugins."
    fi
}

# ============================================================================
# Main
# ============================================================================
main() {
    echo ""
    echo "======================================"
    echo "  Tmux + TPM Setup"
    echo "======================================"
    echo ""

    check_tmux
    install_clipboard_tool
    install_tpm
    setup_config
    install_plugins

    echo ""
    echo "======================================"
    echo "  Installation Complete!"
    echo "======================================"
    echo ""
    echo "If plugins weren't installed automatically, start tmux and press:"
    echo "  prefix + I  (Ctrl+b, then Shift+i)"
    echo ""
    echo "Useful keybindings:"
    echo "  prefix + |     Split vertically"
    echo "  prefix + -     Split horizontally"
    echo "  prefix + h/j/k/l  Navigate panes (vim-style)"
    echo "  prefix + F     Open fzf menu"
    echo "  prefix + r     Reload config"
    echo ""
}

main "$@"
