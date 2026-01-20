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
	@echo "  vim          - Setup vim configuration"
	@echo "  uv           - Install uv (Python package manager)"
	@echo "  symlinks     - Create all symlinks"
	@echo ""
	@echo "Utilities:"
	@echo "  backup       - Backup existing dotfiles"
	@echo "  clean        - Remove symlinks"
	@echo "  list         - List available modules"

# ============================================================================
# Main Installation Targets
# ============================================================================
.PHONY: install
install: packages symlinks
	@echo ""
	@echo "✓ Installation complete!"
	@echo "  Please restart your shell or run: source ~/.bashrc (or ~/.zshrc)"

.PHONY: dev
dev: packages shell-zsh git vim
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
shell-zsh:
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

.PHONY: vim
vim:
	@bash scripts/common/symlinks.sh --module vim

.PHONY: uv
uv:
	@bash scripts/common/uv.sh

.PHONY: symlinks
symlinks:
	@bash scripts/common/symlinks.sh --all

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
	@echo "  - vim"
	@echo "  - uv"
	@echo ""
	@echo "Package lists ($(OS)):"
	@ls -1 packages/$(OS_FAMILY)/*.txt 2>/dev/null || echo "  No package lists found"
