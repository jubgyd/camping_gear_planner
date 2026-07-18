import 'category.dart';
import 'item.dart';
import 'item_status.dart';
import 'trip_meta.dart';

/// A single camping event with its checklist and metadata (GDD §2, §4 + the
/// design plan's trip attributes: destination, season, style, budget, dates).
class Trip {
  const Trip({
    required this.id,
    required this.name,
    this.subtitle = '',
    this.countryCode,
    this.seasonKey,
    this.campStyleKey,
    this.typeKey = 'solo',
    this.budget,
    this.startDate,
    this.endDate,
    this.calendarSynced = false,
    this.reminderDaysBefore,
    this.archived = false,
    this.location = '',
    this.locationLink,
    this.weather = '',
    this.partySize,
    this.notes = '',
    this.categories = const [],
  });

  final String id;
  final String name;
  final String subtitle;

  final String? countryCode;
  final String? seasonKey;
  final String? campStyleKey;
  final String typeKey;

  final double? budget;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool calendarSynced;
  final int? reminderDaysBefore;
  final bool archived;

  /// Optional planning details (added schema v4).
  final String location; // campsite / place name
  final String? locationLink; // maps or booking URL
  final String weather; // free-text expected conditions
  final int? partySize; // exact headcount
  final String notes; // free-text trip notes

  final List<Category> categories;

  // Resolved metadata objects (null if unset / unknown code).
  Country? get country => Country.byCode(countryCode);
  Season? get season => Season.byKey(seasonKey);
  CampStyle? get campStyle => CampStyle.byKey(campStyleKey);
  TripType? get type => TripType.byKey(typeKey);

  Iterable<Item> get _allItems => categories.expand((c) => c.items);

  int get totalCount => _allItems.length;
  int get ownedCount =>
      _allItems.where((i) => i.status == ItemStatus.owned).length;

  /// Readiness: owned / total item count (design plan `tripStats.pct`).
  double get readyFraction => totalCount == 0 ? 0 : ownedCount / totalCount;
  int get readyPercent => (readyFraction * 100).round();

  /// Weight of owned items only — what you'd actually be carrying (GDD §11).
  int get ownedWeightGrams => _allItems
      .where((i) => i.status == ItemStatus.owned)
      .fold(0, (s, i) => s + i.totalWeightGrams);

  /// Full projected pack weight (design plan sums all items).
  int get fullWeightGrams =>
      _allItems.fold(0, (s, i) => s + i.totalWeightGrams);

  /// Money already committed on owned items (design plan `tripBudgetStats`).
  double get spent => _allItems
      .where((i) => i.status == ItemStatus.owned)
      .fold(0.0, (s, i) => s + (i.totalPrice ?? 0));

  /// Owned + still-to-buy — the projected total spend.
  double get projected => _allItems
      .where((i) =>
          i.status == ItemStatus.owned || i.status == ItemStatus.needToBuy)
      .fold(0.0, (s, i) => s + (i.totalPrice ?? 0));

  Trip copyWith({
    String? name,
    String? subtitle,
    String? Function()? countryCode,
    String? Function()? seasonKey,
    String? Function()? campStyleKey,
    String? typeKey,
    double? Function()? budget,
    DateTime? Function()? startDate,
    DateTime? Function()? endDate,
    bool? calendarSynced,
    int? Function()? reminderDaysBefore,
    bool? archived,
    String? location,
    String? Function()? locationLink,
    String? weather,
    int? Function()? partySize,
    String? notes,
    List<Category>? categories,
  }) {
    return Trip(
      id: id,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      countryCode: countryCode != null ? countryCode() : this.countryCode,
      seasonKey: seasonKey != null ? seasonKey() : this.seasonKey,
      campStyleKey: campStyleKey != null ? campStyleKey() : this.campStyleKey,
      typeKey: typeKey ?? this.typeKey,
      budget: budget != null ? budget() : this.budget,
      startDate: startDate != null ? startDate() : this.startDate,
      endDate: endDate != null ? endDate() : this.endDate,
      calendarSynced: calendarSynced ?? this.calendarSynced,
      reminderDaysBefore: reminderDaysBefore != null
          ? reminderDaysBefore()
          : this.reminderDaysBefore,
      archived: archived ?? this.archived,
      location: location ?? this.location,
      locationLink: locationLink != null ? locationLink() : this.locationLink,
      weather: weather ?? this.weather,
      partySize: partySize != null ? partySize() : this.partySize,
      notes: notes ?? this.notes,
      categories: categories ?? this.categories,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subtitle': subtitle,
        'countryCode': countryCode,
        'seasonKey': seasonKey,
        'campStyleKey': campStyleKey,
        'typeKey': typeKey,
        'budget': budget,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'calendarSynced': calendarSynced,
        'reminderDaysBefore': reminderDaysBefore,
        'archived': archived,
        'location': location,
        'locationLink': locationLink,
        'weather': weather,
        'partySize': partySize,
        'notes': notes,
        'categories': categories.map((c) => c.toJson()).toList(),
      };

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        countryCode: json['countryCode'] as String?,
        seasonKey: json['seasonKey'] as String?,
        campStyleKey: json['campStyleKey'] as String?,
        typeKey: json['typeKey'] as String? ?? 'solo',
        budget: (json['budget'] as num?)?.toDouble(),
        startDate: json['startDate'] != null
            ? DateTime.tryParse(json['startDate'] as String)
            : null,
        endDate: json['endDate'] != null
            ? DateTime.tryParse(json['endDate'] as String)
            : null,
        calendarSynced: json['calendarSynced'] as bool? ?? false,
        reminderDaysBefore: (json['reminderDaysBefore'] as num?)?.toInt(),
        archived: json['archived'] as bool? ?? false,
        location: json['location'] as String? ?? '',
        locationLink: json['locationLink'] as String?,
        weather: json['weather'] as String? ?? '',
        partySize: (json['partySize'] as num?)?.toInt(),
        notes: json['notes'] as String? ?? '',
        categories: (json['categories'] as List<dynamic>? ?? [])
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
