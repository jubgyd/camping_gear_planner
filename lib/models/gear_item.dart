/// An entry in the user's personal gear catalog ("My Gear") — a hand-curated
/// inventory of gear they own/have gathered, independent of any trip. Picking
/// one when building a trip copies it in as a checklist item.
class GearItem {
  const GearItem({
    required this.id,
    required this.name,
    this.note = '',
    this.link,
    this.weightGrams,
    this.pricePerUnit,
    this.category = 'Sonstiges',
  });

  final String id;
  final String name;
  final String note;
  final String? link;
  final int? weightGrams;
  final double? pricePerUnit;

  /// The checklist category this lands in when added to a trip.
  final String category;

  GearItem copyWith({
    String? name,
    String? note,
    String? Function()? link,
    int? Function()? weightGrams,
    double? Function()? pricePerUnit,
    String? category,
  }) {
    return GearItem(
      id: id,
      name: name ?? this.name,
      note: note ?? this.note,
      link: link != null ? link() : this.link,
      weightGrams: weightGrams != null ? weightGrams() : this.weightGrams,
      pricePerUnit: pricePerUnit != null ? pricePerUnit() : this.pricePerUnit,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'note': note,
        'link': link,
        'weightGrams': weightGrams,
        'pricePerUnit': pricePerUnit,
        'category': category,
      };

  factory GearItem.fromJson(Map<String, dynamic> json) => GearItem(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        note: json['note'] as String? ?? '',
        link: json['link'] as String?,
        weightGrams: (json['weightGrams'] as num?)?.toInt(),
        pricePerUnit: (json['pricePerUnit'] as num?)?.toDouble(),
        category: json['category'] as String? ?? 'Sonstiges',
      );
}
