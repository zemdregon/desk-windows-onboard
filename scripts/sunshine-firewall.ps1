# Open Sunshine / GameStream ports on all profiles (incl. ZeroTier). Run elevated.
$ErrorActionPreference = 'Stop'

$rules = @(
    @{ Name = 'Sunshine TCP (GameStream)'; Protocol = 'TCP'; Port = '47984,47989,48010' }
    @{ Name = 'Sunshine UDP (GameStream)'; Protocol = 'UDP'; Port = '5353,47998-48010' }
)

foreach ($r in $rules) {
    $existing = Get-NetFirewallRule -DisplayName $r.Name -ErrorAction SilentlyContinue
    if ($existing) { Remove-NetFirewallRule -DisplayName $r.Name }
    New-NetFirewallRule -DisplayName $r.Name -Direction Inbound -Action Allow `
        -Protocol $r.Protocol -LocalPort $r.Port | Out-Null
    Write-Host "Added: $($r.Name)"
}
