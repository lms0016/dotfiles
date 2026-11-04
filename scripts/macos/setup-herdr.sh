#!/usr/bin/env bash
# macOS Herdr setup script
# Deploys the custom mods and layout from dotfiles.
#
# Only files listed under config/herdr/{mods,layouts} are written. Shipped mods,
# settings.json and keys.json belong to the app and to the person, and are left alone.
# The Herdr Admin launcher is Windows-only: it exists to run elevated.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Always this checkout: an inherited DOTFILES_DIR may point at another clone or none.
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$DOTFILES_DIR/lib/utils.sh"

# ============================================================================
# Configuration
# ============================================================================
SOURCE_DIR="$DOTFILES_DIR/config/herdr"
# Herdr itself reads HERDR_APP_HOME, so this follows the same override.
APP_HOME="${HERDR_APP_HOME:-$HOME/.config/herdr-app}"
BACKUP_DIR="$HOME/.dotfiles_backup/herdr"

# ============================================================================
# Functions
# ============================================================================

is_herdr_installed() {
    [ -d "$HOME/Applications/Herdr.app" ] || [ -d "/Applications/Herdr.app" ]
}

# Copies one file, keeping a timestamped backup when it would overwrite different content.
copy_with_backup() {
    local relative="$1"
    local source="$SOURCE_DIR/$relative"
    local target="$APP_HOME/$relative"

    if [ -e "$target" ]; then
        cmp -s "$source" "$target" && return 0
        local backup="$BACKUP_DIR/$relative.$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$(dirname "$backup")"
        cp "$target" "$backup"
        info "Backed up: $backup"
    fi

    mkdir -p "$(dirname "$target")"
    cp "$source" "$target"
    success "Installed: $target"
}

# ============================================================================
# Main
# ============================================================================

if ! is_herdr_installed; then
    warning "Herdr app is not installed, skipping"
    exit 0
fi

info "Deploying mods and layout to $APP_HOME..."

# Process substitution rather than a pipe, so `set -e` still stops on a failed copy.
while IFS= read -r -d '' file; do
    copy_with_backup "${file#"$SOURCE_DIR"/}"
done < <(find "$SOURCE_DIR/mods" "$SOURCE_DIR/layouts" -type f -print0)

success "Herdr mods and layout are up to date"
info "Next: in Herdr, press Cmd+Shift+L until the My Main layout shows"
