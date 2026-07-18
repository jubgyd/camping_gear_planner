import 'gear_item.dart';
import 'packing_list.dart';
import 'shopping_entry.dart';
import 'template.dart';
import 'trip.dart';

/// User-level preferences persisted alongside the data (design plan: Settings
/// tab language + appearance).
class AppSettings {
  const AppSettings({this.darkMode = false, this.language = 'de'});

  final bool darkMode;
  final String language;

  AppSettings copyWith({bool? darkMode, String? language}) => AppSettings(
        darkMode: darkMode ?? this.darkMode,
        language: language ?? this.language,
      );

  Map<String, dynamic> toJson() => {'darkMode': darkMode, 'language': language};

  factory AppSettings.fromJson(Map<String, dynamic>? json) => AppSettings(
        darkMode: json?['darkMode'] as bool? ?? false,
        language: json?['language'] as String? ?? 'de',
      );
}

/// Root aggregate holding all app state. Its JSON shape doubles as the
/// export/import wire format (GDD §12); [schemaVersion] is bumped whenever the
/// data model changes to keep future imports safe.
class AppData {
  const AppData({
    this.schemaVersion = currentSchemaVersion,
    this.exportedAt,
    this.trips = const [],
    this.templateLibrary = const [],
    this.manualEntries = const [],
    this.gearLibrary = const [],
    this.packingLists = const [],
    this.settings = const AppSettings(),
  });

  static const int currentSchemaVersion = 4;

  final int schemaVersion;
  final DateTime? exportedAt;
  final List<Trip> trips;
  final List<TemplateCategory> templateLibrary;

  /// Free-standing manual shopping entries; trip-linked lines are derived live.
  final List<ManualEntry> manualEntries;

  /// The user's personal gear catalog ("My Gear"), hand-curated.
  final List<GearItem> gearLibrary;

  /// Custom reusable starting lists saved off trips (builtin lists come from a
  /// provider and are not persisted here).
  final List<PackingList> packingLists;

  final AppSettings settings;

  AppData copyWith({
    List<Trip>? trips,
    List<TemplateCategory>? templateLibrary,
    List<ManualEntry>? manualEntries,
    List<GearItem>? gearLibrary,
    List<PackingList>? packingLists,
    AppSettings? settings,
  }) {
    return AppData(
      schemaVersion: schemaVersion,
      exportedAt: exportedAt,
      trips: trips ?? this.trips,
      templateLibrary: templateLibrary ?? this.templateLibrary,
      manualEntries: manualEntries ?? this.manualEntries,
      gearLibrary: gearLibrary ?? this.gearLibrary,
      packingLists: packingLists ?? this.packingLists,
      settings: settings ?? this.settings,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': schemaVersion,
        'exportedAt': (exportedAt ?? DateTime.now().toUtc()).toIso8601String(),
        'trips': trips.map((t) => t.toJson()).toList(),
        'templateLibrary': templateLibrary.map((c) => c.toJson()).toList(),
        'manualEntries': manualEntries.map((e) => e.toJson()).toList(),
        'gearLibrary': gearLibrary.map((g) => g.toJson()).toList(),
        'packingLists': packingLists.map((l) => l.toJson()).toList(),
        'settings': settings.toJson(),
      };

  factory AppData.fromJson(Map<String, dynamic> json) => AppData(
        schemaVersion:
            (json['version'] as num?)?.toInt() ?? currentSchemaVersion,
        exportedAt: json['exportedAt'] != null
            ? DateTime.tryParse(json['exportedAt'] as String)
            : null,
        trips: (json['trips'] as List<dynamic>? ?? [])
            .map((e) => Trip.fromJson(e as Map<String, dynamic>))
            .toList(),
        templateLibrary: (json['templateLibrary'] as List<dynamic>? ?? [])
            .map((e) => TemplateCategory.fromJson(e as Map<String, dynamic>))
            .toList(),
        manualEntries: (json['manualEntries'] as List<dynamic>? ?? [])
            .map((e) => ManualEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        gearLibrary: (json['gearLibrary'] as List<dynamic>? ?? [])
            .map((e) => GearItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        packingLists: (json['packingLists'] as List<dynamic>? ?? [])
            .map((e) => PackingList.fromJson(e as Map<String, dynamic>))
            .toList(),
        settings: AppSettings.fromJson(json['settings'] as Map<String, dynamic>?),
      );
}
