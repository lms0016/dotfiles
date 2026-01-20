#!/usr/bin/env bash
# Symlink management script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

source "$DOTFILES_DIR/lib/utils.sh"

# ============================================================================
# Configuration
# ============================================================================
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# ============================================================================
# Symlink definitions
# ============================================================================

# Shell symlinks
setup_shell_bash() {
    info "Setting up Bash configuration..."
    create_symlink "$DOTFILES_DIR/config/shell/bash/.bashrc" "$HOME/.bashrc"
}

setup_shell_zsh() {
    info "Setting up Zsh configuration..."

    # Install zsh if not present
    if ! is_command_exists zsh; then
        warning "Zsh not found. Please install it first via 'make packages'"
        return 1
    fi

    create_symlink "$DOTFILES_DIR/config/shell/zsh/.zshrc" "$HOME/.zshrc"

    # Set zsh as default shell if not already
    if [ "$SHELL" != "$(which zsh)" ]; then
        info "Setting zsh as default shell..."
        chsh -s "$(which zsh)" || warning "Failed to set zsh as default shell. Run manually: chsh -s \$(which zsh)"
    fi
}

# Git symlinks
setup_git() {
    info "Setting up Git configuration..."
    create_symlink "$DOTFILES_DIR/config/git/.gitconfig" "$HOME/.gitconfig"

    if [ -f "$DOTFILES_DIR/config/git/.gitignore_global" ]; then
        create_symlink "$DOTFILES_DIR/config/git/.gitignore_global" "$HOME/.gitignore_global"
    fi
}

# Vim symlinks
setup_vim() {
    info "Setting up Vim configuration..."

    if [ -f "$DOTFILES_DIR/config/vim/.vimrc" ]; then
        create_symlink "$DOTFILES_DIR/config/vim/.vimrc" "$HOME/.vimrc"
    fi

    if [ -d "$DOTFILES_DIR/config/vim/.vim" ]; then
        create_symlink "$DOTFILES_DIR/config/vim/.vim" "$HOME/.vim"
    fi

    # Neovim support
    if [ -d "$DOTFILES_DIR/config/vim/nvim" ]; then
        mkdir -p "$HOME/.config"
        create_symlink "$DOTFILES_DIR/config/vim/nvim" "$HOME/.config/nvim"
    fi
}

# Tmux symlinks
setup_tmux() {
    info "Setting up Tmux configuration..."

    if [ -f "$DOTFILES_DIR/config/tmux/.tmux.conf" ]; then
        create_symlink "$DOTFILES_DIR/config/tmux/.tmux.conf" "$HOME/.tmux.conf"
    fi
}

# ============================================================================
# Backup function
# ============================================================================
backup_all() {
    info "Backing up existing dotfiles to $BACKUP_DIR..."
    mkdir -p "$BACKUP_DIR"

    local files=(
        "$HOME/.bashrc"
        "$HOME/.zshrc"
        "$HOME/.p10k.zsh"
        "$HOME/.gitconfig"
        "$HOME/.gitignore_global"
        "$HOME/.vimrc"
        "$HOME/.tmux.conf"
    )

    for file in "${files[@]}"; do
        if [ -e "$file" ] && [ ! -L "$file" ]; then
            cp "$file" "$BACKUP_DIR/" 2>/dev/null && \
                success "Backed up $(basename "$file")"
        fi
    done

    success "Backup complete: $BACKUP_DIR"
}

# ============================================================================
# Clean function
# ============================================================================
clean_symlinks() {
    info "Removing dotfiles symlinks..."

    local symlinks=(
        "$HOME/.bashrc"
        "$HOME/.zshrc"
        "$HOME/.p10k.zsh"
        "$HOME/.gitconfig"
        "$HOME/.gitignore_global"
        "$HOME/.vimrc"
        "$HOME/.vim"
        "$HOME/.config/nvim"
        "$HOME/.tmux.conf"
    )

    for link in "${symlinks[@]}"; do
        if [ -L "$link" ]; then
            rm "$link"
            success "Removed $link"
        fi
    done

    success "Cleanup complete"
}

# ============================================================================
# Setup all
# ============================================================================
setup_all() {
    info "Setting up all symlinks..."
    setup_shell_bash
    setup_git
    setup_vim
    setup_tmux
    success "All symlinks created"
}

# ============================================================================
# Main
# ============================================================================
main() {
    case "${1:-}" in
        --shell)
            case "${2:-}" in
                bash) setup_shell_bash ;;
                zsh)  setup_shell_zsh ;;
                *)    error "Usage: $0 --shell [bash|zsh]" ;;
            esac
            ;;
        --module)
            case "${2:-}" in
                git)   setup_git ;;
                vim)   setup_vim ;;
                tmux)  setup_tmux ;;
                *)     error "Usage: $0 --module [git|vim|tmux]" ;;
            esac
            ;;
        --all)
            setup_all
            ;;
        --backup)
            backup_all
            ;;
        --clean)
            clean_symlinks
            ;;
        *)
            echo "Usage: $0 [--shell bash|zsh] [--module git|vim|tmux] [--all] [--backup] [--clean]"
            exit 1
            ;;
    esac
}

main "$@"
