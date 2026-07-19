# Private iPhone Web App (PWA on Hetzner) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the existing Camp Gear Planner as a private, installable iPhone web app (PWA), served from the user's Hetzner CX23 behind Caddy + Basic Auth, with the Windows desktop build behaviourally unchanged.

**Architecture:** Flutter already targets web for everything except the product-image feature, which uses `dart:io` + `path_provider`. Move those two files behind the same conditional-import facade pattern the project already uses for `lib/util/file_access.dart` (`_io` / `_web` / `_stub` selected by `dart.library.io` / `dart.library.html`). The web variants no-op, so images cleanly disappear on web while desktop keeps the real implementation. Then configure the PWA manifest + iOS home-screen icons, build the static `build/web`, and serve it from Hetzner via Caddy (auto-HTTPS) behind HTTP Basic Auth.

**Tech Stack:** Flutter web (Flutter 3.44.x at `D:\Flutter\flutter\bin\flutter.bat`), Dart conditional imports, Python Pillow (already installed) for icon resizing, Caddy web server on Hetzner (Ubuntu), OpenSSH `scp` for deploy.

## Global Constraints

- Flutter binary: `D:\Flutter\flutter\bin\flutter.bat`; Dart: `D:\Flutter\flutter\bin\dart.bat`. Neither is on PATH — always use the full path.
- Git binary: `D:\Git\cmd\git.exe`. Every commit ends with the trailer:
  `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`
- Work in `D:\Camping gear app\camp_gear_planner` (a git repo, branch `main`).
- **Desktop build must not change behaviour.** All web-specific code lives in `_web`/`_stub` variant files; the `_io` variant is byte-for-byte today's logic.
- The active data repository is `PrefsRepository` (shared_preferences) — do not touch it; it already works on web.
- Brand palette (light): background `#EDEFE5`, dark header/ink `#23291D`, moss `#4B6A4A`. Use these for PWA colors and icon backgrounds.
- No new runtime dependencies. No backend, no accounts (per approved spec).
- After each code task: `flutter analyze` clean and `flutter test` green before committing.

---

### Task 1: Move `ImageStore` behind a conditional-import facade

Splits the singleton so the web build never imports `dart:io`/`path_provider`. Public API is identical on all platforms; the web/stub variants no-op and return null, which every caller already treats as "no image".

**Files:**
- Create: `lib/util/image_store_io.dart` (the current implementation, moved verbatim)
- Create: `lib/util/image_store_web.dart` (no-op variant)
- Create: `lib/util/image_store_stub.dart` (no-op fallback)
- Modify (replace whole file): `lib/util/image_store.dart` → becomes the export facade
- No call-site changes: `main.dart`, `item_edit_screen.dart`, `product_thumb_io.dart` keep `import '.../image_store.dart'` and use `ImageStore.instance`.

**Interfaces:**
- Produces: `class ImageStore` with `static final ImageStore instance`, and instance members:
  - `String? get dirPath`
  - `Future<void> init()`
  - `String? pathFor(String filename)`
  - `Future<String?> download(String url, {required String basename})`
  - `Future<String?> importFile(String sourcePath, {required String basename})`
  - `Future<void> delete(String? filename)`
  These signatures are IDENTICAL across `_io`, `_web`, and `_stub`.

- [ ] **Step 1: Create `lib/util/image_store_io.dart` with the current implementation**

Copy the entire current body of `lib/util/image_store.dart` (the `import 'dart:io';` / `http` / `path_provider` version, class `ImageStore` with all methods) into a new file `lib/util/image_store_io.dart`, unchanged. This is the desktop/mobile implementation.

- [ ] **Step 2: Create `lib/util/image_store_web.dart` (no-op)**

```dart
// Web build: there is no local filesystem, so the product-image feature is
// inert. Every method matches the IO signature but does nothing and returns
// null, which callers already interpret as "no image". No dart:io import.

class ImageStore {
  ImageStore._();
  static final ImageStore instance = ImageStore._();

  /// Always null on web — no on-disk image directory exists.
  String? get dirPath => null;

  /// Nothing to resolve; succeeds so startup code can await it unconditionally.
  Future<void> init() async {}

  /// No stored images on web.
  String? pathFor(String filename) => null;

  /// Image download is disabled on web (v1); reports "no image".
  Future<String?> download(String url, {required String basename}) async => null;

  /// Local file import is disabled on web (v1); reports "no image".
  Future<String?> importFile(String sourcePath,
          {required String basename}) async =>
      null;

  /// Nothing to delete on web.
  Future<void> delete(String? filename) async {}
}
```

