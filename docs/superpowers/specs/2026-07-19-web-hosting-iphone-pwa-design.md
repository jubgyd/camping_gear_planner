# Camp Gear Planner — Private iPhone Web App (PWA on Hetzner)

**Date:** 2026-07-19
**Status:** Approved design, pending implementation plan

## Goal

Access the existing Camp Gear Planner from an iPhone by hosting the Flutter
**web** build privately on the user's own Hetzner CX23 server, and adding it to
the iOS home screen as a standalone PWA. Apple Developer Program enrollment is
not available right now, so a native iOS build is out of scope.

## Non-goals (explicitly out of scope for this milestone)

- **No cross-device sync / backend / accounts.** The iPhone instance keeps its
  own data in the phone browser's storage. Moving trips between the Windows app
  and the phone is done with the existing **Backup Save / Load** feature
  (export a file on Windows, import it in the browser). Confirmed by the user.
- **No product images on the web build for v1.** See "Product images" below.
- No native iOS packaging, no App Store, no push notifications.

## Constraints & requirements

- iOS "Add to Home Screen" as a real standalone app requires **HTTPS with a
  valid certificate** and a **web app manifest** + `apple-touch-icon`.
- The server is a Hetzner CX23 (always-on VPS). The user owns a domain and can
  add a subdomain (e.g. `camp.example.tld`).
- The Windows desktop build must remain byte-for-byte behaviourally unchanged —
  all web-specific code goes behind conditional imports, never replacing the
  desktop paths.

## Current web-compatibility assessment

Audited `lib/` for browser-incompatible APIs:

| Area | Web status |
| --- | --- |
| App data (`shared_preferences`) | ✅ Works (browser storage) |
| Backup save/load (`file_access` facade) | ✅ Already has `file_access_web.dart` |
| Price/link fetch (`http`, `html`), `url_launcher`, `share_plus`, `google_fonts` | ✅ Web-compatible |
| **Product images** (`lib/util/image_store.dart`, `lib/widgets/product_thumb.dart`) | ❌ Use `dart:io` file writes + `path_provider.getApplicationSupportDirectory` — do not exist in the browser; **block web compilation** |

The product-image feature is the **only** code blocker for a web build.

## Design

### 1. Make the app compile & run on web

Abstract the two `dart:io`-dependent image files behind the same conditional-
import pattern already used by `lib/util/file_access.dart`
(`_stub` / `_io` / `_web` selected via `dart.library.io` / `dart.library.html`).

- **`ImageStore`** → facade + `_io` (current implementation, unchanged for
  desktop) + `_web` (no-op: `init()` succeeds, `dirPath`/`pathFor` return null,
  `download`/`importFile` return null, `delete` no-ops). Web callers already
  treat null as "no image", so the feature degrades cleanly.
- **`ProductThumb`** → must not reference `dart:io` `File` on web. Either split
  into `_io`/`_web` variants, or gate the `Image.file` behind the same facade so
  the web widget returns `SizedBox.shrink()`.
- **Image UI controls** in `item_edit_screen.dart` ("Choose from computer",
  "Remove image", thumbnail preview): hidden on web (`kIsWeb`) so users aren't
  shown buttons that do nothing.

Desktop behaviour is untouched — the `_io` path is exactly today's code.

### 2. PWA polish for iOS

Flutter emits `web/manifest.json` + a service worker. Configure:

- `manifest.json`: `name` / `short_name` ("Camp Gear"), `display: standalone`,
  `background_color` + `theme_color` matching the app, and icon entries
  (192, 512, and a `maskable` 512) generated from `assets/icon/app_icon.png`.
- `web/index.html`: `apple-mobile-web-app-capable`, `apple-mobile-web-app-title`,
  `apple-mobile-web-app-status-bar-style`, and an `apple-touch-icon` link
  pointing at a 180×180 PNG of the mountain logo (iOS ignores the manifest icon
  for the home-screen glyph and uses this instead).
- Confirm the app renders acceptably at iPhone widths — the existing responsive
  nav already switches to the bottom `NavigationBar` on narrow screens, so this
  should mostly hold; verify no horizontal overflow.

### 3. Hosting on Hetzner (CX23)

- **DNS:** `A` record `camp.<domain>` → server public IP.
- **Web server:** Caddy, chosen for automatic Let's Encrypt HTTPS + renewal with
  minimal config. Rough Caddyfile:

  ```
  camp.<domain> {
      root * /var/www/camp
      encode gzip
      basic_auth {
          <user> <bcrypt-hash>
      }
      try_files {path} /index.html   # SPA fallback for deep links
      file_server
  }
  ```

  `basic_auth` is the privacy gate — one username/password, remembered by Safari
  after first entry. Hash generated with `caddy hash-password`.
- **Firewall:** ensure ports 80 + 443 open (80 needed for the ACME challenge).

### 4. Build & deploy

- Local build: `D:\Flutter\flutter\bin\flutter.bat build web --release`
  (consider `--base-href /` since it's served at the domain root).
- Deploy: rsync/scp `build/web/` → `/var/www/camp/` on the server. Provide a
  small one-line deploy script (documented, not committed with secrets).
- **Cache note:** Flutter's service worker can serve stale builds; document the
  hard-refresh / version-bump step for redeploys.

### 5. Product images (deferred decision, recorded)

For v1 the web build **skips** images entirely (buttons + thumbnails hidden;
Windows keeps full image support). Chosen for fastest ship and because auto-grab
from links is typically CORS-blocked in browsers anyway. A later milestone could
add a web image path (manual pick → store bytes as base64/IndexedDB), if wanted.

## Verification

1. `flutter analyze` clean; `flutter test` green (desktop paths unaffected).
2. `flutter build web --release` succeeds.
3. Run the built site in the in-app browser: no console errors; create a trip,
   a list, a shopping item; reload and confirm persistence (browser storage);
   backup save/load round-trips.
4. Confirm desktop Windows build still behaves identically (images intact).
5. User acceptance on-device: open `https://camp.<domain>`, Basic Auth prompt,
   Add to Home Screen, launch fullscreen with the mountain icon.

## Risks / open items

- **iOS PWA storage durability:** Safari can evict browser storage under storage
  pressure or long disuse. Mitigation: the backup file is the source of truth;
  document "export a backup periodically." (Acceptable given the no-backend
  decision.)
- **Subdomain name** not yet chosen — user to supply.
- **Basic Auth over the login** is single-credential; fine for a private
  single-user tool. Can be upgraded (Authelia/OAuth) later if needed.
