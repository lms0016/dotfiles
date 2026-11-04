# Windows Herdr Setup Script
# Deploys the "Herdr Admin" launcher and the custom mods and layout from dotfiles.
#
# Only files listed under config\herdr are written. Shipped mods, settings.json
# and keys.json belong to the app and to the person, and are left alone.

param(
    # The Herdr home that receives the mods and layout.
    [string]$AppHome = (Join-Path $HOME ".config\herdr-admin")
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DotfilesDir = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$SourceDir = Join-Path $DotfilesDir "config\herdr"

$HerdrExe = Join-Path $env:LOCALAPPDATA "Programs\herdr-app\herdr-app.exe"
$AdminDir = Join-Path $env:LOCALAPPDATA "Programs\herdr-admin"
$BackupDir = Join-Path $HOME ".dotfiles_backup\herdr"

function Write-Info    { param($msg) Write-Host "  -> $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Step    { param($msg) Write-Host "`n$msg" -ForegroundColor Blue }

# Copies one file, keeping a timestamped backup when it would overwrite different content.
function Copy-WithBackup {
    param([string]$Source, [string]$Target, [string]$BackupName)

    if (Test-Path $Target) {
        if ((Get-FileHash $Source).Hash -eq (Get-FileHash $Target).Hash) { return }
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backup = Join-Path $BackupDir "$BackupName.$stamp"
        New-Item -ItemType Directory -Path (Split-Path -Parent $backup) -Force | Out-Null
        Copy-Item $Target $backup -Force
        Write-Info "Backed up: $backup"
    }
    New-Item -ItemType Directory -Path (Split-Path -Parent $Target) -Force | Out-Null
    Copy-Item $Source $Target -Force
    Write-Success "Installed: $Target"
}

if (-not (Test-Path $HerdrExe)) {
    Write-Host "Herdr app is not installed, skipping: $HerdrExe" -ForegroundColor Yellow
    return
}

# ============================================================================
# 1. Herdr Admin launcher
# ============================================================================
Write-Step "Deploying Herdr Admin launcher..."

$StartScript = Join-Path $AdminDir "start-admin.ps1"
Copy-WithBackup (Join-Path $SourceDir "admin\start-admin.ps1") $StartScript "admin\start-admin.ps1"

$ShortcutPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "Herdr Admin.lnk"
$Shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = (Get-Command pwsh).Source
$Shortcut.Arguments = "-NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$StartScript`""
$Shortcut.IconLocation = "$HerdrExe,0"
$Shortcut.Save()

# WScript.Shell cannot request elevation; this bit in the .lnk header is "Run as administrator".
$Bytes = [IO.File]::ReadAllBytes($ShortcutPath)
$Bytes[0x15] = $Bytes[0x15] -bor 0x20
[IO.File]::WriteAllBytes($ShortcutPath, $Bytes)
Write-Success "Shortcut: $ShortcutPath"

# ============================================================================
# 2. Mods and layout
# ============================================================================
Write-Step "Deploying mods and layout to $AppHome..."

foreach ($folder in "mods", "layouts") {
    $root = Join-Path $SourceDir $folder
    Get-ChildItem $root -Recurse -File | ForEach-Object {
        $relative = [IO.Path]::GetRelativePath($SourceDir, $_.FullName)
        Copy-WithBackup $_.FullName (Join-Path $AppHome $relative) $relative
    }
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  Open Herdr Admin, then press Ctrl+Shift+L until the My Main layout shows."
