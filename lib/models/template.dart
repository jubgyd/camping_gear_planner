// The reusable template library — categories/items with no status, pulled into
// any trip via "Add from template" (GDD §2, §4, §14.4).

/// A template item. Unlike an item it has no status; it may carry a default
/// weight that is copied to the trip item when added (GDD §11). [styles] tags
/// it to camp styles for the style-filtered suggestions view (design plan);
/// an empty list means "universal" (shown for every style).
class TemplateItem {
  const TemplateItem({
    required this.id,
    required this.name,
    this.note = '',
    this.link,
    this.weightGrams,
    this.styles = const [],
  });

  final String id;
  final String name;
  final String note;
  final String? link;
  final int? weightGrams;
  final List<String> styles;

  bool get isUniversal => styles.isEmpty;
  bool matchesStyle(String? styleKey) =>
      isUniversal || (styleKey != null && styles.contains(styleKey));

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'note': note,
        'link': link,
        'weightGrams': weightGrams,
        'styles': styles,
      };

  factory TemplateItem.fromJson(Map<String, dynamic> json) => TemplateItem(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        note: json['note'] as String? ?? '',
        link: json['link'] as String?,
        weightGrams: (json['weightGrams'] as num?)?.toInt(),
        styles: (json['styles'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
      );
}

class TemplateCategory {
  const TemplateCategory({
    required this.id,
    required this.name,
    this.order = 0,
    this.items = const [],
  });

  final String id;
  final String name;
  final int order;
  final List<TemplateItem> items;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'order': order,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory TemplateCategory.fromJson(Map<String, dynamic> json) =>
      TemplateCategory(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        order: (json['order'] as num?)?.toInt() ?? 0,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => TemplateItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
