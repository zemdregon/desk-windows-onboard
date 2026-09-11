# Moonlight ↔ Sunshine over ZeroTier

## Symptom

Sunshine web UI accepts the PIN ("success"), but Moonlight reports:

> GeForce Experience returned an error: the client is not authorized. certificate validation failed (error 401)

## Cause

Pairing is a **four-step cert exchange**, not just the PIN. Common failure modes on this setup:

1. **Wrong host address in Moonlight** — auto-discovery picks LAN (`192.168.68.x`) or WAN (`76.85.x.x`). Pairing must use the **ZeroTier ULA**:
   ```
   fd2c:a2fd:5d9e:ab72:9d99:9307:c2fd:60d2
   ```
2. **Sunshine `origin_pin_allowed` too strict** — default may reject the PIN handshake from mesh clients even when the web UI PIN page works.
3. **Stale partial pairing** — repeated attempts leave mismatched client/server certs. Clear both sides and re-pair once.

## Fix (do in order)

### Windows (elevated PowerShell)

```powershell
cd <repo>\scripts
.\sunshine-firewall.ps1
.\configure-sunshine.ps1
```

Then open https://localhost:47990 → **Remove all paired clients**.

### thin (NixOS client)

1. Moonlight → remove `DESKTOP-IS44VP9` if present.
2. **Add PC manually** with address `fd2c:a2fd:5d9e:ab72:9d99:9307:c2fd:60d2` (no brackets in GUI; CLI accepts bare IPv6).
3. Pair from terminal (more reliable than GUI):

   ```bash
   moonlight pair fd2c:a2fd:5d9e:ab72:9d99:9307:c2fd:60d2
   ```

   Moonlight prints a 4-digit PIN. Enter it in Sunshine web UI → PIN tab **while the pair command is waiting** (do not use an old PIN).

4. Or pass PIN directly:

   ```bash
   moonlight pair fd2c:a2fd:5d9e:ab72:9d99:9307:c2fd:60d2 --pin 1234
   ```

   (Enter `1234` in Sunshine web UI at the same time.)

### Verify

```bash
moonlight list fd2c:a2fd:5d9e:ab72:9d99:9307:c2fd:60d2
moonlight stream fd2c:a2fd:5d9e:ab72:9d99:9307:c2fd:60d2 Desktop
```

## Notes

- Windows user is **`ai`** (ASCII — no locale issues).
- Do **not** pair via LAN IP from thin when you intend to stream over ZeroTier.
- If it still fails, delete `%APPDATA%\Sunshine\sunshine_state` paired-client data (after backing up) and reset Moonlight's host list.
