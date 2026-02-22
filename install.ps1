#Requires -Version 7.0
# Dotfiles installer for Windows (PowerShell 7)
# Usage: pwsh -ExecutionPolicy Bypass -File install.ps1

$ErrorActionPreference = "Stop"

$DotfilesDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ============================================================================
# Logging
# ============================================================================
function Write-Info  { param([string]$msg) Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Ok    { param([string]$msg) Write-Host "[ OK] $msg" -ForegroundColor Green }
function Write-Warn  { param([string]$msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Step  { param([string]$msg) Write-Host "`n$msg" -ForegroundColor Blue }
function Write-Fatal { param([string]$msg) Write-Host "[ERR] $msg" -ForegroundColor Red; exit 1 }

# ============================================================================
# Winget Packages
# ============================================================================
function Install-WingetPackages {
    Write-Step "Installing winget packages..."

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Fatal "winget not found. Install 'App Installer' from the Microsoft Store first."
    }

    $packageFile = Join-Path $DotfilesDir "packages\windows\winget.txt"
    $packages = Get-Content $packageFile |
        Where-Object { $_ -notmatch '^\s*#' -and $_ -match '\S' } |
        ForEach-Object { $_.Trim() }

    foreach ($pkg in $packages) {
        Write-Info "Installing $pkg..."
        winget install --id $pkg --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
            Write-Warn "$pkg`: winget returned $LASTEXITCODE (may already be installed, continuing)"
        } else {
            Write-Ok "$pkg"
        }
    }
}

# ============================================================================
# PowerShell Config
# ============================================================================
function Install-PwshConfig {
    Write-Step "Installing PowerShell configuration..."
    & "$DotfilesDir\scripts\windows\setup-powershell.ps1"
}

# ============================================================================
# Git Config
# ============================================================================
function Install-GitConfig {
    Write-Step "Installing Git configuration..."
    & "$DotfilesDir\scripts\windows\setup-git.ps1"
}

# ============================================================================
# SSH Config
# ============================================================================
function Install-SshConfig {
    Write-Step "Installing SSH configuration..."
    & "$DotfilesDir\scripts\windows\setup-ssh.ps1"
}

# ============================================================================
# Main
# ============================================================================
function Main {
    Write-Host ""
    Write-Host "======================================" -ForegroundColor Blue
    Write-Host "  Dotfiles - Windows Setup"
    Write-Host "======================================" -ForegroundColor Blue
    Write-Host ""
    Write-Info "Dotfiles directory: $DotfilesDir"

    Install-WingetPackages
    Install-PwshConfig
    Install-GitConfig
    Install-SshConfig

    Write-Host ""
    Write-Host "======================================" -ForegroundColor Green
    Write-Host "  Setup Complete!"
    Write-Host "======================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Restart PowerShell to apply all changes." -ForegroundColor Yellow
    Write-Host ""
}

Main
