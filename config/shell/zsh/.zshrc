#!/usr/bin/env zsh
# Zsh configuration file

# ============================================================================
# Basic settings
# ============================================================================

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=20000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt APPEND_HISTORY

# Directory navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS

# Completion
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END

# ============================================================================
# Completion system
# ============================================================================
autoload -Uz compinit
compinit

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Menu selection
zstyle ':completion:*' menu select

# ============================================================================
# Prompt
# ============================================================================
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'

setopt PROMPT_SUBST
PROMPT='%F{green}%n@%m%f:%F{blue}%~%f%F{yellow}${vcs_info_msg_0_}%f$ '

# ============================================================================
# Dotfiles configuration
# ============================================================================
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
export DOTFILES_DIR

# Load common aliases
if [ -f "$DOTFILES_DIR/config/shell/common/aliases.sh" ]; then
    source "$DOTFILES_DIR/config/shell/common/aliases.sh"
fi

# Load common functions
if [ -f "$DOTFILES_DIR/config/shell/common/functions.sh" ]; then
    source "$DOTFILES_DIR/config/shell/common/functions.sh"
fi

# ============================================================================
# Key bindings
# ============================================================================
bindkey -e  # Emacs key bindings
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# ============================================================================
# Plugins (optional - add your preferred plugin manager here)
# ============================================================================
# Example with zinit:
# source "$HOME/.zinit/bin/zinit.zsh"
# zinit light zsh-users/zsh-autosuggestions
# zinit light zsh-users/zsh-syntax-highlighting

# ============================================================================
# Local configuration (machine-specific, not in git)
# ============================================================================
if [ -f "$HOME/.zshrc.local" ]; then
    source "$HOME/.zshrc.local"
fi
