#!/usr/bin/env bash
# Firewall Setup Script for Ubuntu
# Configures ufw with secure defaults

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

source "$DOTFILES_DIR/lib/utils.sh"

# ============================================================================
# Configuration
# ============================================================================
SSH_PORT=22

# ============================================================================
# Helper Functions
# ============================================================================

get_ssh_port() {
    # Try to detect current SSH port from sshd_config
    if [ -f /etc/ssh/sshd_config ]; then
        local port=$(grep -E "^Port\s+" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
        if [ -n "$port" ]; then
            echo "$port"
            return
        fi
    fi
    echo "22"
}

# ============================================================================
# Setup Functions
# ============================================================================

install_ufw() {
    info "Checking ufw..."

    if command -v ufw &> /dev/null; then
        success "ufw already installed"
    else
        info "Installing ufw..."
        sudo apt-get update
        sudo apt-get install -y ufw
        success "ufw installed"
    fi
}

configure_ufw() {
    info "Configuring firewall rules..."

    # Reset to defaults (without disabling)
    # sudo ufw --force reset

    # Set default policies
    sudo ufw default deny incoming
    success "Default policy: deny incoming"

    sudo ufw default allow outgoing
    success "Default policy: allow outgoing"

    # Allow SSH
    if [ "$SSH_PORT" = "22" ]; then
        sudo ufw allow ssh
        success "Allowed: SSH (port 22)"
    else
        sudo ufw allow "$SSH_PORT/tcp" comment 'SSH'
        success "Allowed: SSH (port $SSH_PORT)"
    fi
}

enable_ufw() {
    info "Enabling firewall..."

    # Check if already enabled
    if sudo ufw status | grep -q "Status: active"; then
        success "Firewall already active"
    else
        # Enable ufw (--force to skip confirmation)
        sudo ufw --force enable
        success "Firewall enabled"
    fi
}

show_status() {
    echo ""
    echo "======================================"
    echo "  Firewall Setup Complete!"
    echo "======================================"
    echo ""
    echo "Current firewall status:"
    echo ""
    sudo ufw status verbose
    echo ""
    echo "Useful commands:"
    echo "  ufw status              # Show current rules"
    echo "  ufw allow <port>        # Open a port"
    echo "  ufw deny <port>         # Block a port"
    echo "  ufw delete allow <port> # Remove a rule"
    echo "  ufw disable             # Disable firewall"
    echo ""
}

# ============================================================================
# Interactive Setup
# ============================================================================

interactive_setup() {
    echo ""
    echo "======================================"
    echo "  Firewall (ufw) Setup"
    echo "======================================"
    echo ""

    # Detect SSH port
    SSH_PORT=$(get_ssh_port)
    info "Detected SSH port: $SSH_PORT"

    echo ""
    echo "This will configure ufw with the following rules:"
    echo "  - Default: DENY incoming"
    echo "  - Default: ALLOW outgoing"
    echo "  - Allow: SSH (port $SSH_PORT)"
    echo ""

    read -p "Continue? [Y/n]: " confirm
    if [[ "$confirm" =~ ^[Nn] ]]; then
        info "Cancelled"
        exit 0
    fi

    echo ""
}

# ============================================================================
# Additional Rules
# ============================================================================

add_common_rules() {
    echo ""
    echo "Optional: Add common service rules"
    echo ""

    # HTTP/HTTPS
    read -p "Allow HTTP/HTTPS (ports 80, 443)? [y/N]: " allow_http
    if [[ "$allow_http" =~ ^[Yy] ]]; then
        sudo ufw allow http
        sudo ufw allow https
        success "Allowed: HTTP (80) and HTTPS (443)"
    fi

    # RDP (for remote desktop)
    read -p "Allow RDP (port 3389) for remote desktop? [y/N]: " allow_rdp
    if [[ "$allow_rdp" =~ ^[Yy] ]]; then
        sudo ufw allow 3389/tcp comment 'RDP'
        success "Allowed: RDP (port 3389)"
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    # Check for Ubuntu/Debian
    if ! command -v apt-get &> /dev/null; then
        error "This script requires apt-get (Ubuntu/Debian)"
        exit 1
    fi

    case "${1:-}" in
        --help|-h)
            echo "Usage: $0 [--defaults] [--with-rdp]"
            echo ""
            echo "Options:"
            echo "  --defaults    Use default settings (SSH only)"
            echo "  --with-rdp    Also allow RDP port 3389"
            echo "  --help        Show this help message"
            ;;
        --defaults)
            SSH_PORT=$(get_ssh_port)
            info "Using default settings (SSH port: $SSH_PORT)..."
            install_ufw
            configure_ufw
            enable_ufw
            show_status
            ;;
        --with-rdp)
            SSH_PORT=$(get_ssh_port)
            info "Setting up with RDP..."
            install_ufw
            configure_ufw
            sudo ufw allow 3389/tcp comment 'RDP'
            success "Allowed: RDP (port 3389)"
            enable_ufw
            show_status
            ;;
        *)
            interactive_setup
            install_ufw
            configure_ufw
            add_common_rules
            enable_ufw
            show_status
            ;;
    esac
}

main "$@"
