import 'package:camp_gear_planner/data/repository.dart';
import 'package:camp_gear_planner/models/app_data.dart';
import 'package:camp_gear_planner/models/category.dart';
import 'package:camp_gear_planner/models/item.dart';
import 'package:camp_gear_planner/models/item_status.dart';
import 'package:camp_gear_planner/models/shopping_entry.dart';
import 'package:camp_gear_planner/models/trip.dart';
import 'package:camp_gear_planner/state/app_controller.dart';
import 'package:camp_gear_planner/state/shopping_view.dart';
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

/// Two trips that both need to buy an item of the *same name* — the exact case
/// where a filter or a buy action could touch the wrong trip.
const _twoTrips = AppData(trips: [
  Trip(id: 't1', name: 'Norwegen', categories: [
    Category(id: 'c1', name: 'Schlafen', items: [
      Item(id: 'i1', name: 'Zelt', status: ItemStatus.needToBuy, pricePerUnit: 89),
    ]),
  ]),
  Trip(id: 't2', name: 'Ardennen', categories: [
    Category(id: 'c2', name: 'Schlafen', items: [
      Item(id: 'i2', name: 'Zelt', status: ItemStatus.needToBuy, pricePerUnit: 64),
    ]),
  ]),
], manualEntries: [
  ManualEntry(id: 'm1', name: 'Batterien'),
]);

void main() {
  group('buildShoppingGroups keeps each line bound to its own trip', () {
    test('one group per trip, keyed by trip id, plus Sonstiges', () {
      final groups = buildShoppingGroups(_twoTrips, ShoppingSort.trip);
      expect(groups.map((g) => g.key), ['t1', 't2', 'manual']);
      expect(groups.map((g) => g.name), ['Norwegen', 'Ardennen', 'Sonstiges']);
    });

    test('each line carries the tripId/categoryId of its source trip', () {
      final groups = buildShoppingGroups(_twoTrips, ShoppingSort.trip);
      final norway = groups.firstWhere((g) => g.key == 't1');
      final ardennes = groups.firstWhere((g) => g.key == 't2');

      expect(norway.lines.single.tripId, 't1');
      expect(norway.lines.single.categoryId, 'c1');
      expect(norway.lines.single.id, 'i1');

      expect(ardennes.lines.single.tripId, 't2');
      expect(ardennes.lines.single.categoryId, 'c2');
      expect(ardennes.lines.single.id, 'i2');
    });
  });

  group('filterShoppingGroups (Option B trip picker)', () {
    final groups = buildShoppingGroups(_twoTrips, ShoppingSort.trip);

    test('null key ("Alle") returns every group unchanged', () {
      expect(filterShoppingGroups(groups, null), same(groups));
    });

    test('a trip key returns only that trip\'s group', () {
      final only = filterShoppingGroups(groups, 't2');
      expect(only.map((g) => g.key), ['t2']);
      expect(only.single.lines.single.id, 'i2');
    });

    test('a stale key (trip gone) falls back to all groups', () {
      final result = filterShoppingGroups(groups, 'does-not-exist');
      expect(result, same(groups));
    });
  });

  group('marking bought targets the correct trip', () {
    test('markItemOwned only flips the item in the named trip', () async {
      final (container, c) = await _boot(_twoTrips);
      addTearDown(container.dispose);

      // Buy the Norwegen "Zelt" via the same call the shopping row makes.
      final line = buildShoppingGroups(
              container.read(appDataProvider).value!, ShoppingSort.trip)
          .firstWhere((g) => g.key == 't1')
          .lines
          .single;
      await c.markItemOwned(line.tripId!, line.categoryId!, line.id);

      final trips = container.read(appDataProvider).value!.trips;
      final norwayItem = trips
          .firstWhere((t) => t.id == 't1')
          .categories
          .single
          .items
          .single;
      final ardennesItem = trips
          .firstWhere((t) => t.id == 't2')
          .categories
          .single
          .items
          .single;

      expect(norwayItem.status, ItemStatus.owned,
          reason: 'the bought item flips to owned');
      expect(ardennesItem.status, ItemStatus.needToBuy,
          reason: 'the same-named item in the OTHER trip must be untouched');
    });

    test('after buying, that trip drops out of the shopping groups', () async {
      final (container, c) = await _boot(_twoTrips);
      addTearDown(container.dispose);

      await c.markItemOwned('t1', 'c1', 'i1');

      final groups = buildShoppingGroups(
          container.read(appDataProvider).value!, ShoppingSort.trip);
      // t1 had a single need-to-buy item; it's now owned, so t1 has no lines.
      expect(groups.map((g) => g.key), ['t2', 'manual']);
    });
  });
}
