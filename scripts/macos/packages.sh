#!/usr/bin/env bash
# Package installation script for macOS

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

source "$DOTFILES_DIR/lib/utils.sh"

# ============================================================================
# Configuration
# ============================================================================
PACKAGES_DIR="$DOTFILES_DIR/packages/macos"
MINIMAL_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --minimal) MINIMAL_MODE=true; shift ;;
        *) shift ;;
    esac
done

# ============================================================================
# Homebrew installation
# ============================================================================

install_homebrew() {
    if is_command_exists brew; then
        success "Homebrew is already installed"
        return 0
    fi

    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon Macs
    if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    if is_command_exists brew; then
        success "Homebrew installed successfully"
    else
        error "Failed to install Homebrew"
        exit 1
    fi
}

# ============================================================================
# Package installation functions
# ============================================================================

install_brew_packages() {
    local package_file="$PACKAGES_DIR/brew.txt"

    if [ ! -f "$package_file" ]; then
        warning "No brew package list found at $package_file"
        return 0
    fi

    info "Updating Homebrew..."
    brew update

    info "Installing Homebrew packages..."

    # Read packages, skip comments and empty lines
    while IFS= read -r package || [ -n "$package" ]; do
        # Skip comments and empty lines
        [[ "$package" =~ ^#.*$ || -z "$package" ]] && continue

        # In minimal mode, skip packages marked with [full]
        if $MINIMAL_MODE && [[ "$package" =~ \[full\]$ ]]; then
            continue
        fi

        # Remove tags like [full] from package name
        package=$(echo "$package" | sed 's/\[.*\]//g' | xargs)

        if brew list "$package" &> /dev/null; then
            success "$package (already installed)"
        else
            info "Installing $package..."
            brew install "$package" < /dev/null && \
                success "$package" || \
                warning "Failed to install $package"
        fi
    done < "$package_file"
}

install_cask_packages() {
    local package_file="$PACKAGES_DIR/cask.txt"

    if [ ! -f "$package_file" ]; then
        return 0
    fi

    # Skip cask in minimal mode
    if $MINIMAL_MODE; then
        info "Skipping cask packages in minimal mode"
        return 0
    fi

    info "Installing Homebrew Cask packages..."

    while IFS= read -r package || [ -n "$package" ]; do
        [[ "$package" =~ ^#.*$ || -z "$package" ]] && continue

        if brew list --cask "$package" &> /dev/null; then
            success "$package (already installed)"
        else
            info "Installing $package..."
            brew install --cask "$package" < /dev/null && \
                success "$package" || \
                warning "Failed to install $package"
        fi
    done < "$package_file"
}

# ============================================================================
# Main
# ============================================================================
main() {
    echo ""
    echo "======================================"
    echo "  Package Installation (macOS)"
    if $MINIMAL_MODE; then
        echo "  Mode: Minimal"
    else
        echo "  Mode: Full"
    fi
    echo "======================================"
    echo ""

    install_homebrew
    install_brew_packages
    install_cask_packages

    echo ""
    success "Package installation complete!"
}

main "$@"
