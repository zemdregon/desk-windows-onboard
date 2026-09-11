# Fix ZeroTier inbound on Windows 11 (Public profile + IPv6 firewall).
# Run elevated after ZeroTier is joined to the mesh network.
$ErrorActionPreference = 'Stop'

$MeshIpv6 = 'fd2c:a2fd:5d9e:ab72:9d99:9307:c2fd:60d2'

Write-Host '==> ZeroTier adapters'
Get-NetAdapter | Where-Object InterfaceDescription -like '*ZeroTier*' | Format-Table Name, Status, InterfaceDescription

Write-Host '==> Set ZeroTier network profile to Private (Public blocks inbound on Win11)'
Get-NetConnectionProfile | Where-Object InterfaceAlias -like 'ZeroTier*' |
    Set-NetConnectionProfile -NetworkCategory Private

Get-NetConnectionProfile | Where-Object InterfaceAlias -like 'ZeroTier*' |
    Format-Table InterfaceAlias, NetworkCategory, IPv4Connectivity, IPv6Connectivity

$ztIfaces = @(Get-NetAdapter | Where-Object InterfaceDescription -like '*ZeroTier*' | Select-Object -ExpandProperty Name)
if ($ztIfaces.Count -eq 0) {
    Write-Warning 'No ZeroTier adapter found. Is ZeroTier One running and joined?'
}

function Ensure-Rule {
    param(
        [string]$DisplayName,
        [string]$Protocol,
        [string]$LocalPort = '',
        [string[]]$InterfaceAlias
    )
    Get-NetFirewallRule -DisplayName $DisplayName -ErrorAction SilentlyContinue |
        Remove-NetFirewallRule -ErrorAction SilentlyContinue

    $params = @{
        DisplayName  = $DisplayName
        Direction    = 'Inbound'
        Action       = 'Allow'
        Protocol     = $Protocol
        Profile      = @('Private', 'Public', 'Domain')
        InterfaceAlias = $InterfaceAlias
        Enabled      = 'True'
    }
    if ($LocalPort) { $params.LocalPort = $LocalPort }

    New-NetFirewallRule @params | Out-Null
    Write-Host "  rule: $DisplayName ($Protocol $(if ($LocalPort) { $LocalPort }))"
}

foreach ($iface in $ztIfaces) {
    Write-Host "==> Firewall allow inbound on interface '$iface'"
    Ensure-Rule -DisplayName "ZT ICMPv4 ($iface)" -Protocol ICMPv4 -InterfaceAlias @($iface)
    Ensure-Rule -DisplayName "ZT ICMPv6 ($iface)" -Protocol ICMPv6 -InterfaceAlias @($iface)
    Ensure-Rule -DisplayName "ZT SSH ($iface)" -Protocol TCP -LocalPort 22 -InterfaceAlias @($iface)
    Ensure-Rule -DisplayName "ZT Sunshine TCP ($iface)" -Protocol TCP -LocalPort '47984,47989,48010' -InterfaceAlias @($iface)
    Ensure-Rule -DisplayName "ZT Sunshine UDP ($iface)" -Protocol UDP -LocalPort '5353,47998-48010' -InterfaceAlias @($iface)
}

Write-Host '==> ZeroTier addresses'
& 'C:\ProgramData\ZeroTier\One\zerotier-cli.bat' listnetworks 2>&1
& 'C:\ProgramData\ZeroTier\One\zerotier-cli.bat' -j listnetworks 2>$null | Out-Null

Write-Host ''
Write-Host "Expected mesh IPv6: $MeshIpv6"
Write-Host 'From a mesh peer (thin), verify:'
Write-Host "  ping -6 $MeshIpv6"
Write-Host "  ssh ai@$MeshIpv6"
Write-Host '  moonlight stream $MeshIpv6 Desktop'
