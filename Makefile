# Dotfiles Makefile
# Automatically detects OS and runs appropriate scripts

SHELL := /bin/bash
DOTFILES_DIR := $(shell pwd)
export DOTFILES_DIR

# OS Detection
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
    OS := linux
    OS_FAMILY := linux
endif
ifeq ($(UNAME_S),Darwin)
    OS := macos
    OS_FAMILY := macos
endif

# Default target
.PHONY: help
help:
	@echo "Dotfiles Installation"
	@echo "====================="
	@echo "Detected OS: $(OS)"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Main targets:"
	@echo "  install      - Full installation (packages + configs)"
	@echo "  dev          - Development machine setup (zsh + full tools)"
	@echo "  server       - Server/test machine setup (bash + basic tools)"
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
	@echo "  clean        - Remove installed configs"
	@echo "  list         - List available modules"

# ============================================================================
# Main Installation Targets
# ============================================================================
.PHONY: install
install: packages configs
	@echo ""
	@echo "✓ Installation complete!"
	@echo "  Please restart your shell or run: source ~/.bashrc (or ~/.zshrc)"

.PHONY: dev
dev: packages git vim
	@echo ""
	@read -p "Install Oh My Zsh + Powerlevel10k? [y/N] " answer; \
	if [ "$$answer" = "y" ] || [ "$$answer" = "Y" ]; then \
		$(MAKE) oh-my-zsh; \
	else \
		$(MAKE) shell-zsh; \
	fi
	@echo ""
	@echo "✓ Development machine setup complete!"
	@echo "  Please restart your shell or run: source ~/.zshrc"

.PHONY: server
server: packages-minimal shell-bash git
	@echo ""
	@echo "✓ Server setup complete!"
	@echo "  Please restart your shell or run: source ~/.bashrc"

# ============================================================================
# Package Installation
# ============================================================================
.PHONY: packages
packages:
ifeq ($(OS_FAMILY),linux)
	@bash scripts/linux/packages.sh
else ifeq ($(OS_FAMILY),macos)
	@bash scripts/macos/packages.sh
else
	@echo "Unsupported OS for package installation"
endif

.PHONY: packages-minimal
packages-minimal:
ifeq ($(OS_FAMILY),linux)
	@bash scripts/linux/packages.sh --minimal
else ifeq ($(OS_FAMILY),macos)
	@bash scripts/macos/packages.sh --minimal
else
	@echo "Unsupported OS for package installation"
endif

# ============================================================================
# Shell Configuration
# ============================================================================
.PHONY: shell-zsh
shell-zsh: packages
	@bash scripts/common/symlinks.sh --shell zsh

.PHONY: shell-bash
shell-bash:
	@bash scripts/common/symlinks.sh --shell bash

# ============================================================================
# Application Configuration
# ============================================================================
.PHONY: git
git:
	@bash scripts/common/symlinks.sh --module git

.PHONY: ssh
ssh:
	@bash scripts/common/ssh.sh

.PHONY: vim
vim:
	@bash scripts/common/symlinks.sh --module vim

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
	@bash scripts/common/symlinks.sh --all

# Alias for backward compatibility
.PHONY: symlinks
symlinks: configs

# ============================================================================
# Linux System Setup (Ubuntu)
# ============================================================================
.PHONY: ssh-server
ssh-server:
ifeq ($(OS_FAMILY),linux)
	@bash scripts/linux/ssh-server.sh
else
	@echo "ssh-server is only available on Linux"
endif

.PHONY: firewall
firewall:
ifeq ($(OS_FAMILY),linux)
	@bash scripts/linux/firewall.sh
else
	@echo "firewall is only available on Linux"
endif

# ============================================================================
# Utilities
# ============================================================================
.PHONY: backup
backup:
	@bash scripts/common/symlinks.sh --backup

.PHONY: clean
clean:
	@bash scripts/common/symlinks.sh --clean

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
	@echo "Package lists ($(OS)):"
	@ls -1 packages/$(OS_FAMILY)/*.txt 2>/dev/null || echo "  No package lists found"
