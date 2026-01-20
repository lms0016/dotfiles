#!/usr/bin/env bash
# Shared utility functions for dotfiles

# ============================================================================
# Colors
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# Logging functions
# ============================================================================
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ============================================================================
# OS Detection
# ============================================================================
detect_os() {
    case "$(uname -s)" in
        Linux*)
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                echo "$ID"
            else
                echo "linux"
            fi
            ;;
        Darwin*)
            echo "macos"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

detect_os_family() {
    case "$(uname -s)" in
        Linux*)   echo "linux" ;;
        Darwin*)  echo "macos" ;;
        CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
        *)        echo "unknown" ;;
    esac
}

# ============================================================================
# System checks
# ============================================================================
is_command_exists() {
    command -v "$1" &> /dev/null
}

is_root() {
    [ "$EUID" -eq 0 ]
}

require_sudo() {
    if ! is_root; then
        if ! is_command_exists sudo; then
            error "This script requires sudo privileges"
            exit 1
        fi
    fi
}

# ============================================================================
# File operations
# ============================================================================
backup_file() {
    local file="$1"
    local backup_dir="${2:-$HOME/.dotfiles_backup}"

    if [ -e "$file" ] && [ ! -L "$file" ]; then
        mkdir -p "$backup_dir"
        local backup_name="$(basename "$file").$(date +%Y%m%d_%H%M%S)"
        mv "$file" "$backup_dir/$backup_name"
        info "Backed up $file to $backup_dir/$backup_name"
    fi
}

copy_config() {
    local source="$1"
    local target="$2"

    if [ -L "$target" ]; then
        rm "$target"
    elif [ -e "$target" ]; then
        backup_file "$target"
    fi

    mkdir -p "$(dirname "$target")"
    cp "$source" "$target"
    success "Copied $source -> $target"
}

# ============================================================================
# Dotfiles path
# ============================================================================
get_dotfiles_dir() {
    # Get the directory where dotfiles are installed
    if [ -n "$DOTFILES_DIR" ]; then
        echo "$DOTFILES_DIR"
    else
        echo "$HOME/.dotfiles"
    fi
}
