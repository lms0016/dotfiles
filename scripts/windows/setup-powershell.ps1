# Windows PowerShell Setup Script
# Installs PowerShell profile and oh-my-posh theme
#
# Prerequisites (run first):
#   winget install Microsoft.PowerShell
#   winget install JanDeDobbeleer.OhMyPosh
# Then restart PowerShell before running this script.

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DotfilesDir = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$SourceDir = Join-Path $DotfilesDir "config\shell\powershell"

$ProfileDir = Split-Path -Parent $PROFILE
$ProfilePath = Join-Path $ProfileDir "Microsoft.PowerShell_profile.ps1"
$ThemePath = Join-Path $ProfileDir "alan.omp.yaml"

function Write-Info { param($msg) Write-Host "  -> $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "  [!] $msg" -ForegroundColor Yellow }
function Write-Step { param($msg) Write-Host "`n$msg" -ForegroundColor Blue }

# ============================================================================
# 1. Install font
# ============================================================================
Write-Step "Installing CascadiaCode font..."
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh font install CascadiaCode
    Write-Success "CascadiaCode font installed"
} else {
    Write-Warn "oh-my-posh not found. Run: winget install JanDeDobbeleer.OhMyPosh, then restart PowerShell"
}

# ============================================================================
# 2. Install PowerShell modules
# ============================================================================
Write-Step "Installing PowerShell modules..."

Write-Info "Installing Terminal-Icons..."
Install-Module -Name Terminal-Icons -Repository PSGallery -Force
Write-Success "Terminal-Icons installed"

Write-Info "Installing PSReadLine..."
Install-Module PSReadLine -AllowPrerelease -Force
Write-Success "PSReadLine installed"

# ============================================================================
# 3. Install profile and theme
# ============================================================================
Write-Step "Installing PowerShell profile..."

# Ensure profile directory exists
if (-not (Test-Path $ProfileDir)) {
    New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
    Write-Info "Created profile directory: $ProfileDir"
}

# Backup existing profile
if (Test-Path $ProfilePath) {
    $BackupPath = "$ProfilePath.bak"
    Copy-Item $ProfilePath $BackupPath -Force
    Write-Info "Backed up existing profile to: $BackupPath"
}

# Copy profile
Copy-Item (Join-Path $SourceDir "Microsoft.PowerShell_profile.ps1") $ProfilePath -Force
Write-Success "Installed PowerShell profile: $ProfilePath"

# Copy oh-my-posh theme
Copy-Item (Join-Path $SourceDir "alan.omp.yaml") $ThemePath -Force
Write-Success "Installed oh-my-posh theme: $ThemePath"

# ============================================================================
# Done
# ============================================================================
Write-Host ""
Write-Host "Done! Restart PowerShell or run: . `$PROFILE" -ForegroundColor Green
Write-Host "Note: Remember to set CascadiaCode as your terminal font in Windows Terminal settings." -ForegroundColor Yellow
