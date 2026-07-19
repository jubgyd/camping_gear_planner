// The single-trip half of the Option B trip-picker coverage: with only one
// trip there are fewer than two groups, so the picker bar must not appear.
// Separate file from shopping_filter_widget_test.dart so each isolate boots the
// full HomeShell only once (see the harness note).
import 'package:camp_gear_planner/models/app_data.dart';
import 'package:camp_gear_planner/models/category.dart';
import 'package:camp_gear_planner/models/item.dart';
import 'package:camp_gear_planner/models/item_status.dart';
import 'package:camp_gear_planner/models/trip.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/shopping_filter_harness.dart';

const _oneTrip = AppData(trips: [
  Trip(id: 't1', name: 'Norwegen', categories: [
    Category(id: 'c1', name: 'Schlafen', items: [
      Item(id: 'i1', name: 'NorthTent', status: ItemStatus.needToBuy),
    ]),
  ]),
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('no picker bar with a single trip', (tester) async {
    await pumpShoppingTab(tester, _oneTrip);

    // Only one group -> no "All" pill.
    expect(find.text('All'), findsNothing);
    expect(find.text('NorthTent'), findsOneWidget);
  });
}
