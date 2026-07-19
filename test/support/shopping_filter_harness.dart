// Shared harness for the Shopping-tab widget tests. Kept in its own file so
// each *test* file performs exactly one full-app HomeShell boot (two boots in
// one isolate hang on teardown).
import 'package:camp_gear_planner/app.dart';
import 'package:camp_gear_planner/data/repository.dart';
import 'package:camp_gear_planner/l10n/app_strings.dart';
import 'package:camp_gear_planner/models/app_data.dart';
import 'package:camp_gear_planner/state/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class SeedRepository implements Repository {
  SeedRepository(this._data);
  AppData _data;
  @override
  Future<AppData> load() async => _data;
  @override
  Future<void> save(AppData data) async => _data = data;
}

/// Advances animations and the async initial load with bounded pumps. Never
/// waits for full quiescence (which the app's animations can prevent), so it
/// can't hang the way `pumpAndSettle` does.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// Boots the full app with [seed] and switches to the Shopping tab.
Future<void> pumpShoppingTab(WidgetTester tester, AppData seed) async {
  final strings = await AppStrings.load();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(SeedRepository(seed)),
      ],
      child: MaterialApp(
        home: const HomeShell(),
        builder: (context, child) =>
            AppStrings(lang: 'en', maps: strings, child: child!),
      ),
    ),
  );
  await settle(tester);
  await tester.tap(find.text('Shopping'));
  await settle(tester);
}
