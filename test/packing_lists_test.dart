import 'package:camp_gear_planner/data/packing_lists.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ships the 3 starters plus the master and 4 season kits', () {
    final lists = builtinPackingLists();
    final ids = lists.map((l) => l.id).toList();
    expect(ids, containsAll(<String>[
      'builtin-tent',
      'builtin-van',
      'builtin-wild',
      'builtin-complete',
      'builtin-season-spring',
      'builtin-season-summer',
      'builtin-season-autumn',
      'builtin-season-winter',
    ]));
    // No duplicate list ids.
    expect(ids.toSet().length, ids.length);
    // All are flagged as built-in.
    expect(lists.every((l) => l.builtin), isTrue);
  });

  test('every built-in list has non-empty categories and items', () {
    for (final list in builtinPackingLists()) {
      expect(list.categories, isNotEmpty, reason: '${list.id} has no categories');
      for (final cat in list.categories) {
        expect(cat.items, isNotEmpty,
            reason: '${list.id} / "${cat.name}" is empty');
        expect(cat.name.trim(), isNotEmpty);
        for (final item in cat.items) {
          expect(item.name.trim(), isNotEmpty,
              reason: 'blank item name in ${list.id} / ${cat.name}');
        }
      }
      // Category order is a stable 0..n-1 sequence.
      expect(list.categories.map((c) => c.order).toList(),
          List.generate(list.categories.length, (i) => i));
    }
  });

  test('item ids are unique within each list and fresh across calls', () {
    for (final list in builtinPackingLists()) {
      final itemIds =
          list.categories.expand((c) => c.items).map((i) => i.id).toList();
      expect(itemIds.toSet().length, itemIds.length,
          reason: 'duplicate item id within ${list.id}');
    }
    // Two independent calls must not share item ids (fresh uuids each time).
    final a = builtinPackingLists()
        .expand((l) => l.categories)
        .expand((c) => c.items)
        .map((i) => i.id)
        .toSet();
    final b = builtinPackingLists()
        .expand((l) => l.categories)
        .expand((c) => c.items)
        .map((i) => i.id)
        .toSet();
    expect(a.intersection(b), isEmpty);
  });

  test('master list carries everything, incl. both seasonal extra blocks', () {
    final master =
        builtinPackingLists().firstWhere((l) => l.id == 'builtin-complete');
    final catNames = master.categories.map((c) => c.name).toList();
    expect(catNames, containsAll(<String>['Winter-Extras', 'Sommer-Extras']));
    // It's the biggest list by item count.
    final maxOther = builtinPackingLists()
        .where((l) => l.id != 'builtin-complete')
        .map((l) => l.itemCount)
        .reduce((a, b) => a > b ? a : b);
    expect(master.itemCount, greaterThan(maxOther));
  });

  test('season kits are complete and season-appropriate', () {
    final byId = {for (final l in builtinPackingLists()) l.id: l};

    String? catContaining(String id, String needle) => byId[id]!
        .categories
        .expand((c) => c.items)
        .map((i) => i.name)
        .firstWhere((n) => n.contains(needle), orElse: () => '')
        .let((n) => n.isEmpty ? null : n);

    // Winter kit has the winter extras and cold-weather clothing.
    final winter = byId['builtin-season-winter']!;
    expect(winter.categories.map((c) => c.name), contains('Winter-Extras'));
    expect(catContaining('builtin-season-winter', 'Thermounterwäsche'),
        isNotNull);
    // Summer kit has sun/insect protection and summer extras, not winter ones.
    final summer = byId['builtin-season-summer']!;
    expect(summer.categories.map((c) => c.name),
        containsAll(<String>['Sonnen- & Insektenschutz', 'Sommer-Extras']));
    expect(summer.categories.map((c) => c.name), isNot(contains('Winter-Extras')));
    // Every season kit is a real kit (shelter, sleep, kitchen, clothing, pack).
    for (final id in [
      'builtin-season-spring',
      'builtin-season-summer',
      'builtin-season-autumn',
      'builtin-season-winter',
    ]) {
      final names = byId[id]!.categories.map((c) => c.name).toSet();
      expect(
          names,
          containsAll(<String>[
            'Unterkunft',
            'Schlafen',
            'Küche & Kochen',
            'Kleidung',
            'Pack & Organisation',
          ]),
          reason: '$id is missing a core category');
    }
  });
}

extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
