# Dotfiles Makefile
# Automatically detects OS and runs appropriate scripts

SHELL := /bin/bash
DOTFILES_DIR := $(shell pwd)
export DOTFILES_DIR

# OS Detection
UNAME_S := $(shell uname -s)
IS_WSL  := $(shell grep -qi microsoft /proc/version 2>/dev/null && echo 1 || echo 0)

ifeq ($(UNAME_S),Linux)
    ifeq ($(IS_WSL),1)
        OS_FAMILY := wsl
    else
        OS_FAMILY := linux
    endif
endif
ifeq ($(UNAME_S),Darwin)
    OS_FAMILY := macos
endif

# WSL uses Linux scripts for most targets
ifeq ($(OS_FAMILY),wsl)
    OS_FAMILY_BASE := linux
else
    OS_FAMILY_BASE := $(OS_FAMILY)
endif

# Default target
.PHONY: help
help:
	@echo "Dotfiles Installation"
	@echo "====================="
	@echo "Detected OS: $(OS_FAMILY)"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Main targets:"
	@echo "  install      - Full installation (all modules)"
	@echo "  tester       - Test machine setup (install without ai-agents, oh-my-zsh)"
	@echo "  ci-test      - CI test (non-interactive, for GitHub Actions)"
	@echo ""
	@echo "Individual targets:"
	@echo "  packages     - Install system packages only"
	@echo "  shell-zsh    - Setup zsh configuration"
	@echo "  shell-bash   - Setup bash configuration"
	@echo "  git          - Setup git configuration"
	@echo "  ssh          - Setup SSH multi-account (interactive)"
	@echo "  vim          - Setup vim configuration"
	@echo "  tmux         - Setup tmux + TPM (Tmux Plugin Manager)"
	@echo "  uv           - Install uv (Python package manager)"
	@echo "  nvm          - Install nvm and Node.js"
	@echo "  ai-agents    - Install AI CLI tools (Copilot, Codex, Gemini, Claude)"
	@echo "  oh-my-zsh    - Install Oh My Zsh + Powerlevel10k"
	@echo "  configs      - Install all configuration files"
	@echo ""
	@echo "Linux system setup (Ubuntu):"
	@echo "  ssh-server   - Setup SSH server (openssh-server)"
	@echo "  firewall     - Setup firewall (ufw)"
	@echo ""
	@echo "Utilities:"
	@echo "  backup       - Backup existing dotfiles"
	@echo "  list         - List available modules"

# ============================================================================
# Main Installation Targets
# ============================================================================
.PHONY: install
install: packages configs ssh-server firewall tmux uv nvm ai-agents oh-my-zsh ssh
	@echo ""
	@echo "✓ Installation complete!"
	@echo "  Please restart your shell or run: source ~/.bashrc (or ~/.zshrc)"

.PHONY: tester
tester: packages configs ssh-server firewall tmux uv nvm ssh
	@echo ""
	@echo "✓ Test machine setup complete!"
	@echo "  Please restart your shell or run: source ~/.bashrc (or ~/.zshrc)"

# CI test: non-interactive targets only (for GitHub Actions)
# Excludes: ssh (interactive), ai-agents (requires npm login), oh-my-zsh (changes shell)
.PHONY: ci-test
ci-test: packages configs tmux uv nvm
	@echo ""
	@echo "✓ CI test complete!"

# ============================================================================
# Package Installation
# ============================================================================
.PHONY: packages
packages:
ifeq ($(OS_FAMILY_BASE),linux)
	@bash scripts/linux/packages.sh
else ifeq ($(OS_FAMILY_BASE),macos)
	@bash scripts/macos/packages.sh
else
	@echo "Unsupported OS for package installation"
endif

# ============================================================================
# Shell Configuration
# ============================================================================
.PHONY: shell-zsh
shell-zsh: packages
	@bash scripts/common/configs.sh --shell zsh

.PHONY: shell-bash
shell-bash:
	@bash scripts/common/configs.sh --shell bash

# ============================================================================
# Application Configuration
# ============================================================================
.PHONY: git
git:
	@bash scripts/common/configs.sh --module git

.PHONY: ssh
ssh:
	@bash scripts/common/ssh.sh

.PHONY: vim
vim:
	@bash scripts/common/configs.sh --module vim

.PHONY: tmux
tmux: packages
	@bash scripts/common/tmux.sh

.PHONY: uv
uv:
	@bash scripts/common/uv.sh

.PHONY: nvm
nvm:
	@bash scripts/common/nvm.sh

.PHONY: ai-agents
ai-agents: nvm
	@bash scripts/common/ai-agents.sh

.PHONY: oh-my-zsh
oh-my-zsh: packages
	@bash scripts/common/oh-my-zsh.sh

.PHONY: configs
configs:
	@bash scripts/common/configs.sh --all

# ============================================================================
# Linux System Setup (Ubuntu)
# ============================================================================
.PHONY: ssh-server
ssh-server:
ifeq ($(OS_FAMILY_BASE),linux)
	@bash scripts/linux/ssh-server.sh
else
	@echo "ssh-server is only available on Linux"
endif

.PHONY: firewall
firewall:
ifeq ($(OS_FAMILY_BASE),linux)
	@bash scripts/linux/firewall.sh
else
	@echo "firewall is only available on Linux"
endif

# ============================================================================
# Utilities
# ============================================================================
.PHONY: backup
backup:
	@bash scripts/common/configs.sh --backup

.PHONY: list
list:
	@echo "Available modules:"
	@echo "  - shell (bash/zsh)"
	@echo "  - git"
	@echo "  - ssh"
	@echo "  - vim"
	@echo "  - tmux"
	@echo "  - uv"
	@echo "  - nvm"
	@echo "  - ai-agents"
	@echo "  - oh-my-zsh"
	@echo ""
	@echo "Linux system setup (Ubuntu):"
	@echo "  - ssh-server"
	@echo "  - firewall"
	@echo ""
	@echo "Package lists ($(OS_FAMILY)):"
	@ls -1 packages/$(OS_FAMILY_BASE)/*.txt 2>/dev/null || echo "  No package lists found"
