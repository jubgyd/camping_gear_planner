# Deploying Camp Gear Planner to Hetzner (CX23) as a private PWA

One-time server setup, then a one-command deploy from Windows. The app is a
static site (Flutter web build); Caddy serves it over HTTPS behind Basic Auth.

Replace `<SERVER_IP>` with the CX23's public IP throughout. The app is served at
`https://camp.biergames.de`.

> **If the server already runs a web server** (e.g. something already answering on
> ports 80/443 for `biergames.de`), don't install a second one — add the
> `camp.biergames.de { … }` block to that server's config instead. This runbook
> assumes Caddy owns 80/443. Check with `sudo ss -ltnp '( sport = :80 or sport = :443 )'`
> before installing.

## 1. DNS (one time)
Create an `A` record: `camp.biergames.de` → `<SERVER_IP>`. Wait until
`nslookup camp.biergames.de` returns the server IP before continuing (needed for
the Let's Encrypt HTTP challenge).

## 2. Firewall (one time)
Open ports 80 and 443. On Hetzner Cloud Firewall (or `ufw`):
```
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```
Port 80 is required for the ACME certificate challenge; Caddy redirects it to 443.

## 3. Install Caddy (one time)
```
sudo apt update
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install -y caddy
```

## 4. Create the web root (one time)
```
sudo mkdir -p /var/www/camp
sudo chown -R $USER:$USER /var/www/camp
```

## 5. Generate a Basic Auth password hash (one time)
```
caddy hash-password --plaintext 'CHOOSE-A-STRONG-PASSWORD'
```
Copy the `$2a$...` bcrypt hash it prints.

## 6. Configure Caddy (one time)
Edit `/etc/caddy/Caddyfile` so it contains ONLY:
```
camp.biergames.de {
    root * /var/www/camp
    encode gzip zstd

    # Privacy gate. Directive is `basic_auth` on Caddy v2.8+, `basicauth` on
    # older v2. Use whichever your `caddy version` accepts.
    basic_auth {
        campuser <PASTE_BCRYPT_HASH_HERE>
    }

    # SPA fallback so Flutter deep links resolve to index.html.
    try_files {path} /index.html
    file_server
}
```
Then:
```
sudo systemctl reload caddy
sudo systemctl status caddy   # confirm active; Caddy fetches HTTPS automatically
```

## 7. Deploy the app (every update, from Windows)
From the project folder (the script defaults to `root@camp.biergames.de` and
`/var/www/camp`):
```
./tool/deploy_web.ps1
```
Override if your SSH user isn't `root`:
```
./tool/deploy_web.ps1 -Server youruser@camp.biergames.de
```
(Uses OpenSSH `scp`, built into Windows 11. If key auth isn't set up, it prompts
for the server password.)

## 8. Install on iPhone (one time)
1. Open `https://camp.biergames.de` in Safari; enter the Basic Auth user/password.
2. Share button → **Add to Home Screen**.
3. Launch from the home screen — it opens fullscreen with the mountain icon.

## Notes
- **Data is per-device.** The phone keeps its own data in Safari storage. Move
  trips over with Settings → Backup: Save a backup on Windows, Load it in the
  web app. Export a backup periodically — iOS Safari can evict site storage
  under storage pressure or long disuse.
- **Stale build after redeploy:** Flutter's service worker may serve a cached
  build. Hard-refresh in Safari, or delete and re-add the home-screen app, to
  pick up a new version.
