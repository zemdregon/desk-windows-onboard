# ZeroTier on desk Windows — inbound fix

## Problem

ZeroTier peer shows **DIRECT** on dawn, but from thin:

- `ping -6 fd2c:…:60d2` → 100% loss
- SSH / Sunshine on mesh IPv6 → timeout

LAN (`192.168.68.109`) works. Mesh IPv6 does not.

## Root cause

Windows 11 sets the ZeroTier virtual adapter to **Public** firewall profile by default. Public blocks inbound IPv6 (ICMP, SSH, GameStream). ZeroTier L3 is up; Windows firewall drops everything arriving on that interface.

## Fix (on Windows, elevated PowerShell)

After ZeroTier is joined (`setup.ps1` or manual join):

```powershell
cd <repo>\scripts
.\fix-zerotier-windows.ps1
```

This script:

1. Sets `ZeroTier One […]` network profile → **Private**
2. Adds inbound allow rules **bound to the ZeroTier interface** for ICMPv4/v6, SSH :22, Sunshine TCP/UDP

## Verify from thin

```bash
ping -6 fd2c:a2fd:5d9e:ab72:9d99:9307:c2fd:60d2
ssh ai@fd2c:a2fd:5d9e:ab72:9d99:9307:c2fd:60d2
```

Moonlight: set manual/remote address on the paired host to the ZT ULA for away-from-LAN streaming.

## If still broken

- Confirm assigned address: `zerotier-cli listnetworks` on Windows shows `fd2c:a2fd:5d9e:ab72:9d99:9307:c2fd:60d2`
- Confirm node still admitted on dawn: `zerotier-members --network-id 2ca2fd5d9eab729d list | grep 07c2fd60d2`
- Re-run `setup.ps1` if OpenSSH stopped (port 22 dead on LAN too)
