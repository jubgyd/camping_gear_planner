import 'template.dart';

/// A reusable starting checklist. New trips can begin blank, from a [builtin]
/// premade list, or from a custom list the user saved off one of their trips
/// ("Save as list"). Applying a list seeds the trip's whole checklist at once.
///
/// Reuses [TemplateCategory]/[TemplateItem] for its contents so a list is just
/// "categories of items" with no status.
class PackingList {
  const PackingList({
    required this.id,
    required this.name,
    this.description = '',
    this.builtin = false,
    this.categories = const [],
  });

  final String id;
  final String name;
  final String description;
  final bool builtin;
  final List<TemplateCategory> categories;

  int get itemCount =>
      categories.fold(0, (sum, c) => sum + c.items.length);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'builtin': builtin,
        'categories': categories.map((c) => c.toJson()).toList(),
      };

  factory PackingList.fromJson(Map<String, dynamic> json) => PackingList(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        builtin: json['builtin'] as bool? ?? false,
        categories: (json['categories'] as List<dynamic>? ?? [])
            .map((e) => TemplateCategory.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
