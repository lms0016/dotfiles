# Windows Git Configuration Setup Script
# Deploys .gitconfig and applies Windows-specific settings.
#
# Features:
#   - Deploys shared .gitconfig from dotfiles
#   - Sets Windows OpenSSH as git SSH command
#   - Configures 1Password SSH commit signing
#   - Prompts for personal identity (name, email, signing key)
#   - Optionally adds work accounts with directory-based identity switching

$ErrorActionPreference = "Stop"

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$DotfilesDir = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$SourceConfig = Join-Path $DotfilesDir "config\git\.gitconfig"

function Write-Info    { param($msg) Write-Host "  -> $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn    { param($msg) Write-Host "  [!]  $msg" -ForegroundColor Yellow }
function Write-Step    { param($msg) Write-Host "`n$msg" -ForegroundColor Blue }

# ============================================================================
# 1. Deploy shared .gitconfig
# ============================================================================
Write-Step "[1/3] Deploying .gitconfig..."

$GitconfigPath = Join-Path $HOME ".gitconfig"

if (Test-Path $GitconfigPath) {
    $BackupPath = "$GitconfigPath.bak"
    Copy-Item $GitconfigPath $BackupPath -Force
    Write-Info "Backed up existing config to: $BackupPath"
}

Copy-Item $SourceConfig $GitconfigPath -Force
Write-Success "Deployed .gitconfig: $GitconfigPath"

# ============================================================================
# 2. Apply Windows-specific settings
# ============================================================================

# Windows OpenSSH
git config --global core.sshCommand "C:/Windows/System32/OpenSSH/ssh.exe"
Write-Success "Set core.sshCommand (Windows OpenSSH)"

# 1Password SSH signing
$OpSignPath = Join-Path $env:LOCALAPPDATA "Microsoft\WindowsApps\op-ssh-sign.exe"
if (Test-Path $OpSignPath) {
    git config --global gpg.format ssh
    git config --global gpg.ssh.program "$OpSignPath"
    git config --global commit.gpgsign true
    Write-Success "Set gpg signing via 1Password"
} else {
    Write-Warn "op-ssh-sign.exe not found at: $OpSignPath"
    Write-Warn "Skipping GPG signing config. Install 1Password and enable SSH Agent."
}

# ============================================================================
# 3. Personal identity
# ============================================================================
Write-Step "[2/3] Personal identity"
Write-Host "  (Leave blank to skip a field)" -ForegroundColor DarkGray

$name = Read-Host "  Name"
if ($name) {
    git config --global user.name "$name"
    Write-Success "Set user.name"
}

$email = Read-Host "  Email"
if ($email) {
    git config --global user.email "$email"
    Write-Success "Set user.email"
}

$signingKey = Read-Host "  Signing key (paste SSH public key, e.g. ssh-ed25519 AAAA...)"
if ($signingKey) {
    git config --global user.signingkey "$signingKey"
    Write-Success "Set user.signingkey"
}

# ============================================================================
# 4. Work accounts (optional)
# ============================================================================
Write-Step "[3/3] Work accounts"

$addWork = Read-Host "  Do you want to add work accounts? (Y/n)"
if ($addWork -ne 'n' -and $addWork -ne 'N') {

    do {
        Write-Host ""
        $label = Read-Host "  Label (e.g. work, company)"
        if (-not $label) { Write-Warn "Label cannot be empty. Skipping."; break }

        $projectDir = Read-Host "  Project dir (e.g. D:/Projects/Work)"
        if (-not $projectDir) { Write-Warn "Project dir cannot be empty. Skipping."; break }

        $workEmail = Read-Host "  Work email"
        if (-not $workEmail) { Write-Warn "Work email cannot be empty. Skipping."; break }

        $sshAlias = Read-Host "  SSH host alias for url rewrite (leave blank to skip)"

        # Write ~/.gitconfig-<label>
        $workConfigPath = Join-Path $HOME ".gitconfig-$label"
        $workConfigContent = "[user]`n`temail = $workEmail"
        if ($sshAlias) {
            $workConfigContent += "`n`n[url `"git@$sshAlias`:`"]`n`tinsteadOf = git@github.com:"
        }
        Set-Content -Path $workConfigPath -Value $workConfigContent -Encoding UTF8
        Write-Success "Created: $workConfigPath"

        # Normalize path separators for git (forward slashes, trailing slash)
        $gitDir = $projectDir.Replace('\', '/').TrimEnd('/') + '/'
        git config --global "includeIf.gitdir/i:$gitDir.path" "~/.gitconfig-$label"
        Write-Success "Added includeIf for: $gitDir"

        $more = Read-Host "  Add another? (y/N)"
    } while ($more -eq 'y' -or $more -eq 'Y')
}

# ============================================================================
# Done
# ============================================================================
Write-Host ""
Write-Host "Git configuration complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Verify with: git config --list --global" -ForegroundColor DarkGray
Write-Host ""
