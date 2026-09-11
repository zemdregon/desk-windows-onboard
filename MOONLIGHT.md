# Moonlight ↔ Sunshine over ZeroTier

## Where the PIN comes from

**Sunshine does not generate the PIN.** Moonlight does. Sunshine only shows "pairing request received" and waits for you to type the PIN into its web UI.

- **Moonlight GUI:** click the locked PC → a dialog shows a **4-digit PIN** → type that into Sunshine → PIN tab.
- **Moonlight CLI (recommended):** you pick the PIN so both sides match:

  ```bash
  moonlight pair 192.168.68.109 --pin 4829
  ```

  Immediately enter **4829** in Sunshine web UI → PIN tab → Send.

If Sunshine shows multiple pairing requests, stuck sessions are blocking new ones. On Windows (elevated):

```powershell
.\scripts\restart-sunshine.ps1
```

Then do **one** pair attempt only.

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

**Pair on LAN first** (works today). Move to ZeroTier address after pairing succeeds.

1. Windows: `.\scripts\restart-sunshine.ps1` (clears stuck sessions).
2. Moonlight → remove `DESKTOP-IS44VP9` if present.
3. One pairing attempt:

   ```bash
   moonlight pair 192.168.68.109 --pin 4829
   ```

   Within a few seconds, Sunshine web UI → PIN tab → enter **4829** → Send.

4. After paired, add ZT address in Moonlight host settings for away-from-home streaming:
   `fd2c:a2fd:5d9e:ab72:9d99:9307:c2fd:60d2`

### Verify

```bash
moonlight list fd2c:a2fd:5d9e:ab72:9d99:9307:c2fd:60d2
moonlight stream fd2c:a2fd:5d9e:ab72:9d99:9307:c2fd:60d2 Desktop
```

## Notes

- Windows user is **`ai`** (ASCII — no locale issues).
- Do **not** pair via LAN IP from thin when you intend to stream over ZeroTier.
- If it still fails, delete `%APPDATA%\Sunshine\sunshine_state` paired-client data (after backing up) and reset Moonlight's host list.
