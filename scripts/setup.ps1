# Desk Windows — ZeroTier mesh + OpenSSH for Cursor agent access.
# Run as Administrator (setup.cmd requests elevation).
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ConfigPath = Join-Path $RepoRoot 'config.env'

function Read-Config($path) {
    $cfg = @{}
    Get-Content $path | ForEach-Object {
        if ($_ -match '^\s*#' -or $_ -notmatch '=') { return }
        $k, $v = $_ -split '=', 2
        $cfg[$k.Trim()] = $v.Trim()
    }
    return $cfg
}

$cfg = Read-Config $ConfigPath
$NetworkId = $cfg.ZT_NETWORK_ID
$MoonDawn = $cfg.ZT_MOON_DAWN
$MoonDusk = $cfg.ZT_MOON_DUSK
$PubKey = (Get-Content (Join-Path $RepoRoot 'ssh\cursor-agent.pub') -Raw).Trim()
$SshUser = if ($cfg.SSH_UNIX_NAME) { $cfg.SSH_UNIX_NAME } else { 'ai' }

Write-Host "==> Installing ZeroTier One (if missing)"
$ztExe = Join-Path $env:TEMP 'ZeroTier One.msi'
if (-not (Get-Command zerotier-cli -ErrorAction SilentlyContinue)) {
    Invoke-WebRequest -Uri 'https://download.zerotier.com/dist/ZeroTier%20One.msi' -OutFile $ztExe
    Start-Process msiexec.exe -Wait -ArgumentList @('/i', $ztExe, '/qn')
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [System.Environment]::GetEnvironmentVariable('Path', 'User')
}

$ztDir = 'C:\ProgramData\ZeroTier\One'
New-Item -ItemType Directory -Force -Path $ztDir | Out-Null

Write-Host "==> Installing pre-generated ZeroTier identity"
Stop-Service ZeroTierOneService -Force -ErrorAction SilentlyContinue
Copy-Item (Join-Path $RepoRoot 'zerotier\identity.secret') (Join-Path $ztDir 'identity.secret') -Force
Copy-Item (Join-Path $RepoRoot 'zerotier\identity.public') (Join-Path $ztDir 'identity.public') -Force
Start-Service ZeroTierOneService
Start-Sleep -Seconds 3

$cli = (Get-Command zerotier-cli -ErrorAction Stop).Source
$nodeId = (& $cli info).Split()[2]
Write-Host "ZeroTier node id: $nodeId (expect $($cfg.ZT_NODE_ID))"

Write-Host "==> Joining mesh network $NetworkId"
& $cli join $NetworkId | Out-Null
& $cli orbit $MoonDawn $MoonDawn | Out-Null
& $cli orbit $MoonDusk $MoonDusk | Out-Null

Write-Host "==> Enabling OpenSSH Server + agent key"
$cap = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
if ($cap.State -ne 'Installed') {
    Add-WindowsCapability -Online -Name $cap.Name | Out-Null
}

Set-Service -Name sshd -StartupType Automatic
Start-Service sshd

if (-not (Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' `
        -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
}

$adminKeys = 'C:\ProgramData\ssh\administrators_authorized_keys'
$userKeys = Join-Path $env:ProgramData "ssh\users_$($env:USERNAME)\authorized_keys"

function Add-AuthorizedKey($path) {
    $existing = @()
    if (Test-Path $path) { $existing = Get-Content $path -ErrorAction SilentlyContinue }
    if ($existing -notcontains $PubKey) {
        ($existing + $PubKey) | Where-Object { $_ -and $_.Trim() } | Set-Content -Path $path -Encoding ascii
    }
    icacls $path /inheritance:r | Out-Null
    icacls $path /grant 'SYSTEM:(F)' | Out-Null
    icacls $path /grant 'BUILTIN\Administrators:(F)' | Out-Null
}

Add-AuthorizedKey $adminKeys
$userDir = Split-Path $userKeys
New-Item -ItemType Directory -Force -Path $userDir | Out-Null
Add-AuthorizedKey $userKeys

$config = 'C:\ProgramData\ssh\sshd_config'
$text = Get-Content $config -Raw
if ($text -notmatch '(?m)^PubkeyAuthentication\s+yes') {
    $text = $text -replace '(?m)^#?\s*PubkeyAuthentication.*', 'PubkeyAuthentication yes'
    if ($text -notmatch 'PubkeyAuthentication') { $text += "`nPubkeyAuthentication yes`n" }
}
if ($text -notmatch '(?m)^PasswordAuthentication\s+no') {
    $text = $text -replace '(?m)^#?\s*PasswordAuthentication.*', 'PasswordAuthentication no'
    if ($text -notmatch 'PasswordAuthentication') { $text += "`nPasswordAuthentication no`n" }
}
Set-Content -Path $config -Value $text -Encoding ascii
Restart-Service sshd

Write-Host ""
Write-Host "Done. Next steps (on dawn controller):"
Write-Host "  zerotier-members --network-id $NetworkId allow $nodeId"
Write-Host "Then register ULA in nix-production modules/zt-addrs.nix:"
Write-Host "  desk-win = `"$($cfg.ZT_EXPECTED_IPV6)`""
Write-Host ""
Write-Host "Agent SSH (after admit):"
Write-Host "  ssh $SshUser@$($cfg.ZT_EXPECTED_IPV6)"
