import '../models/app_data.dart';

/// The single seam between the app and persistence (GDD §13). Every screen
/// talks to this interface, never to `dart:io` directly — so swapping local
/// JSON for "local + remote sync" later is a one-class change.
abstract interface class Repository {
  /// Loads persisted data, or returns an empty [AppData] on first run.
  Future<AppData> load();

  /// Persists the full [AppData] snapshot.
  Future<void> save(AppData data);
}
