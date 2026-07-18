import 'package:camp_gear_planner/models/app_data.dart';
import 'package:camp_gear_planner/models/category.dart';
import 'package:camp_gear_planner/models/item.dart';
import 'package:camp_gear_planner/models/item_status.dart';
import 'package:camp_gear_planner/models/trip.dart';
import 'package:camp_gear_planner/util/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Trip stats (design plan formulas)', () {
    const trip = Trip(
      id: 't1',
      name: 'Solo-Camp am See',
      categories: [
        Category(id: 'c1', name: 'Schlafen', items: [
          Item(id: 'i1', name: 'Zelt', status: ItemStatus.owned, weightGrams: 1400),
          Item(
              id: 'i2',
              name: 'Heringe',
              status: ItemStatus.owned,
              weightGrams: 15,
              quantity: 6,
              pricePerUnit: 0.9),
        ]),
        Category(id: 'c2', name: 'Kochen', items: [
          Item(
              id: 'i3',
              name: 'Kochset',
              status: ItemStatus.needToBuy,
              weightGrams: 300,
              pricePerUnit: 42.5),
          Item(id: 'i4', name: 'Deko', status: ItemStatus.notNeeded, weightGrams: 999),
        ]),
      ],
    );

    test('owned weight counts owned items with quantity', () {
      // 1400 + 15*6 = 1490
      expect(trip.ownedWeightGrams, 1490);
    });

    test('full weight sums all items incl. quantity', () {
      // 1400 + 90 + 300 + 999
      expect(trip.fullWeightGrams, 2789);
    });

    test('ready percent = owned / total item count', () {
      // 2 owned of 4 items → 50%
      expect(trip.readyPercent, 50);
    });

    test('budget stats: spent=owned prices, projected adds need-to-buy', () {
      expect(trip.spent, closeTo(5.4, 0.001)); // 0.9 * 6
      expect(trip.projected, closeTo(47.9, 0.001)); // 5.4 + 42.5
    });
  });

  group('Formatting', () {
    test('weight', () {
      expect(fmtWeight(850), '850g');
      expect(fmtWeight(1400), '1.4kg');
      expect(fmtWeight(3000), '3kg');
    });
    test('price', () {
      expect(fmtPrice(39), '€39');
      expect(fmtPrice(42.5), '€42.50');
    });
  });

  group('JSON round-trip (GDD §12)', () {
    test('AppData survives serialize → deserialize', () {
      const data = AppData(trips: [
        Trip(
          id: 't1',
          name: 'Trip',
          countryCode: 'DE',
          seasonKey: 'spring',
          budget: 180,
          categories: [
            Category(id: 'c1', name: 'Cat', items: [
              Item(
                  id: 'i1',
                  name: 'Tent',
                  status: ItemStatus.owned,
                  quantity: 2,
                  pricePerUnit: 12.5),
            ]),
          ],
        ),
      ]);
      final restored = AppData.fromJson(data.toJson());
      final t = restored.trips.single;
      expect(t.name, 'Trip');
      expect(t.country?.code, 'DE');
      expect(t.budget, 180);
      final item = t.categories.single.items.single;
      expect(item.quantity, 2);
      expect(item.totalPrice, 25.0);
      expect(restored.schemaVersion, AppData.currentSchemaVersion);
    });
  });
}
