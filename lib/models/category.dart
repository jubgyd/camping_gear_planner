import 'item.dart';
import 'item_status.dart';

/// A collapsible grouping within a trip's checklist (GDD §2, §4).
class Category {
  const Category({
    required this.id,
    required this.name,
    this.order = 0,
    this.items = const [],
    this.collapsed = false,
  });

  final String id;
  final String name;
  final int order;
  final List<Item> items;
  final bool collapsed;

  /// Per-category weight subtotal (grams), counting everything except
  /// not-needed items — matches the design plan's `categoryWeight`.
  int get weightGrams => items
      .where((i) => i.status != ItemStatus.notNeeded)
      .fold(0, (sum, i) => sum + i.totalWeightGrams);

  Category copyWith({
    String? name,
    int? order,
    List<Item>? items,
    bool? collapsed,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      order: order ?? this.order,
      items: items ?? this.items,
      collapsed: collapsed ?? this.collapsed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'order': order,
        'collapsed': collapsed,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        order: (json['order'] as num?)?.toInt() ?? 0,
        collapsed: json['collapsed'] as bool? ?? false,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => Item.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
