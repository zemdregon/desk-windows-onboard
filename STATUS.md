# Status — desk Windows onboarding

Last updated: 2026-09-11 (UTC-5)

## Done

| Step | Status | Notes |
|------|--------|-------|
| Repo created | ✅ | https://github.com/zemdregon/desk-windows-onboard (private) |
| ZT identity generated | ✅ | Node `07c2fd60d2`, ULA `fd2c:a2fd:5d9e:ab72:9d99:9307:c2fd:60d2` |
| Node admitted on dawn | ✅ | `zerotier-members --network-id 2ca2fd5d9eab729d allow 07c2fd60d2` → `200 OK` |
| ZT mesh connectivity | ✅ | Dawn sees peer as **DIRECT** at `76.85.115.98/59491` (2026-09-11 00:16) |
| SSH username confirmed | ✅ | Windows user is **`ai`** (not `ender`) — reflected in `config.env` + scripts |

## Blocked — SSH not reachable

Multiple attempts from **thin** and **dawn** failed:

```bash
ping -6 fd2c:a2fd:5d9e:ab72:9d99:9307:c2fd:60d2   # 100% packet loss
ssh ai@fd2c:a2fd:5d9e:ab72:9d99:9307:c2fd:60d2   # port 22 connection timed out
```

Agent key: `~/.ssh/id_ed25519` (pubkey in `ssh/cursor-agent.pub`).

**Interpretation:** ZeroTier L3 path is up (peer online on controller), but nothing on Windows is accepting inbound on the ZT interface — ICMP and TCP/22 both dead.

## Likely causes (check on Windows)

1. **`scripts/setup.cmd` not run elevated** — installs OpenSSH, drops agent pubkey, joins ZT.
2. **OpenSSH Server not running** — `Get-Service sshd` should be Running.
3. **Windows Firewall** blocking inbound on the ZeroTier virtual adapter (ICMP + TCP/22).
4. **Key not in right file** — admin users need `C:\ProgramData\ssh\administrators_authorized_keys`; non-admin users need `C:\ProgramData\ssh\users_ai\authorized_keys`.

## Still TODO (infra)

- [ ] Run `scripts/setup.cmd` as Administrator on the Windows desktop (if not done).
- [ ] Add ULA to `nix-production/modules/zt-addrs.nix`:
  ```nix
  desk-win = "fd2c:a2fd:5d9e:ab72:9d99:9307:c2fd:60d2";
  ```
- [ ] Add `Host desk-win` to agent `~/.ssh/config` (see README).
- [ ] Re-test after Windows setup:
  ```bash
  ssh -o ConnectTimeout=10 -i ~/.ssh/id_ed25519 ai@fd2c:a2fd:5d9e:ab72:9d99:9307:c2fd:60d2 'hostname & whoami'
  ```

## Dawn controller commands (reference)

```bash
# admit (already done)
sudo /nix/store/a4k3hysql1c1881bia75xjd09drxj1id-zerotier-tools-0.1.0/bin/zerotier-members \
  --network-id 2ca2fd5d9eab729d allow 07c2fd60d2

# verify member
sudo /nix/store/a4k3hysql1c1881bia75xjd09drxj1id-zerotier-tools-0.1.0/bin/zerotier-members \
  --network-id 2ca2fd5d9eab729d list | grep 07c2fd60d2
# → 07c2fd60d2 fd2c:a2fd:5d9e:ab72:9d99:9307:c2fd:60d2 True

# check peer liveness
sudo zerotier-cli peers | grep 07c2fd60d2
```

SSH to dawn: `ender@fd2c:a2fd:5d9e:ab72:9d99:932c:a2fd:5d9e`

## Identity separation

| OS | Node ID | Mesh IPv6 |
|----|---------|-----------|
| desk (NixOS) | `3b2af6548bb` | `fd2c:a2fd:5d9e:ab72:9d99:93b2:af65:48bb` |
| desk (Windows) | `07c2fd60d2` | `fd2c:a2fd:5d9e:ab72:9d99:9307:c2fd:60d2` |

Only one OS boots at a time on the OMEN chassis; identities are intentionally separate.