- [ ] **Step 3: Create `lib/util/image_store_stub.dart` (fallback, identical no-op)**

```dart
// Fallback used only if neither dart:io nor dart:html is available. Mirrors the
// web no-op so the app still compiles and the image feature is simply inert.

class ImageStore {
  ImageStore._();
  static final ImageStore instance = ImageStore._();

  String? get dirPath => null;
  Future<void> init() async {}
  String? pathFor(String filename) => null;
  Future<String?> download(String url, {required String basename}) async => null;
  Future<String?> importFile(String sourcePath,
          {required String basename}) async =>
      null;
  Future<void> delete(String? filename) async {}
}
```

- [ ] **Step 4: Replace `lib/util/image_store.dart` with the export facade**

Replace the ENTIRE file contents with:

```dart
// Platform-selecting facade for the product-image store.
//
// Desktop/mobile (dart.library.io) get the real on-disk implementation; the web
// build (dart.library.html) gets a no-op so no `dart:io`/`path_provider` code is
// pulled into the browser bundle. UI code imports only this file and uses
// `ImageStore.instance`.
export 'image_store_stub.dart'
    if (dart.library.io) 'image_store_io.dart'
    if (dart.library.html) 'image_store_web.dart';
```

- [ ] **Step 5: Verify desktop still analyzes and tests pass**

Run: `cd "D:\Camping gear app\camp_gear_planner" && "D:\Flutter\flutter\bin\flutter.bat" analyze`
Expected: `No issues found!`

Run: `"D:\Flutter\flutter\bin\flutter.bat" test`
Expected: All tests pass (same count as before — 40).

- [ ] **Step 6: Commit**

```bash
"D:/Git/cmd/git.exe" add lib/util/image_store.dart lib/util/image_store_io.dart lib/util/image_store_web.dart lib/util/image_store_stub.dart
"D:/Git/cmd/git.exe" commit -m "Split ImageStore behind io/web/stub facade for web build

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 2: Move `ProductThumb` behind a conditional-import facade

`ProductThumb` uses `Image.file(File(...))` (`dart:io`), so its top-level `import 'dart:io'` blocks web compilation even though it returns nothing when there's no path. Split it the same way; the web/stub widget always renders `SizedBox.shrink()`.

**Files:**
- Create: `lib/widgets/product_thumb_io.dart` (current implementation, moved verbatim)
- Create: `lib/widgets/product_thumb_web.dart` (renders nothing)
- Create: `lib/widgets/product_thumb_stub.dart` (renders nothing)
- Modify (replace whole file): `lib/widgets/product_thumb.dart` → export facade
- No call-site changes: `trip_detail_screen.dart:615`, `shopping_screen.dart:341`, `item_edit_screen.dart:356` keep `import '../widgets/product_thumb.dart'`.

**Interfaces:**
- Consumes: `ImageStore` (from Task 1) in the `_io` variant only.
- Produces: `class ProductThumb extends StatelessWidget` with const constructor
  `const ProductThumb(String? filename, {Key? key, double size = 44, double radius = 8})`.
  Identical signature across `_io`, `_web`, `_stub`.

- [ ] **Step 1: Create `lib/widgets/product_thumb_io.dart` with the current implementation**

Copy the entire current body of `lib/widgets/product_thumb.dart` (the `import 'dart:io';` version with `Image.file`) into a new file `lib/widgets/product_thumb_io.dart`, unchanged.

- [ ] **Step 2: Create `lib/widgets/product_thumb_web.dart` (renders nothing)**

```dart
import 'package:flutter/material.dart';

/// Web build: product images are disabled (v1), so the thumbnail renders
/// nothing. Same constructor as the IO variant so call sites are identical.
class ProductThumb extends StatelessWidget {
  const ProductThumb(this.filename, {super.key, this.size = 44, this.radius = 8});

  final String? filename;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
```

- [ ] **Step 3: Create `lib/widgets/product_thumb_stub.dart` (identical to web)**

```dart
import 'package:flutter/material.dart';

/// Fallback: no image rendering. Mirrors the web variant.
class ProductThumb extends StatelessWidget {
  const ProductThumb(this.filename, {super.key, this.size = 44, this.radius = 8});

