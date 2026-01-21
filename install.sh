#!/usr/bin/env bash
# Bootstrap script for dotfiles
# This script sets up the basic requirements and then hands off to make

set -e

# ============================================================================
# Configuration
# ============================================================================
# Detect the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"

# ============================================================================
# Colors
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ============================================================================
# OS Detection
# ============================================================================
detect_os() {
    case "$(uname -s)" in
        Linux*)   echo "linux" ;;
        Darwin*)  echo "macos" ;;
        *)        echo "unknown" ;;
    esac
}

OS=$(detect_os)
info "Detected OS: $OS"

# ============================================================================
# Install basic dependencies
# ============================================================================
install_dependencies_linux() {
    info "Installing basic dependencies (Linux)..."

    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y git make curl
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y git make curl
    elif command -v pacman &> /dev/null; then
        sudo pacman -Sy --noconfirm git make curl
    else
        error "Unsupported Linux distribution"
    fi

    success "Basic dependencies installed"
}

install_dependencies_macos() {
    info "Installing basic dependencies (macOS)..."

    # Install Xcode Command Line Tools if not present
    if ! xcode-select -p &> /dev/null; then
        info "Installing Xcode Command Line Tools..."
        xcode-select --install
        # Wait for installation
        until xcode-select -p &> /dev/null; do
            sleep 5
        done
    fi

    # Install Homebrew if not present
    if ! command -v brew &> /dev/null; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    success "Basic dependencies installed"
}

# ============================================================================
# Main
# ============================================================================
main() {
    echo ""
    echo "======================================"
    echo "  Dotfiles Bootstrap Script"
    echo "======================================"
    echo ""

    # Install basic dependencies based on OS
    case "$OS" in
        linux)  install_dependencies_linux ;;
        macos)  install_dependencies_macos ;;
        *)      error "Unsupported operating system" ;;
    esac

    # Change to dotfiles directory
    cd "$DOTFILES_DIR"
    info "Using dotfiles from: $DOTFILES_DIR"

    echo ""
    echo "======================================"
    echo "  Bootstrap complete!"
    echo "======================================"
    echo ""
    echo "Next steps:"
    echo "  cd $DOTFILES_DIR"
    echo ""
    echo "Then run one of:"
    echo "  make install     # Full installation"
    echo "  make dev         # Development machine (zsh)"
    echo "  make server      # Server/test machine (bash)"
    echo ""
    echo "Or run 'make help' to see all options"
    echo ""
}

main "$@"
