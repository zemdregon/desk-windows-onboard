# desk-windows-onboard

Private onboarding bundle for the **desk** machine's Windows side (OMEN dual-boot). Joins the zem mesh ZeroTier network and trusts the Cursor agent SSH key.

**Private repo — contains cryptographic secrets. Do not make public.**

## Contents

| Path | Purpose |
|------|---------|
| `zerotier/identity.secret` | Pre-generated ZeroTier node identity (install before join) |
| `zerotier/identity.public` | Matching public identity |
| `zerotier/network-id` | Mesh network ID (`2ca2fd5d9eab729d`) |
| `zerotier/node-id` | Node ID to admit on the controller |
| `zerotier/expected-mesh-ipv6` | RFC4193 ULA after controller assigns addresses |
| `zerotier/moons.env` | Dawn/dusk moon root IDs |
| `ssh/cursor-agent.pub` | Ed25519 key the Cursor agent uses to SSH in |
| `scripts/setup.ps1` | One-shot Windows setup (ZT + OpenSSH) |

## On the Windows desktop

1. Clone this repo (or copy the folder onto the machine).
2. Right-click `scripts/setup.cmd` → **Run as administrator** (or run `setup.ps1` elevated).
3. On **dawn** (mesh controller), admit the node:

   ```bash
   zerotier-members --network-id 2ca2fd5d9eab729d allow 07c2fd60d2
   ```

4. Add the ULA to `modules/zt-addrs.nix` in nix-production (suggested key `desk-win`):

   ```nix
   desk-win = "fd2c:a2fd:5d9e:ab72:9d99:9307:c2fd:60d2";
   ```

5. Confirm from any mesh peer:

   ```bash
   ping -6 fd2c:a2fd:5d9e:ab72:9d99:9307:c2fd:60d2
   ssh ai@fd2c:a2fd:5d9e:ab72:9d99:9307:c2fd:60d2
   ```

## Agent SSH config (Linux side)

Add to `~/.ssh/config` after admit:

```
Host desk-win
  HostName fd2c:a2fd:5d9e:ab72:9d99:9307:c2fd:60d2
  User ai
  IdentityFile ~/.ssh/id_ed25519
  StrictHostKeyChecking accept-new
  BatchMode yes
```

## Notes

- This identity is **separate** from the NixOS `desk` Linux identity (`3b2af6548bb`). Only one OS boots at a time, but each OS keeps its own ZT node record.
- Moons orbited automatically: dawn `2ca2fd5d9e`, dusk `39b2e68dd6d`.
- OpenSSH is configured for **pubkey-only** auth; password logins disabled.
