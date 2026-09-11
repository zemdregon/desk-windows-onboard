# Clear stuck pairing sessions. Run elevated on Windows.
$ErrorActionPreference = 'Stop'
Restart-Service SunshineService -Force
Start-Sleep -Seconds 2
Get-Service SunshineService | Format-List Name, Status, StartType
Write-Host "Stuck pairing sessions cleared. Re-pair once — use a single PIN from Moonlight."
