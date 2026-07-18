import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/packing_lists.dart';
import '../data/prefs_repository.dart';
import '../data/repository.dart';
import '../data/starter_gear.dart';
import '../data/suggestion_provider.dart';
import '../models/app_data.dart';
import '../models/category.dart';
import '../models/gear_item.dart';
import '../models/item.dart';
import '../models/item_status.dart';
import '../models/packing_list.dart';
import '../models/shopping_entry.dart';
import '../models/template.dart';
import '../models/trip.dart';
import '../util/format.dart';

const _uuid = Uuid();

/// Swap this single override to change persistence backends (GDD §13).
final repositoryProvider = Provider<Repository>((ref) => PrefsRepository());

final suggestionProvider = Provider<SuggestionProvider>(
  (ref) => const StaticSuggestionProvider(),
);

/// Owns the entire [AppData] tree. Screens read derived slices and call mutation
/// methods here; every mutation rebuilds the immutable tree and persists.
final appDataProvider =
    AsyncNotifierProvider<AppController, AppData>(AppController.new);

/// Convenience: current [ThemeMode] from persisted settings (light until loaded).
final themeModeProvider = Provider<ThemeMode>((ref) {
  final data = ref.watch(appDataProvider).valueOrNull;
  return (data?.settings.darkMode ?? false) ? ThemeMode.dark : ThemeMode.light;
});

/// All starting lists offered at trip creation: built-in premades first, then
/// the user's saved custom lists.
final availableListsProvider = Provider<List<PackingList>>((ref) {
  final custom = ref.watch(appDataProvider).valueOrNull?.packingLists ??
      const <PackingList>[];
  return [...builtinPackingLists(), ...custom];
});

class AppController extends AsyncNotifier<AppData> {
  @override
  Future<AppData> build() async {
    final repo = ref.read(repositoryProvider);
    var data = await repo.load();
    if (data.trips.isEmpty && data.templateLibrary.isEmpty) {
      data = data.copyWith(
        templateLibrary: ref.read(suggestionProvider).starterLibrary(),
        // Pre-fill "My Gear" once on a fresh install so it isn't empty; after
        // this the catalog is manual-only (won't re-seed if the user clears it).
        gearLibrary: data.gearLibrary.isEmpty ? starterGear() : data.gearLibrary,
      );
    }
    // Auto-archive trips whose end date has already passed (design plan).
    final now = DateTime.now();
    final archived = data.trips.map((t) {
      if (t.archived || t.endDate == null) return t;
      final cd = daysUntil(t.startDate, t.endDate, now: now);
      return cd?.state == CountdownState.past
          ? t.copyWith(archived: true)
          : t;
    }).toList();
    data = data.copyWith(trips: archived);
    await repo.save(data);
    return data;
  }

