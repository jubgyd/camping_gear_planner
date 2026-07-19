// Widget test for the Option B trip picker on the Shopping tab: with two trips
// the picker filters the list to one trip, and "Alle" restores the rest.
//
// NOTE: boot the full HomeShell only ONCE per test file. Two back-to-back
// full-app boots in the same isolate fail to tear down cleanly and the second
// hangs, so the single-trip case lives in shopping_filter_singletrip_test.dart.
// Advance frames with bounded `pump`s (see [_settle]) rather than
// `pumpAndSettle`, which the app's animations can prevent from ever settling.
import 'package:camp_gear_planner/app.dart';
import 'package:camp_gear_planner/data/repository.dart';
import 'package:camp_gear_planner/l10n/app_strings.dart';
import 'package:camp_gear_planner/models/app_data.dart';
import 'package:camp_gear_planner/models/category.dart';
import 'package:camp_gear_planner/models/item.dart';
import 'package:camp_gear_planner/models/item_status.dart';
import 'package:camp_gear_planner/models/trip.dart';
import 'package:camp_gear_planner/state/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/shopping_filter_harness.dart';

// Two trips with distinctly-named need-to-buy items so we can tell the two
// trip cards apart from the (identically-named) picker pills.
const _twoTrips = AppData(trips: [
  Trip(id: 't1', name: 'Norwegen', categories: [
    Category(id: 'c1', name: 'Schlafen', items: [
      Item(id: 'i1', name: 'NorthTent', status: ItemStatus.needToBuy),
    ]),
  ]),
  Trip(id: 't2', name: 'Ardennen', categories: [
    Category(id: 'c2', name: 'Schlafen', items: [
      Item(id: 'i2', name: 'SouthBag', status: ItemStatus.needToBuy),
    ]),
  ]),
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('picking a trip hides the other trip\'s items', (tester) async {
    await pumpShoppingTab(tester, _twoTrips);

    // "Alle" view: both trips' items are on screen.
    expect(find.text('NorthTent'), findsOneWidget);
    expect(find.text('SouthBag'), findsOneWidget);

    // Tap the "Ardennen" pill (first "Ardennen" in tree order = the picker,
    // which sits above the trip cards).
    await tester.tap(find.text('Ardennen').first);
    await settle(tester);

    // Only Ardennen's item remains.
    expect(find.text('NorthTent'), findsNothing);
    expect(find.text('SouthBag'), findsOneWidget);

    // Back to "Alle" restores both.
    await tester.tap(find.text('All'));
    await settle(tester);
    expect(find.text('NorthTent'), findsOneWidget);
    expect(find.text('SouthBag'), findsOneWidget);
  });
}
