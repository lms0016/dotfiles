#!/usr/bin/env bash
# Bash configuration file

# ============================================================================
# Basic settings
# ============================================================================

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History settings
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend

# Check window size after each command
shopt -s checkwinsize

# Enable ** glob pattern
shopt -s globstar 2>/dev/null

# ============================================================================
# Prompt
# ============================================================================

# Color definitions
if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='\u@\h:\w\$ '
fi

# ============================================================================
# Dotfiles configuration
# ============================================================================
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

# Load common aliases
if [ -f "$DOTFILES_DIR/config/shell/common/aliases.sh" ]; then
    source "$DOTFILES_DIR/config/shell/common/aliases.sh"
fi

# Load common functions
if [ -f "$DOTFILES_DIR/config/shell/common/functions.sh" ]; then
    source "$DOTFILES_DIR/config/shell/common/functions.sh"
fi

# ============================================================================
# Completion
# ============================================================================

# Enable programmable completion
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        source /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        source /etc/bash_completion
    fi
fi

# ============================================================================
# Local configuration (machine-specific, not in git)
# ============================================================================
if [ -f "$HOME/.bashrc.local" ]; then
    source "$HOME/.bashrc.local"
fi
