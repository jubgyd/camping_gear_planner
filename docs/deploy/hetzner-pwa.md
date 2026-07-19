# Camp Gear Planner — private PWA on Hetzner (as-built)

**Status: LIVE since 2026-07-19.** The Flutter web build is served at
**https://camp.biergames.de**, behind HTTP Basic Auth, with an automatic
Let's Encrypt certificate. Data is per-device (browser storage); move trips
between devices with the in-app Backup Save/Load.

This document records the actual running setup and how to redeploy or
troubleshoot it. For the original design rationale see
`docs/superpowers/specs/2026-07-19-web-hosting-iphone-pwa-design.md`.

---

## The running setup at a glance

| Thing | Value |
|-------|-------|
| URL | `https://camp.biergames.de` |
| Server | Hetzner CX23, IP `142.132.180.52`, hostname `BierGames`, Ubuntu, root |
| Web server | Caddy v2.11.4 (auto-HTTPS via Let's Encrypt) |
| Web root | `/var/www/camp` |
| Config | `/etc/caddy/Caddyfile` (default welcome-page config backed up to `Caddyfile.default.bak`) |
| Auth | HTTP Basic Auth, user `campuser` (password held by the app owner) |
| DNS | `camp.biergames.de` A record → `142.132.180.52` (Hetzner DNS) |

> Note: the CX23 only hosts *camp*. The `biergames.de` root domain points at a
> different server (`88.198.219.246`).

## Redeploying an app update (the normal case)

From the project folder on Windows:

```powershell
Set-Location "D:\Camping gear app\camp_gear_planner"
.\tool\deploy_web.ps1
```

That script runs `flutter build web --release` and
`scp -r build/web/. root@camp.biergames.de:/var/www/camp/`.

**If scp asks for a passphrase or is denied,** the SSH agent doesn't have the
key loaded (e.g. after a reboot). Load it once:

```powershell
Get-Service ssh-agent | Set-Service -StartupType Automatic
Start-Service ssh-agent
ssh-add $env:USERPROFILE\.ssh\id_ed25519   # enter passphrase once
```

`~/.ssh/config` already maps `camp.biergames.de` / `142.132.180.52` to
`~/.ssh/id_ed25519`, so after `ssh-add` all ssh/scp is non-interactive.

**Stale build after redeploy:** Flutter's service worker can serve a cached
build. In Safari, hard-refresh or delete + re-add the home-screen app to pick
up a new version.

## Changing the Basic Auth password

```bash
ssh root@142.132.180.52
caddy hash-password --plaintext 'NEW-PASSWORD'      # copy the $2a$... hash
nano /etc/caddy/Caddyfile                            # replace the hash after "campuser"
systemctl reload caddy
```

## Install on iPhone (one time)

1. Open `https://camp.biergames.de` in Safari; log in as `campuser`.
2. Share button → **Add to Home Screen** → **Add**.
3. Launch from the home screen — it opens fullscreen with the mountain icon.

---

## How it was set up (reference / disaster recovery)

If the server is ever rebuilt from scratch, this is the full path.

### 1. DNS
`camp.biergames.de` A record → server IP (already set in Hetzner DNS). SSH uses
the raw IP, so DNS only needs to be live before Caddy requests a certificate.

### 2. SSH access — two gotchas that cost us hours
- **Root login was disabled.** A fresh key kept failing with
  `Server accepts key: ...` immediately followed by `Permission denied
  (publickey)` — the key was authorized but the server refused root logins.
  Root cause was `PermitRootLogin no` in `/etc/ssh/sshd_config`. Fix (run in the
  server console, since you can't SSH in yet):
  ```bash
  sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
  systemctl restart ssh
  ```
  `prohibit-password` allows key logins for root but still blocks passwords.
- The `Server accepts key` line is only the "key is in authorized_keys" probe —
  it does **not** mean the login succeeded. Don't chase authorized_keys or the
  passphrase when you see it followed by a denial; check `PermitRootLogin` and
  file permissions (`chmod 700 ~/.ssh`, `chmod 600 ~/.ssh/authorized_keys`).

### 3. Firewall — open 80 and 443
`ufw` was **inactive**, but a **Hetzner Cloud Firewall** (network-level, in the
Cloud Console, not on the box) blocked inbound 80/443. Symptom: Caddy's ACME
http-01 challenge fails with
`Timeout during connect (likely firewall problem)`. Fix: Cloud Console →
**Firewalls** → the firewall attached to this server → **Inbound** → add
TCP **80** and TCP **443** from any source. (Caddy then succeeded via
tls-alpn-01 on 443.)

### 4. Caddy config
Caddy was already installed. `/etc/caddy/Caddyfile` contains only:

```caddyfile
camp.biergames.de {
	root * /var/www/camp
	encode gzip zstd

	# Private gate — HTTP Basic Auth. Directive is `basic_auth` on Caddy v2.8+.
	basic_auth {
		campuser <BCRYPT_HASH>
	}

	# SPA fallback so Flutter deep links resolve to index.html.
	try_files {path} /index.html
	file_server
}
```

Generate the hash with `caddy hash-password --plaintext '...'`, create the web
root (`mkdir -p /var/www/camp`), then `caddy validate --config
/etc/caddy/Caddyfile --adapter caddyfile` and `systemctl reload caddy`. Caddy
fetches the HTTPS certificate automatically once DNS + firewall are in place.

### 5. Deploy the app
`tool/deploy_web.ps1` (see "Redeploying" above).

## Notes
- **Data is per-device.** The phone keeps its own data in Safari storage. Move
  trips via Settings → Backup: Save on Windows, Load in the web app. Export a
  backup periodically — iOS Safari can evict site storage under pressure or long
  disuse.
- **v1 web has no product images** (the image feature is desktop-only, stubbed
  out on web behind the conditional-import facades).
