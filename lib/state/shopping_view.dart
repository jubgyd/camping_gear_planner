import '../models/app_data.dart';
import '../models/item_status.dart';

/// A single actionable line on the shopping list — either derived from a trip
/// item (has [tripId]/[categoryId]) or a manual entry (has [manualId]).
class ShoppingLine {
  const ShoppingLine({
    required this.id,
    required this.name,
    required this.note,
    required this.link,
    required this.quantity,
    required this.totalPrice,
    required this.totalWeightGrams,
    this.imageFile,
    this.tripId,
    this.categoryId,
    this.manualId,
  });

  final String id;
  final String name;
  final String note;
  final String? link;
  final int quantity;
  final double? totalPrice;
  final int? totalWeightGrams;
  final String? imageFile;

  final String? tripId;
  final String? categoryId;
  final String? manualId;

  bool get isManual => manualId != null;
}

class ShoppingGroup {
  const ShoppingGroup({required this.key, required this.name, required this.lines});
  final String key;
  final String name;
  final List<ShoppingLine> lines;

  double get subtotal =>
      lines.fold(0.0, (s, l) => s + (l.totalPrice ?? 0));
}

enum ShoppingSort { trip, price }

/// Builds the grouped shopping list: one group per trip with need-to-buy items,
/// then a "Sonstiges" group of active manual entries (design plan
/// `shoppingGroups`).
List<ShoppingGroup> buildShoppingGroups(AppData data, ShoppingSort sort) {
  final groups = <String, ShoppingGroup>{};
  final order = <String>[];

  for (final trip in data.trips) {
    for (final cat in trip.categories) {
      for (final it in cat.items) {
        if (it.status != ItemStatus.needToBuy) continue;
        groups.putIfAbsent(trip.id, () {
          order.add(trip.id);
          return ShoppingGroup(key: trip.id, name: trip.name, lines: []);
        });
        groups[trip.id]!.lines.add(ShoppingLine(
              id: it.id,
              name: it.name,
              note: it.note,
              link: it.link,
              quantity: it.quantity,
              totalPrice: it.totalPrice,
              totalWeightGrams:
                  it.weightGrams == null ? null : it.totalWeightGrams,
              imageFile: it.imageFile,
              tripId: trip.id,
              categoryId: cat.id,
            ));
      }
    }
  }

  final manualLines = data.manualEntries
      .where((e) => !e.bought)
      .map((e) => ShoppingLine(
            id: e.id,
            name: e.name,
            note: e.note,
            link: e.link,
            quantity: e.quantity,
            totalPrice: e.totalPrice,
            totalWeightGrams: e.totalWeightGrams,
            imageFile: e.imageFile,
            manualId: e.id,
          ))
      .toList();

  final result = [for (final k in order) groups[k]!];
  if (manualLines.isNotEmpty) {
    result.add(
        ShoppingGroup(key: 'manual', name: 'Sonstiges', lines: manualLines));
  }

  if (sort == ShoppingSort.price) {
    for (final g in result) {
      g.lines.sort((a, b) => (b.totalPrice ?? 0).compareTo(a.totalPrice ?? 0));
    }
  }
  return result;
}

double shoppingTotal(List<ShoppingGroup> groups) =>
    groups.fold(0.0, (s, g) => s + g.subtotal);
