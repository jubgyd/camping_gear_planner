// Smoke test: the app boots to the Camps tab with an empty in-memory
// repository (no path_provider platform channel needed under `flutter test`).
import 'package:camp_gear_planner/app.dart';
import 'package:camp_gear_planner/data/repository.dart';
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
  testWidgets('boots to the Camps tab with empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(FakeRepository()),
        ],
        child: const MaterialApp(home: HomeShell()),
      ),
    );
    // Let the AsyncNotifier resolve its initial load.
    await tester.pumpAndSettle();

    // Three-tab bottom nav renders (GDD §9).
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(3));

    // Camps tab (index 0) shows its empty-state copy.
    expect(find.textContaining('No active trips'), findsOneWidget);
  });
}
