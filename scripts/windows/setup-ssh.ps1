# Windows SSH Configuration Setup Script
# Deploys SSH config from dotfiles to ~/.ssh/config
#
# Prerequisites:
#   - 1Password desktop app installed with SSH Agent enabled
#   - Public key files (.pub) exported to ~/.ssh/ from 1Password

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DotfilesDir = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$SourceConfig = Join-Path $DotfilesDir "config\ssh\config"

$SshDir = Join-Path $HOME ".ssh"
$ConfigPath = Join-Path $SshDir "config"

function Write-Info    { param($msg) Write-Host "  -> $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Step    { param($msg) Write-Host "`n$msg" -ForegroundColor Blue }

# ============================================================================
# 1. Ensure ~/.ssh directory exists with correct permissions
# ============================================================================
Write-Step "Setting up ~/.ssh directory..."

if (-not (Test-Path $SshDir)) {
    New-Item -ItemType Directory -Path $SshDir -Force | Out-Null
    Write-Info "Created directory: $SshDir"
} else {
    Write-Info "Directory already exists: $SshDir"
}

# Restrict ~/.ssh permissions: disable inheritance, keep only user + SYSTEM
$acl = Get-Acl $SshDir
$acl.SetAccessRuleProtection($true, $false)  # disable inheritance, remove inherited rules
$propagation = [System.Security.AccessControl.PropagationFlags]"None"
$inheritance = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit"
$userRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $env:USERNAME, "FullControl", $inheritance, $propagation, "Allow"
)
$systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "SYSTEM", "FullControl", $inheritance, $propagation, "Allow"
)
$acl.SetAccessRule($userRule)
$acl.SetAccessRule($systemRule)
Set-Acl -Path $SshDir -AclObject $acl
Write-Success "Set permissions on: $SshDir"

# ============================================================================
# 2. Backup existing config
# ============================================================================
if (Test-Path $ConfigPath) {
    $BackupPath = "$ConfigPath.bak"
    Copy-Item $ConfigPath $BackupPath -Force
    Write-Info "Backed up existing config to: $BackupPath"
}

# ============================================================================
# 3. Deploy SSH config
# ============================================================================
Write-Step "Deploying SSH config..."

Copy-Item $SourceConfig $ConfigPath -Force
Write-Success "Installed SSH config: $ConfigPath"

# ============================================================================
# 4. Remind about public key files
# ============================================================================
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. In 1Password: Settings > Developer > SSH Agent > enable" -ForegroundColor Yellow
Write-Host "  2. Export public keys from 1Password to ~/.ssh/:" -ForegroundColor Yellow
Write-Host "       id_ed25519.pub        (personal GitHub)" -ForegroundColor Yellow
Write-Host "       id_ed25519_im.pub     (Intelligentmemory GitHub)" -ForegroundColor Yellow
Write-Host "  3. Test connections:" -ForegroundColor Yellow
Write-Host "       ssh -T git@github.com" -ForegroundColor Yellow
Write-Host "       ssh -T git@github-im" -ForegroundColor Yellow
Write-Host ""
