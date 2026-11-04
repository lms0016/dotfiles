# Opens an elevated Herdr window backed by its own elevated herdr-core.
# Launched by the "Herdr Admin" desktop shortcut, which requests elevation.

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host 'NG: not elevated. Use the Herdr Admin shortcut.'
    return
}

# Scoped to this process and its children, so the normal Herdr keeps its own core and settings.
$env:HC_SESSION = 'admin'

# The app's socket path has a length limit, so keep this home short.
$env:HERDR_APP_HOME = "$env:USERPROFILE\.config\herdr-admin"

Start-Process "$env:LOCALAPPDATA\Programs\herdr-app\herdr-app.exe"
