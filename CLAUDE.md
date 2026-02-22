# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cross-platform dotfiles manager supporting macOS, Ubuntu/Linux, Windows (PowerShell), and WSL2. Uses Bash scripts + Make for automated installation of system packages, shell configs, and dev tools.

## Key Commands

```bash
# Full installation
./install.sh          # Bootstrap (installs git/make/curl, clones repo)
make install          # Run all modules

# Individual modules
make packages         # System packages (apt/brew based on OS)
make configs          # Copy all config files to ~
make shell-bash       # Bash config only
make shell-zsh        # Zsh + Oh My Zsh config
make git              # Git config
make ssh              # SSH multi-account setup (interactive)
make vim              # Vim config
make tmux             # Tmux + TPM plugins
make uv               # Python package manager
make nvm              # Node.js version manager
make ai-agents        # AI CLI tools (requires nvm first)
make oh-my-zsh        # Oh My Zsh + Powerlevel10k
make shell-pwsh       # PowerShell (Windows/Git Bash only)

# Linux-only
make ssh-server       # OpenSSH server setup
make firewall         # UFW firewall

# Testing
make ci-test          # Non-interactive CI test (used by GitHub Actions)
make tester           # Test machine setup (skips ai-agents, oh-my-zsh)
```

## Architecture

### Config deployment strategy

Configs are **copied** (not symlinked) from `config/` to `~` via `copy_config()` in `lib/utils.sh`. Existing files are backed up to `~/.dotfiles_backup/` before overwriting.

### Module pattern

Each module follows:

1. **Package list** in `packages/<os>/` — plain text, one per line, `[full]` tag for dev-only packages
2. **Config files** in `config/<app>/` — dotfiles to copy to home directory
3. **Install script** in `scripts/common/` or `scripts/<os>/` — installation logic
4. **Makefile target** — wired up with dependencies (e.g., `ai-agents` depends on `nvm`)

### Platform detection

- `Makefile`: uses `uname -s` to set `OS_FAMILY` (linux/macos), empty on Windows
- `lib/utils.sh`: `detect_os()` returns distro ID, `detect_os_family()` returns linux/macos/windows
- Windows targets check `OS_FAMILY` is empty (running from Git Bash/MSYS2)

### Shell config layering

- `config/shell/common/` — aliases and functions shared across bash/zsh
- `config/shell/bash/` and `config/shell/zsh/` — shell-specific configs
- `~/.bashrc.local` / `~/.zshrc.local` — machine-specific overrides (gitignored)

### Git multi-account

Uses `includeIf` for directory-based identity switching and `url.insteadOf` for SSH host rewriting (e.g., `github-work` host alias).

## Script Conventions

- All scripts source `lib/utils.sh` for logging (`info`, `success`, `warning`, `error`), OS detection, and file operations
- Use `$SUDO` variable (auto-set to `sudo` or empty based on root status) instead of hardcoding `sudo`
- `is_wsl()` checks for WSL2 environment to handle platform edge cases (e.g., SSH UseKeychain)

## CI

GitHub Actions workflow (`.github/workflows/test.yml`) runs `make ci-test` on macOS + Ubuntu, then verifies key files exist and tools installed correctly.

## Important Reminders

- After adding features or modules, update `README.md` (available commands, directory structure sections)
- Use the `/dotfiles-guide` skill for quick reference on where to place new configs, packages, or modules
