// Smoke test: the app boots to the Camps tab with an empty in-memory
// repository (no path_provider platform channel needed under `flutter test`).
import 'package:camp_gear_planner/app.dart';
import 'package:camp_gear_planner/data/repository.dart';
import 'package:camp_gear_planner/l10n/app_strings.dart';
import 'package:camp_gear_planner/models/app_data.dart';
import 'package:camp_gear_planner/state/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repository stub that keeps everything in memory.
class FakeRepository implements Repository {
  AppData _data = const AppData();

  @override
  Future<AppData> load() async => _data;

  @override
  Future<void> save(AppData data) async => _data = data;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boots to the Camps tab with empty state', (tester) async {
    final strings = await AppStrings.load();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(FakeRepository()),
        ],
        child: MaterialApp(
          home: const HomeShell(),
          builder: (context, child) =>
              AppStrings(lang: 'en', maps: strings, child: child!),
        ),
      ),
    );
    // Let the AsyncNotifier resolve its initial load.
    await tester.pumpAndSettle();

    // Three-tab bottom nav renders (GDD §9).
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(3));

    // Camps tab (index 0) shows its empty-state copy (English).
    expect(find.textContaining('No active trips'), findsOneWidget);
  });

  testWidgets('language switches the UI text live', (tester) async {
    final maps = {
      'en': {'k': 'Camps', 'e': 'No active trips'},
      'de': {'k': 'Camps', 'e': 'Keine aktiven Trips'},
    };
    var lang = 'en';
    late StateSetter setOuter;
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(builder: (ctx, setState) {
        setOuter = setState;
        return AppStrings(
          lang: lang,
          maps: maps,
          child: Builder(
            builder: (c) =>
                Text(c.t('e'), textDirection: TextDirection.ltr),
          ),
        );
      }),
    ));

    expect(find.text('No active trips'), findsOneWidget);
    setOuter(() => lang = 'de');
    await tester.pump();
    expect(find.text('Keine aktiven Trips'), findsOneWidget);
    expect(find.text('No active trips'), findsNothing);
  });
}