  final String? filename;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
```

- [ ] **Step 4: Replace `lib/widgets/product_thumb.dart` with the export facade**

Replace the ENTIRE file contents with:

```dart
// Platform-selecting facade for the product thumbnail widget.
//
// Desktop/mobile load the image from disk; the web build (v1) renders nothing.
// Call sites import only this file.
export 'product_thumb_stub.dart'
    if (dart.library.io) 'product_thumb_io.dart'
    if (dart.library.html) 'product_thumb_web.dart';
```

- [ ] **Step 5: Verify desktop still analyzes and tests pass**

Run: `"D:\Flutter\flutter\bin\flutter.bat" analyze`
Expected: `No issues found!`

Run: `"D:\Flutter\flutter\bin\flutter.bat" test`
Expected: All tests pass (40).

- [ ] **Step 6: Commit**

```bash
"D:/Git/cmd/git.exe" add lib/widgets/product_thumb.dart lib/widgets/product_thumb_io.dart lib/widgets/product_thumb_web.dart lib/widgets/product_thumb_stub.dart
"D:/Git/cmd/git.exe" commit -m "Split ProductThumb behind io/web/stub facade for web build

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 3: Hide the image controls in the item editor on web

The image no-ops now compile, but the "Choose from computer" / "Remove image" buttons would still appear on web and do nothing. Gate the whole controls block behind `!kIsWeb` so web users never see dead buttons. (`kIsWeb` is exported by `package:flutter/material.dart`, already imported in this file.)

**Files:**
- Modify: `lib/screens/item_edit_screen.dart` (the image-controls `Padding` block, currently around lines 345–375)

**Interfaces:**
- Consumes: `kIsWeb` (from `package:flutter/foundation.dart`, re-exported by material).
- Produces: nothing new.

- [ ] **Step 1: Wrap the image-controls block in a `!kIsWeb` collection-if**

In `lib/screens/item_edit_screen.dart`, find this block (inside the editor's `Column` children):

```dart
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (_imageFile != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child:
                                  ProductThumb(_imageFile, size: 64, radius: 10),
                            ),
                          TextButton.icon(
                            onPressed: _pickImage,
                            icon: Icon(Icons.image_outlined,
                                size: 18, color: p.rust),
                            label: Text(context.t('item_pick_image'),
                                style: AppText.body(13, color: p.rust)),
                          ),
                          if (_imageFile != null)
                            TextButton.icon(
                              onPressed: _removeImage,
                              icon: Icon(Icons.close,
                                  size: 16, color: p.inkMuted),
                              label: Text(context.t('item_image_remove'),
                                  style: AppText.body(13, color: p.inkMuted)),
                            ),
                        ],
                      ),
                    ),
```

Change the opening line `Padding(` to `if (!kIsWeb)\n                      Padding(` so the entire block becomes a collection-if. The result:

```dart
                    if (!kIsWeb)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (_imageFile != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ProductThumb(_imageFile,
                                    size: 64, radius: 10),
                              ),
                            TextButton.icon(
                              onPressed: _pickImage,
                              icon: Icon(Icons.image_outlined,
                                  size: 18, color: p.rust),
                              label: Text(context.t('item_pick_image'),
                                  style: AppText.body(13, color: p.rust)),
                            ),
                            if (_imageFile != null)
                              TextButton.icon(
                                onPressed: _removeImage,
                                icon: Icon(Icons.close,
                                    size: 16, color: p.inkMuted),
                                label: Text(context.t('item_image_remove'),
                                    style: AppText.body(13, color: p.inkMuted)),
                              ),
                          ],
                        ),
                      ),
```

(Only the `if (!kIsWeb)` guard and the re-indentation change; the inner widgets are identical.)

- [ ] **Step 2: Analyze and test**

Run: `"D:\Flutter\flutter\bin\flutter.bat" analyze`
Expected: `No issues found!`

Run: `"D:\Flutter\flutter\bin\flutter.bat" test`
Expected: All tests pass (40) — desktop widget tree unchanged because `kIsWeb` is false under the VM test runner.

- [ ] **Step 3: Commit**

```bash
"D:/Git/cmd/git.exe" add lib/screens/item_edit_screen.dart
"D:/Git/cmd/git.exe" commit -m "Hide product-image controls on web build

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 4: Verify the web build compiles and runs

First proof the code changes actually produce a working web app. This is the acceptance gate for Tasks 1–3 (a passing `flutter build web` is the real test for "no `dart:io` leaked into the web bundle").

**Files:** none (verification only).

- [ ] **Step 1: Enable web support if needed and confirm the device exists**

Run: `"D:\Flutter\flutter\bin\flutter.bat" config --enable-web`
Run: `"D:\Flutter\flutter\bin\flutter.bat" devices`
Expected: a `Chrome (web)` and/or `Web Server (web)` device is listed.

- [ ] **Step 2: Build the web release bundle**

Run: `"D:\Flutter\flutter\bin\flutter.bat" build web --release`
Expected: `√ Built build\web` with NO compile errors. If it fails with a `dart:io`/`dart:html` error, a facade in Task 1/2 leaked an IO import — fix the named file and rebuild.

- [ ] **Step 3: Serve the built bundle locally and smoke-test in the in-app browser**

Serve the static build on a local port (any static server; example uses Dart's):
Run: `"D:\Flutter\flutter\bin\dart.bat" pub global activate dhttpd` (once), then
Run in background from the build dir: `"D:\Flutter\flutter\bin\dart.bat" pub global run dhttpd --path build/web --port 8099`

Then use the browser tools (`preview_start` with `{url: "http://localhost:8099"}`), and:
- `read_console_messages` → expect no uncaught errors.
- Create a trip, a list, and a shopping item; confirm they render.
- Reload the page (`navigate` to the same URL) → data persists (shared_preferences → browser storage).
- Open Settings → Backup: confirm save/load controls appear.
- Open an item editor → confirm the image "Choose from computer"/"Remove" controls are ABSENT (web).

Fix any runtime error by editing source and rebuilding (back to Step 2).

- [ ] **Step 4: Confirm the Windows desktop build is unaffected**

Run: `"D:\Flutter\flutter\bin\flutter.bat" build windows --release`
Expected: builds successfully. (No need to reinstall here — this only proves the desktop path still compiles with the facades. Image controls remain present on desktop.)

- [ ] **Step 5: Commit (no code change — this is a checkpoint; skip if nothing changed)**

If Step 3 required source fixes, commit them:
```bash
"D:/Git/cmd/git.exe" add -A
"D:/Git/cmd/git.exe" commit -m "Fix web runtime issues found in smoke test

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 5: PWA manifest + iOS home-screen icons

Make the site installable to the iOS home screen as a standalone app with the mountain logo. Regenerate the web icons from `assets/icon/app_icon.png` (the current `web/icons/*` are the default Flutter icons), add a 180×180 `apple-touch-icon`, and set brand name/colors in `manifest.json` and `web/index.html`.

**Files:**
- Create (generated PNGs): `web/icons/Icon-192.png`, `web/icons/Icon-512.png`, `web/icons/Icon-maskable-192.png`, `web/icons/Icon-maskable-512.png`, `web/icons/apple-touch-icon.png`, `web/favicon.png` (overwrite existing)
- Modify (replace whole file): `web/manifest.json`
- Modify: `web/index.html` (head tags)
- Create (tooling): `scratchpad/gen_web_icons.py` (icon generator; not committed)

**Interfaces:** none (assets + static config).

- [ ] **Step 1: Write the icon generator script to scratchpad**

Create `C:\Users\owess\AppData\Local\Temp\claude\D--VISUAL-STUDIO\5402b732-ae59-483b-9153-2c8e9c283aec\scratchpad\gen_web_icons.py`:

```python
from PIL import Image
import os

SRC = r"D:\Camping gear app\camp_gear_planner\assets\icon\app_icon.png"
OUT = r"D:\Camping gear app\camp_gear_planner\web\icons"
FAVICON = r"D:\Camping gear app\camp_gear_planner\web\favicon.png"
BG = (0xED, 0xEF, 0xE5, 255)  # brand light background #EDEFE5

os.makedirs(OUT, exist_ok=True)
logo = Image.open(SRC).convert("RGBA")

def fit(size, pad_ratio):
    """Center the logo on the brand background at `size`, leaving `pad_ratio`
    padding on each side (used for maskable safe-zone and iOS icons)."""
    canvas = Image.new("RGBA", (size, size), BG)
    inner = int(size * (1 - 2 * pad_ratio))
    scaled = logo.copy()
    scaled.thumbnail((inner, inner), Image.LANCZOS)
    x = (size - scaled.width) // 2
    y = (size - scaled.height) // 2
    canvas.paste(scaled, (x, y), scaled)
    return canvas

# Standard "any" icons: small transparent padding, transparent background so
# they look crisp in browser tabs / Android launchers.
def any_icon(size):
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    inner = int(size * 0.92)
    scaled = logo.copy()
    scaled.thumbnail((inner, inner), Image.LANCZOS)
    canvas.paste(scaled, ((size - scaled.width) // 2, (size - scaled.height) // 2), scaled)
    return canvas

any_icon(192).save(os.path.join(OUT, "Icon-192.png"))
any_icon(512).save(os.path.join(OUT, "Icon-512.png"))
# Maskable: full-bleed brand background + ~12% safe-zone padding.
fit(192, 0.12).save(os.path.join(OUT, "Icon-maskable-192.png"))
fit(512, 0.12).save(os.path.join(OUT, "Icon-maskable-512.png"))
# iOS home-screen icon: solid background (iOS shows black behind transparency),
# 180x180, modest padding.
fit(180, 0.10).convert("RGB").save(os.path.join(OUT, "apple-touch-icon.png"))
# Favicon.
any_icon(32).save(FAVICON)
print("web icons generated")
```

- [ ] **Step 2: Run the generator**

Run: `python "C:\Users\owess\AppData\Local\Temp\claude\D--VISUAL-STUDIO\5402b732-ae59-483b-9153-2c8e9c283aec\scratchpad\gen_web_icons.py"`
Expected: `web icons generated`, and the six PNGs exist under `web/icons/` + `web/favicon.png`.

- [ ] **Step 3: Replace `web/manifest.json`**

Replace the ENTIRE file with:

```json
{
    "name": "Camp Gear Planner",
    "short_name": "Camp Gear",
    "start_url": ".",
    "display": "standalone",
    "background_color": "#EDEFE5",
    "theme_color": "#23291D",
    "description": "Plan camping trips — gear checklists, packing weight, budgets, and a shopping list.",
    "orientation": "portrait-primary",
    "prefer_related_applications": false,
    "icons": [
        {
            "src": "icons/Icon-192.png",
            "sizes": "192x192",
            "type": "image/png"
        },
        {
            "src": "icons/Icon-512.png",
            "sizes": "512x512",
            "type": "image/png"
        },
        {
            "src": "icons/Icon-maskable-192.png",
            "sizes": "192x192",
            "type": "image/png",
            "purpose": "maskable"
        },
        {
            "src": "icons/Icon-maskable-512.png",
            "sizes": "512x512",
            "type": "image/png",
            "purpose": "maskable"
        }
    ]
}
```

- [ ] **Step 4: Add iOS meta tags to `web/index.html`**

Read `web/index.html`. In the `<head>` (Flutter's default already contains an `apple-mobile-web-app-*` line and an `apple-touch-icon` link pointing at `icons/Icon-192.png`), ensure exactly these tags are present — update the `apple-touch-icon` href to the new 180px icon and set the title/status-bar tags:

```html
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
  <meta name="apple-mobile-web-app-title" content="Camp Gear">
  <meta name="theme-color" content="#23291D">
  <link rel="apple-touch-icon" href="icons/apple-touch-icon.png">
```

Replace Flutter's existing `apple-touch-icon` line rather than adding a duplicate. Leave the `<base href="$FLUTTER_BASE_HREF">` line untouched.

- [ ] **Step 5: Rebuild web and verify the manifest/icons ship**

Run: `"D:\Flutter\flutter\bin\flutter.bat" build web --release`
Expected: build succeeds; `build/web/manifest.json` shows "Camp Gear Planner" and `build/web/icons/apple-touch-icon.png` exists.

Optionally re-serve (Task 4 Step 3) and confirm in the browser: the tab favicon is the mountain logo, and `read_page` / devtools shows no manifest errors.

- [ ] **Step 6: Commit**

```bash
"D:/Git/cmd/git.exe" add web/manifest.json web/index.html web/favicon.png web/icons
"D:/Git/cmd/git.exe" commit -m "Add PWA manifest, brand colors, and iOS home-screen icons

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 6: Hetzner deployment runbook + deploy script

Serve `build/web` from the CX23 via Caddy (auto-HTTPS) behind Basic Auth, and give the user a repeatable one-command deploy from Windows. Server steps run over SSH by the user (cannot be executed from this machine); they are captured as a committed runbook. On-device iPhone install is the final acceptance test.

**Files:**
- Create: `docs/deploy/hetzner-pwa.md` (server runbook)
- Create: `tool/deploy_web.ps1` (local build + upload script)

**Interfaces:** none.

- [ ] **Step 1: Write the deploy script `tool/deploy_web.ps1`**

```powershell
# Build the Flutter web release and upload it to the Hetzner server over scp.
# Usage:  ./tool/deploy_web.ps1 -Server root@camp.example.tld -Dest /var/www/camp
param(
    [Parameter(Mandatory = $true)][string]$Server,
    [string]$Dest = "/var/www/camp"
)
$flutter = "D:\Flutter\flutter\bin\flutter.bat"
& $flutter build web --release
if ($LASTEXITCODE -ne 0) { Write-Error "flutter build web failed"; exit 1 }

# Upload the contents of build/web into $Dest on the server.
# (-r recurses; the trailing /. copies the directory contents, not the folder.)
scp -r "build/web/." "${Server}:${Dest}/"
if ($LASTEXITCODE -ne 0) { Write-Error "scp upload failed"; exit 1 }
Write-Host "Deployed to ${Server}:${Dest}"
```

- [ ] **Step 2: Write the server runbook `docs/deploy/hetzner-pwa.md`**

````markdown
# Deploying Camp Gear Planner to Hetzner (CX23) as a private PWA

One-time server setup, then a one-command deploy from Windows. The app is a
static site (Flutter web build); Caddy serves it over HTTPS behind Basic Auth.

Replace `camp.example.tld` with your real subdomain and `<SERVER_IP>` with the
CX23's public IP throughout.

## 1. DNS (one time)
Create an `A` record: `camp.example.tld` → `<SERVER_IP>`. Wait until
`nslookup camp.example.tld` returns the server IP before continuing (needed for
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
camp.example.tld {
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
From the project folder:
```
./tool/deploy_web.ps1 -Server <user>@camp.example.tld -Dest /var/www/camp
```
(Uses OpenSSH `scp`, built into Windows 11. If key auth isn't set up, it prompts
for the server password.)

## 8. Install on iPhone (one time)
1. Open `https://camp.example.tld` in Safari; enter the Basic Auth user/password.
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
````

- [ ] **Step 3: Commit**

```bash
"D:/Git/cmd/git.exe" add tool/deploy_web.ps1 docs/deploy/hetzner-pwa.md
"D:/Git/cmd/git.exe" commit -m "Add Hetzner PWA deploy script and server runbook

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

- [ ] **Step 4: Push all commits**

```bash
"D:/Git/cmd/git.exe" push
```

- [ ] **Step 5: User acceptance (manual, on the user's server + iPhone)**

Hand the runbook to the user. Acceptance = following `docs/deploy/hetzner-pwa.md`:
the site loads over HTTPS behind the Basic Auth prompt, installs to the iPhone
home screen with the mountain icon, opens fullscreen, and a backup file saved on
Windows loads successfully in the phone app.

---

## Self-Review

**Spec coverage:**
- Web-compat (only blocker = images) → Tasks 1, 2, 3. ✓
- PWA manifest + apple-touch-icon + standalone → Task 5. ✓
- Hosting on Hetzner (DNS, Caddy, HTTPS, Basic Auth, deploy) → Task 6. ✓
- Verification (analyze/test/build web/desktop unaffected/on-device) → Tasks 4 & 6 Step 5. ✓
- No backend / per-device data / backup transfer → honored (no data code touched); documented in runbook. ✓
- Images skipped on web for v1 → Tasks 1–3 (no-op) + Task 3 (hidden UI). ✓
- Desktop unchanged → `_io` variants verbatim; Task 4 Step 4 rebuild check. ✓

**Placeholder scan:** No TBD/TODO. `camp.example.tld`, `<SERVER_IP>`, `<PASTE_BCRYPT_HASH_HERE>`, and the chosen password are deliberate user-supplied deployment values, called out as such in the runbook — not plan gaps.

**Type consistency:** `ImageStore` public API (`instance`, `dirPath`, `init`, `pathFor`, `download`, `importFile`, `delete`) is identical across all three variants and matches every call site found in `main.dart` and `item_edit_screen.dart`. `ProductThumb` constructor `(String? filename, {Key? key, double size, double radius})` is identical across variants and matches the three call sites. Facade export syntax matches the proven `file_access.dart` pattern.
