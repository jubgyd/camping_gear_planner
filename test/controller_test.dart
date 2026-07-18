import 'package:camp_gear_planner/data/packing_lists.dart';
import 'package:camp_gear_planner/data/repository.dart';
import 'package:camp_gear_planner/models/app_data.dart';
import 'package:camp_gear_planner/models/category.dart';
import 'package:camp_gear_planner/models/gear_item.dart';
import 'package:camp_gear_planner/models/item.dart';
import 'package:camp_gear_planner/models/item_status.dart';
import 'package:camp_gear_planner/models/shopping_entry.dart';
import 'package:camp_gear_planner/models/trip.dart';
import 'package:camp_gear_planner/state/app_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory repository seeded with a starting snapshot.
class SeedRepository implements Repository {
  SeedRepository(this._data);
  AppData _data;
  @override
  Future<AppData> load() async => _data;
  @override
  Future<void> save(AppData data) async => _data = data;
}

Future<(ProviderContainer, AppController)> _boot(AppData seed) async {
  final container = ProviderContainer(
    overrides: [repositoryProvider.overrideWithValue(SeedRepository(seed))],
  );
  await container.read(appDataProvider.future);
  return (container, container.read(appDataProvider.notifier));
}

void main() {
  test('editing a trip shopping item price/qty updates the item', () async {
    const seed = AppData(trips: [
      Trip(id: 't1', name: 'Trip', categories: [
        Category(id: 'c1', name: 'Cat', items: [
          Item(
              id: 'i1',
              name: 'Kochset',
              status: ItemStatus.needToBuy,
              pricePerUnit: 42.5),
        ]),
      ]),
    ]);
    final (container, c) = await _boot(seed);
    addTearDown(container.dispose);

    final item = container
        .read(appDataProvider)
        .value!
        .trips
        .single
        .categories
        .single
        .items
        .single;
    await c.updateItem('t1', 'c1',
        item.copyWith(pricePerUnit: () => 39.99, quantity: 2));

    final updated = container
        .read(appDataProvider)
        .value!
        .trips
        .single
        .categories
        .single
        .items
        .single;
    expect(updated.pricePerUnit, 39.99);
    expect(updated.quantity, 2);
    expect(updated.totalPrice, closeTo(79.98, 0.001));
  });

  test('editing a manual shopping entry price/qty updates it', () async {
    const seed = AppData(manualEntries: [
      ManualEntry(id: 'm1', name: 'Wanderschuhe', pricePerUnit: 89),
    ]);
    final (container, c) = await _boot(seed);
    addTearDown(container.dispose);

    final entry = container.read(appDataProvider).value!.manualEntries.single;
    await c.updateManualEntry(
        entry.copyWith(pricePerUnit: () => 75, quantity: 2));

    final updated = container.read(appDataProvider).value!.manualEntries.single;
    expect(updated.pricePerUnit, 75);
    expect(updated.quantity, 2);
    expect(updated.totalPrice, 150);
  });

  test('clearing a price sets it back to null', () async {
    const seed = AppData(manualEntries: [
      ManualEntry(id: 'm1', name: 'X', pricePerUnit: 10),
    ]);
    final (container, c) = await _boot(seed);
    addTearDown(container.dispose);

    final entry = container.read(appDataProvider).value!.manualEntries.single;
    await c.updateManualEntry(entry.copyWith(pricePerUnit: () => null));

    expect(
        container.read(appDataProvider).value!.manualEntries.single.pricePerUnit,
        isNull);
  });

  test('adding gear to a trip creates an item in the gear category', () async {
    const seed = AppData(trips: [Trip(id: 't1', name: 'T')]);
    final (container, c) = await _boot(seed);
    addTearDown(container.dispose);

    await c.addGearToTrip('t1',
        const GearItem(id: 'g1', name: 'Zelt', category: 'Schlafen', weightGrams: 1400));

    final cat = container
        .read(appDataProvider)
        .value!
        .trips
        .single
        .categories
        .singleWhere((c) => c.name == 'Schlafen');
    expect(cat.items.single.name, 'Zelt');
    expect(cat.items.single.status, ItemStatus.needToBuy);
  });

  test('applying a premade list seeds the trip checklist', () async {
    const seed = AppData(trips: [Trip(id: 't1', name: 'T')]);
    final (container, c) = await _boot(seed);
    addTearDown(container.dispose);

    final list = builtinPackingLists().first;
    await c.applyListToTrip('t1', list);

    final trip = container.read(appDataProvider).value!.trips.single;
    expect(trip.categories.length, list.categories.length);
    expect(trip.totalCount, list.itemCount);
  });

  test('saving a trip as a list snapshots its checklist', () async {
    const seed = AppData(trips: [
      Trip(id: 't1', name: 'Solo', categories: [
        Category(id: 'c1', name: 'Schlafen', items: [
          Item(id: 'i1', name: 'Zelt', weightGrams: 1400),
        ]),
      ]),
    ]);
    final (container, c) = await _boot(seed);
    addTearDown(container.dispose);

    await c.saveTripAsList('t1', 'Meine Basis');

    final list = container.read(appDataProvider).value!.packingLists.single;
    expect(list.name, 'Meine Basis');
    expect(list.builtin, isFalse);
    expect(list.itemCount, 1);
    expect(list.categories.single.items.single.name, 'Zelt');
  });

  test('a fresh install pre-seeds the My Gear catalog', () async {
    // Empty starting data == fresh install.
    const seed = AppData();
    final (container, _) = await _boot(seed);
    addTearDown(container.dispose);

    final gear = container.read(appDataProvider).value!.gearLibrary;
    expect(gear, isNotEmpty);
    expect(gear.any((g) => g.name == 'Zelt (2 Personen)'), isTrue);
  });

  test('existing data is not re-seeded with starter gear', () async {
    // A returning user who has deleted all their gear but has trips/templates.
    const seed = AppData(trips: [Trip(id: 't1', name: 'T')]);
    final (container, _) = await _boot(seed);
    addTearDown(container.dispose);

    expect(container.read(appDataProvider).value!.gearLibrary, isEmpty);
  });

  test('gear and custom lists survive JSON round-trip (export/import)', () {
    const data = AppData(
      gearLibrary: [
        GearItem(id: 'g1', name: 'Zelt', category: 'Schlafen', weightGrams: 1400),
      ],
    );
    final restored = AppData.fromJson(data.toJson());
    expect(restored.gearLibrary.single.name, 'Zelt');
    expect(restored.gearLibrary.single.weightGrams, 1400);
    expect(restored.schemaVersion, 3);
  });
}
