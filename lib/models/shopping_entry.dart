/// A manually-added shopping-list entry with no trip link (design plan
/// "Sonstiges" group). Trip-linked shopping lines are derived live from items
/// with status `needToBuy` — only these free-standing manual entries are stored.
class ManualEntry {
  const ManualEntry({
    required this.id,
    required this.name,
    this.note = '',
    this.link,
    this.weightGrams,
    this.pricePerUnit,
    this.quantity = 1,
    this.bought = false,
    this.imageFile,
  });

  final String id;
  final String name;
  final String note;
  final String? link;
  final int? weightGrams;
  final double? pricePerUnit;
  final int quantity;
  final bool bought;

  /// Filename of a downloaded product image on disk (see ImageStore), or null.
  final String? imageFile;

  int? get totalWeightGrams =>
      weightGrams == null ? null : weightGrams! * quantity;
  double? get totalPrice =>
      pricePerUnit == null ? null : pricePerUnit! * quantity;

  ManualEntry copyWith({
    String? name,
    String? note,
    String? Function()? link,
    int? Function()? weightGrams,
    double? Function()? pricePerUnit,
    int? quantity,
    bool? bought,
    String? Function()? imageFile,
  }) {
    return ManualEntry(
      id: id,
      name: name ?? this.name,
      note: note ?? this.note,
      link: link != null ? link() : this.link,
      weightGrams: weightGrams != null ? weightGrams() : this.weightGrams,
      pricePerUnit: pricePerUnit != null ? pricePerUnit() : this.pricePerUnit,
      quantity: quantity ?? this.quantity,
      bought: bought ?? this.bought,
      imageFile: imageFile != null ? imageFile() : this.imageFile,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'note': note,
        'link': link,
        'weightGrams': weightGrams,
        'pricePerUnit': pricePerUnit,
        'quantity': quantity,
        'bought': bought,
        'imageFile': imageFile,
      };

  factory ManualEntry.fromJson(Map<String, dynamic> json) => ManualEntry(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        note: json['note'] as String? ?? '',
        link: json['link'] as String?,
        weightGrams: (json['weightGrams'] as num?)?.toInt(),
        pricePerUnit: (json['pricePerUnit'] as num?)?.toDouble(),
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        bought: json['bought'] as bool? ?? false,
        imageFile: json['imageFile'] as String?,
      );
}
