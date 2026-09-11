# Sunshine pairing over ZeroTier — run elevated on Windows after Sunshine is installed.
$ErrorActionPreference = 'Stop'

$sunshineConf = Join-Path $env:APPDATA 'Sunshine\sunshine.conf'
New-Item -ItemType Directory -Force -Path (Split-Path $sunshineConf) | Out-Null

$lines = @()
if (Test-Path $sunshineConf) {
    $lines = Get-Content $sunshineConf
}

function Set-ConfLine($key, $value) {
    script:lines = $lines | Where-Object { $_ -notmatch "^\s*$([regex]::Escape($key))\s*=" }
    $script:lines += "$key = $value"
}

Set-ConfLine 'origin_pin_allowed' 'wan'
Set-ConfLine 'origin_web_ui_allowed' 'lan'
Set-ConfLine 'upnp' 'disabled'

$lines | Set-Content -Path $sunshineConf -Encoding ascii

Write-Host "Wrote $sunshineConf"
Write-Host "  origin_pin_allowed = wan   # required for PIN over ZeroTier"
Write-Host ""
Write-Host "Restart Sunshine, then remove old paired clients in https://localhost:47990"
Write-Host "Then run fix-zerotier-windows.ps1 for mesh inbound (see ZEROTIER-WINDOWS.md)"
Write-Host "Add firewall rules for Sunshine (see scripts/sunshine-firewall.ps1)"

Restart-Service SunshineService -ErrorAction SilentlyContinue
