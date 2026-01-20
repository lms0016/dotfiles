#!/usr/bin/env bash
# Common shell functions (shared between bash and zsh)

# ============================================================================
# Directory operations
# ============================================================================

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.tar.xz)    tar xJf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# ============================================================================
# Search
# ============================================================================

# Find file by name
ff() {
    find . -type f -iname "*$1*"
}

# Find directory by name
fd() {
    find . -type d -iname "*$1*"
}

# ============================================================================
# Process management
# ============================================================================

# Find process by name
psg() {
    ps aux | grep -v grep | grep -i "$1"
}

# ============================================================================
# Network
# ============================================================================

# Get public IP
myip() {
    curl -s https://ipinfo.io/ip
    echo ""
}

# Get local IP
localip() {
    hostname -I | awk '{print $1}'
}

# ============================================================================
# Development
# ============================================================================

# Quick HTTP server
serve() {
    local port="${1:-8000}"
    python3 -m http.server "$port"
}

# ============================================================================
# Add your custom functions below
# ============================================================================