  Future<void> _update(AppData Function(AppData) transform) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final next = transform(current);
    state = AsyncData(next);
    await ref.read(repositoryProvider).save(next);
  }

  // ---- Trips -------------------------------------------------------------

  Future<void> addTrip(Trip trip) =>
      _update((d) => d.copyWith(trips: [...d.trips, trip]));

  Future<void> renameTrip(String tripId, String name) =>
      _update((d) => _mapTrip(d, tripId, (t) => t.copyWith(name: name)));

  Future<void> deleteTrip(String tripId) => _update(
      (d) => d.copyWith(trips: d.trips.where((t) => t.id != tripId).toList()));

  Future<void> setArchived(String tripId, bool archived) => _update(
      (d) => _mapTrip(d, tripId, (t) => t.copyWith(archived: archived)));

  Future<void> setBudget(String tripId, double? budget) => _update(
      (d) => _mapTrip(d, tripId, (t) => t.copyWith(budget: () => budget)));

  Future<void> setDates(String tripId, DateTime? start, DateTime? end) =>
      _update((d) => _mapTrip(d, tripId,
          (t) => t.copyWith(startDate: () => start, endDate: () => end)));

  Future<void> setCalendarSynced(String tripId, bool synced) => _update(
      (d) => _mapTrip(d, tripId, (t) => t.copyWith(calendarSynced: synced)));

  Future<void> setReminderDays(String tripId, int? days) => _update((d) =>
      _mapTrip(d, tripId, (t) => t.copyWith(reminderDaysBefore: () => days)));

  /// Replace a trip's editable metadata in one shot (the edit form). Keeps the
  /// checklist (categories) and archived flag untouched.
  Future<void> updateTripMeta(
    String tripId, {
    required String name,
    required String subtitle,
    required String? countryCode,
    required String? seasonKey,
    required String? campStyleKey,
    required String typeKey,
    required double? budget,
    required DateTime? startDate,
    required DateTime? endDate,
    required bool calendarSynced,
    required int? reminderDaysBefore,
  }) =>
      _update((d) => _mapTrip(d, tripId, (t) => t.copyWith(
            name: name,
            subtitle: subtitle,
            countryCode: () => countryCode,
            seasonKey: () => seasonKey,
            campStyleKey: () => campStyleKey,
            typeKey: typeKey,
            budget: () => budget,
            startDate: () => startDate,
            endDate: () => endDate,
            calendarSynced: calendarSynced,
            reminderDaysBefore: () => reminderDaysBefore,
          )));

  // ---- Categories & items ------------------------------------------------

  Future<void> addCategory(String tripId, String name) =>
      _update((d) => _mapTrip(d, tripId, (t) {
            return t.copyWith(categories: [
              ...t.categories,
              Category(id: _uuid.v4(), name: name, order: t.categories.length),
            ]);
          }));

  Future<void> toggleCategoryCollapsed(String tripId, String categoryId) =>
      _update((d) => _mapCategory(d, tripId, categoryId,
          (c) => c.copyWith(collapsed: !c.collapsed)));

  Future<void> addItem(String tripId, String categoryId, Item item) =>
      _update((d) => _mapCategory(
          d, tripId, categoryId, (c) => c.copyWith(items: [...c.items, item])));

  Future<void> updateItem(String tripId, String categoryId, Item updated) =>
      _update((d) => _mapCategory(
            d,
            tripId,
            categoryId,
            (c) => c.copyWith(
                items:
                    c.items.map((i) => i.id == updated.id ? updated : i).toList()),
          ));

  Future<void> setItemStatus(
    String tripId,
    String categoryId,
    String itemId,
    ItemStatus status,
  ) =>
      _update((d) => _mapCategory(
            d,
            tripId,
            categoryId,
            (c) => c.copyWith(
              items: c.items
                  .map((i) =>
                      i.id == itemId ? i.copyWith(status: status) : i)
                  .toList(),
            ),
          ));

  /// Marking a shopping line bought flips its trip item to owned (design plan).
  Future<void> markItemOwned(String tripId, String categoryId, String itemId) =>
      setItemStatus(tripId, categoryId, itemId, ItemStatus.owned);

  /// Copies a template item into a trip: appends to a category of the same name
  /// if one exists, otherwise creates it (design plan `addTemplateItemToTrip`).
  Future<void> addFromTemplate(
    String tripId,
    String categoryName,
    TemplateItem tpl,
  ) =>
      _update((d) => _mapTrip(
            d,
            tripId,
            (t) => _addItemToNamedCategory(
              t,
              categoryName,
              Item(
                id: _uuid.v4(),
                name: tpl.name,
                note: tpl.note,
                link: tpl.link,
                weightGrams: tpl.weightGrams,
                status: ItemStatus.needToBuy,
                sourceTemplateId: tpl.id,
              ),
            ),
          ));

  /// Adds a catalog gear item into a trip, in its own [GearItem.category].
  Future<void> addGearToTrip(String tripId, GearItem gear) =>
      _update((d) => _mapTrip(
            d,
            tripId,
            (t) => _addItemToNamedCategory(
              t,
              gear.category,
              Item(
                id: _uuid.v4(),
                name: gear.name,
                note: gear.note,
                link: gear.link,
                weightGrams: gear.weightGrams,
                pricePerUnit: gear.pricePerUnit,
                status: ItemStatus.needToBuy,
              ),
            ),
          ));

  /// Seeds a trip's whole checklist from a [PackingList] (blank/premade/custom
  /// choice at trip creation). Items land as need-to-buy.
  Future<void> applyListToTrip(String tripId, PackingList list) =>
      _update((d) => _mapTrip(d, tripId, (t) {
            var trip = t;
            for (final cat in list.categories) {
              for (final tpl in cat.items) {
                trip = _addItemToNamedCategory(
                  trip,
                  cat.name,
                  Item(
                    id: _uuid.v4(),
                    name: tpl.name,
                    note: tpl.note,
                    link: tpl.link,
                    weightGrams: tpl.weightGrams,
                    status: ItemStatus.needToBuy,
                    sourceTemplateId: tpl.id,
                  ),
                );
              }
            }
            return trip;
          }));

  // ---- Gear catalog ("My Gear") ------------------------------------------

  Future<void> addGearItem(GearItem gear) =>
      _update((d) => d.copyWith(gearLibrary: [...d.gearLibrary, gear]));

  Future<void> updateGearItem(GearItem gear) => _update((d) => d.copyWith(
      gearLibrary:
          d.gearLibrary.map((g) => g.id == gear.id ? gear : g).toList()));

  Future<void> deleteGearItem(String id) => _update((d) => d.copyWith(
      gearLibrary: d.gearLibrary.where((g) => g.id != id).toList()));

  // ---- Custom lists ------------------------------------------------------

  /// Snapshots a trip's checklist into a reusable custom list (design plan
  /// "Save as list"). Captures every item regardless of status.
  Future<void> saveTripAsList(String tripId, String name,
          {String description = ''}) =>
      _update((d) {
        final trip = d.trips.firstWhereOrNull((t) => t.id == tripId);
        if (trip == null) return d;
        final cats = trip.categories
            .map((c) => TemplateCategory(
                  id: _uuid.v4(),
                  name: c.name,
                  order: c.order,
                  items: c.items
                      .map((i) => TemplateItem(
                            id: _uuid.v4(),
                            name: i.name,
                            note: i.note,
                            link: i.link,
                            weightGrams: i.weightGrams,
                          ))
                      .toList(),
                ))
            .toList();
        return d.copyWith(packingLists: [
          ...d.packingLists,
          PackingList(
              id: _uuid.v4(),
              name: name,
              description: description,
              categories: cats),
        ]);
      });

  Future<void> deletePackingList(String id) => _update((d) => d.copyWith(
      packingLists: d.packingLists.where((l) => l.id != id).toList()));

  // ---- Manual shopping entries -------------------------------------------

  Future<void> addManualEntry(ManualEntry entry) => _update(
      (d) => d.copyWith(manualEntries: [...d.manualEntries, entry]));

  Future<void> updateManualEntry(ManualEntry updated) => _update((d) =>
      d.copyWith(
          manualEntries: d.manualEntries
              .map((e) => e.id == updated.id ? updated : e)
              .toList()));

  Future<void> setManualBought(String id, bool bought) => _update((d) =>
      d.copyWith(
          manualEntries: d.manualEntries
              .map((e) => e.id == id ? e.copyWith(bought: bought) : e)
              .toList()));

  // ---- Import (GDD §12) --------------------------------------------------

  /// Replace-all import: wipes current data, loads [incoming]. Returns the
  /// number of trips loaded.
  Future<int> replaceAll(AppData incoming) async {
    await _update((_) => incoming);
    return incoming.trips.length;
  }

  /// Merge import: adds trips and template categories from [incoming] whose ids
  /// aren't already present, skipping duplicates. Returns the count of new trips.
  Future<int> mergeFrom(AppData incoming) async {
    var added = 0;
    await _update((d) {
      final tripIds = d.trips.map((t) => t.id).toSet();
      final newTrips = incoming.trips.where((t) => !tripIds.contains(t.id)).toList();
      added = newTrips.length;
      final tplIds = d.templateLibrary.map((c) => c.id).toSet();
      final newTpl = incoming.templateLibrary
          .where((c) => !tplIds.contains(c.id))
          .toList();
      final gearIds = d.gearLibrary.map((g) => g.id).toSet();
      final newGear =
          incoming.gearLibrary.where((g) => !gearIds.contains(g.id)).toList();
      final listIds = d.packingLists.map((l) => l.id).toSet();
      final newLists =
          incoming.packingLists.where((l) => !listIds.contains(l.id)).toList();
      return d.copyWith(
        trips: [...d.trips, ...newTrips],
        templateLibrary: [...d.templateLibrary, ...newTpl],
        gearLibrary: [...d.gearLibrary, ...newGear],
        packingLists: [...d.packingLists, ...newLists],
      );
    });
    return added;
  }

  // ---- Settings ----------------------------------------------------------

  Future<void> setDarkMode(bool dark) => _update(
      (d) => d.copyWith(settings: d.settings.copyWith(darkMode: dark)));

  Future<void> setLanguage(String lang) => _update(
      (d) => d.copyWith(settings: d.settings.copyWith(language: lang)));

  // ---- Immutable-tree helpers -------------------------------------------

  /// Appends [item] to the trip's category named [categoryName], creating that
  /// category if it doesn't exist. Shared by template/gear/list insertion.
  Trip _addItemToNamedCategory(Trip t, String categoryName, Item item) {
    final existing =
        t.categories.firstWhereOrNull((c) => c.name == categoryName);
    if (existing != null) {
      return t.copyWith(
        categories: t.categories
            .map((c) =>
                c.id == existing.id ? c.copyWith(items: [...c.items, item]) : c)
            .toList(),
      );
    }
    return t.copyWith(categories: [
      ...t.categories,
      Category(
          id: _uuid.v4(),
          name: categoryName,
          order: t.categories.length,
          items: [item]),
    ]);
  }

  AppData _mapTrip(AppData d, String tripId, Trip Function(Trip) fn) =>
      d.copyWith(
          trips: d.trips.map((t) => t.id == tripId ? fn(t) : t).toList());

  AppData _mapCategory(
    AppData d,
    String tripId,
    String categoryId,
    Category Function(Category) fn,
  ) =>
      _mapTrip(
        d,
        tripId,
        (t) => t.copyWith(
            categories: t.categories
                .map((c) => c.id == categoryId ? fn(c) : c)
                .toList()),
      );
}
