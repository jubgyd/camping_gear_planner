# Camp Gear Planner (Flutter)

Offline companion app for planning camping trips — gear checklists, packing
weight, and a shopping list. See [`../CampGear-GDD.md`](../CampGear-GDD.md) for
the full design.

## Status

Working **scaffold**: data model, persistence layer, state management, and the
four screens are in place and wired together. Windows + Android runner folders
are generated; dependencies resolve; `flutter analyze` is clean and
`flutter test` passes (model math, JSON round-trip, boot smoke test).

Built and verified with **Flutter 3.44.6 stable (Dart 3.12.2)**, installed at
`D:\Flutter\flutter` (not on the shell PATH — invoke via
`D:\Flutter\flutter\bin\flutter.bat`).

## Running it

```powershell
$flutter = "D:\Flutter\flutter\bin\flutter.bat"
Set-Location "camp_gear_planner"
& $flutter pub get
& $flutter run                 # pick a device
```

**Windows desktop** builds need Developer Mode enabled once (plugins use
symlinks): run `start ms-settings:developers` and toggle it on.

**Web** is already set up and verified — no system settings needed:

```powershell
& $flutter run -d chrome           # best for visual dev
# or a headless server:
& $flutter run -d web-server --web-port 8123
```

Note: Flutter 3.44 web renders via CanvasKit only (the HTML renderer was
removed). Persistence uses `shared_preferences` (`PrefsRepository`) rather than
the file-based `JsonRepository`, since `dart:io` isn't available on web; the
`Repository` seam (GDD §13) makes that a one-line swap. Native file export/import
goes through the conditional-import helpers in `lib/util/file_access*.dart`.

## Architecture

```
lib/
  main.dart                 App entry + theme
  app.dart                  Three-tab bottom-nav shell (Camps · Shopping · Settings)
  models/                   Immutable value types + JSON (Trip, Category, Item, …)
  data/
    repository.dart         Persistence interface (the single sync seam, GDD §13)
    json_repository.dart      → local JSON file implementation
    suggestion_provider.dart  Starter template library (swap for an LLM later, GDD §13)
  state/
    app_controller.dart     Riverpod AsyncNotifier — owns AppData, all mutations
  screens/                  Camps, trip checklist, item edit, templates, shopping, settings
  util/format.dart          Weight formatting + status glyphs
```

State management is **Riverpod**. All reads/writes go through `Repository`, so a
future "local + remote sync" backend is a one-class swap (GDD §13).

## Known TODOs left in the scaffold

- **Import merge/replace** (`settings_screen.dart`) parses, validates, and asks
  for a mode, but doesn't yet apply it — add `replaceAll` / `merge` methods to
  `AppController`.
- Category reordering (drag), trip rename/delete UI, and purchased-history view
  are stubbed or absent — logic exists in the controller where relevant.
