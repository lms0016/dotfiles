#!/usr/bin/env bash
# Package installation script for Linux (Ubuntu/Debian)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

source "$DOTFILES_DIR/lib/utils.sh"

# ============================================================================
# Configuration
# ============================================================================
PACKAGES_DIR="$DOTFILES_DIR/packages/linux"
MINIMAL_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --minimal) MINIMAL_MODE=true; shift ;;
        *) shift ;;
    esac
done

# ============================================================================
# Package installation functions
# ============================================================================

install_apt_packages() {
    local package_file="$PACKAGES_DIR/apt.txt"

    if [ ! -f "$package_file" ]; then
        warning "No apt package list found at $package_file"
        return 0
    fi

    info "Updating apt cache..."
    $SUDO apt-get update

    info "Installing apt packages..."

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

        if dpkg -l "$package" &> /dev/null; then
            success "$package (already installed)"
        else
            info "Installing $package..."
            $SUDO apt-get install -y "$package" && \
                success "$package" || \
                warning "Failed to install $package"
        fi
    done < "$package_file"
}

install_snap_packages() {
    local package_file="$PACKAGES_DIR/snap.txt"

    if [ ! -f "$package_file" ]; then
        return 0
    fi

    # Skip snap in minimal mode
    if $MINIMAL_MODE; then
        info "Skipping snap packages in minimal mode"
        return 0
    fi

    if ! is_command_exists snap; then
        warning "Snap is not installed, skipping snap packages"
        return 0
    fi

    info "Installing snap packages..."

    while IFS= read -r line || [ -n "$line" ]; do
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue

        # Parse package and flags (e.g., "code --classic")
        local package=$(echo "$line" | awk '{print $1}')
        local flags=$(echo "$line" | cut -d' ' -f2-)

        if [ "$package" = "$flags" ]; then
            flags=""
        fi

        if snap list "$package" &> /dev/null; then
            success "$package (already installed)"
        else
            info "Installing $package..."
            $SUDO snap install $package $flags && \
                success "$package" || \
                warning "Failed to install $package"
        fi
    done < "$package_file"
}

install_flatpak_packages() {
    local package_file="$PACKAGES_DIR/flatpak.txt"

    if [ ! -f "$package_file" ]; then
        return 0
    fi

    # Skip flatpak in minimal mode
    if $MINIMAL_MODE; then
        info "Skipping flatpak packages in minimal mode"
        return 0
    fi

    if ! is_command_exists flatpak; then
        warning "Flatpak is not installed, skipping flatpak packages"
        return 0
    fi

    info "Installing flatpak packages..."

    while IFS= read -r package || [ -n "$package" ]; do
        [[ "$package" =~ ^#.*$ || -z "$package" ]] && continue

        if flatpak list --app | grep -q "$package"; then
            success "$package (already installed)"
        else
            info "Installing $package..."
            flatpak install -y flathub "$package" && \
                success "$package" || \
                warning "Failed to install $package"
        fi
    done < "$package_file"
}

# ============================================================================
# Post-install setup
# ============================================================================

setup_package_aliases() {
    info "Setting up package aliases..."

    # Create ~/.local/bin if it doesn't exist
    mkdir -p "$HOME/.local/bin"

    # bat: Ubuntu/Debian installs as 'batcat', create symlink to 'bat'
    if is_command_exists batcat && [ ! -e "$HOME/.local/bin/bat" ]; then
        ln -s /usr/bin/batcat "$HOME/.local/bin/bat"
        success "Created symlink: bat -> batcat"
    elif [ -e "$HOME/.local/bin/bat" ]; then
        success "bat symlink already exists"
    fi
}

# ============================================================================
# Main
# ============================================================================
main() {
    echo ""
    echo "======================================"
    echo "  Package Installation (Linux)"
    if $MINIMAL_MODE; then
        echo "  Mode: Minimal"
    else
        echo "  Mode: Full"
    fi
    echo "======================================"
    echo ""

    install_apt_packages
    install_snap_packages
    install_flatpak_packages
    setup_package_aliases

    echo ""
    success "Package installation complete!"
}

main "$@"
