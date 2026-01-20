#!/usr/bin/env bash
# Oh My Zsh + Powerlevel10k installation script (Linux only)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

source "$DOTFILES_DIR/lib/utils.sh"

# ============================================================================
# Configuration
# ============================================================================
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# Third-party plugins to install
PLUGINS=(
    "zsh-users/zsh-autosuggestions"
    "zsh-users/zsh-completions"
    "zsh-users/zsh-syntax-highlighting"
)

# ============================================================================
# Functions
# ============================================================================

install_zsh() {
    if is_command_exists zsh; then
        success "Zsh is already installed"
        return 0
    fi

    info "Installing Zsh..."
    if is_command_exists apt-get; then
        sudo apt-get update
        sudo apt-get install -y zsh
    elif is_command_exists dnf; then
        sudo dnf install -y zsh
    elif is_command_exists pacman; then
        sudo pacman -Sy --noconfirm zsh
    else
        error "Unsupported package manager. Please install zsh manually."
    fi
    success "Zsh installed"
}

install_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        success "Oh My Zsh is already installed"
        return 0
    fi

    info "Installing Oh My Zsh..."
    # Install Oh My Zsh without running zsh automatically
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    success "Oh My Zsh installed"
}

install_powerlevel10k() {
    local p10k_dir="$ZSH_CUSTOM/themes/powerlevel10k"

    if [ -d "$p10k_dir" ]; then
        success "Powerlevel10k is already installed"
        return 0
    fi

    info "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
    success "Powerlevel10k installed"
}

install_plugin() {
    local repo="$1"
    local plugin_name="${repo##*/}"
    local plugin_dir="$ZSH_CUSTOM/plugins/$plugin_name"

    if [ -d "$plugin_dir" ]; then
        success "Plugin $plugin_name is already installed"
        return 0
    fi

    info "Installing plugin: $plugin_name..."
    git clone --depth=1 "https://github.com/$repo.git" "$plugin_dir"
    success "Plugin $plugin_name installed"
}

install_plugins() {
    info "Installing third-party plugins..."
    for plugin in "${PLUGINS[@]}"; do
        install_plugin "$plugin"
    done
}

setup_symlinks() {
    info "Setting up Oh My Zsh configuration symlinks..."

    # Backup existing .zshrc if it's not a symlink
    if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
        local backup="$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        info "Backing up existing .zshrc to $backup"
        mv "$HOME/.zshrc" "$backup"
    fi

    # Remove existing symlink or OMZ default .zshrc
    if [ -L "$HOME/.zshrc" ] || [ -f "$HOME/.zshrc" ]; then
        rm -f "$HOME/.zshrc"
    fi

    # Create symlinks
    create_symlink "$DOTFILES_DIR/config/shell/zsh/.zshrc.omz" "$HOME/.zshrc"
    create_symlink "$DOTFILES_DIR/config/shell/zsh/.p10k.zsh" "$HOME/.p10k.zsh"

    success "Symlinks created"
}

set_default_shell() {
    if [ "$SHELL" = "$(which zsh)" ]; then
        success "Zsh is already the default shell"
        return 0
    fi

    info "Setting Zsh as default shell..."
    if chsh -s "$(which zsh)"; then
        success "Zsh set as default shell"
        warning "Please log out and log back in for the change to take effect"
    else
        warning "Failed to set zsh as default shell. Run manually: chsh -s \$(which zsh)"
    fi
}

# ============================================================================
# Main
# ============================================================================
main() {
    echo ""
    echo "======================================"
    echo "  Oh My Zsh + Powerlevel10k Setup"
    echo "======================================"
    echo ""

    # Check if running on Linux
    if [ "$(uname -s)" != "Linux" ]; then
        error "This script currently only supports Linux"
    fi

    install_zsh
    install_oh_my_zsh
    install_powerlevel10k
    install_plugins
    setup_symlinks
    set_default_shell

    echo ""
    echo "======================================"
    echo "  Installation Complete!"
    echo "======================================"
    echo ""
    echo "Please restart your terminal or run:"
    echo "  exec zsh"
    echo ""
    echo "If you see font issues, install a Nerd Font:"
    echo "  https://github.com/romkatv/powerlevel10k#fonts"
    echo ""
}

main "$@"
