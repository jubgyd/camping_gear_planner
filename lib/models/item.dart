import 'item_status.dart';

/// A single gear piece inside a trip's category (GDD §4, §11 + design plan).
///
/// Immutable value type; mutations go through the controller which produces a
/// new instance via [copyWith] and persists through the repository.
class Item {
  const Item({
    required this.id,
    required this.name,
    this.note = '',
    this.link,
    this.status = ItemStatus.needToBuy,
    this.sourceTemplateId,
    this.weightGrams,
    this.quantity = 1,
    this.pricePerUnit,
  });

  final String id;
  final String name;
  final String note;

  /// Optional URL; tapping it opens the browser (GDD §5.6).
  final String? link;
  final ItemStatus status;

  /// Ties back to the template item this was created from, if any (GDD §4).
  final String? sourceTemplateId;

  /// Optional packing weight per unit in grams (GDD §11).
  final int? weightGrams;

  /// How many of this item (design plan). Multiplies weight and price totals.
  final int quantity;

  /// Optional price per unit, in euros (design plan budget tracking).
  final double? pricePerUnit;

  /// Total weight = per-unit weight × quantity (0 if no weight set).
  int get totalWeightGrams => (weightGrams ?? 0) * quantity;

  /// Total price = per-unit price × quantity, or null if no price set.
  double? get totalPrice =>
      pricePerUnit == null ? null : pricePerUnit! * quantity;

  Item copyWith({
    String? name,
    String? note,
    String? Function()? link,
    ItemStatus? status,
    String? Function()? sourceTemplateId,
    int? Function()? weightGrams,
    int? quantity,
    double? Function()? pricePerUnit,
  }) {
    return Item(
      id: id,
      name: name ?? this.name,
      note: note ?? this.note,
      link: link != null ? link() : this.link,
      status: status ?? this.status,
      sourceTemplateId:
          sourceTemplateId != null ? sourceTemplateId() : this.sourceTemplateId,
      weightGrams: weightGrams != null ? weightGrams() : this.weightGrams,
      quantity: quantity ?? this.quantity,
      pricePerUnit: pricePerUnit != null ? pricePerUnit() : this.pricePerUnit,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'note': note,
        'link': link,
        'status': status.wire,
        'sourceTemplateId': sourceTemplateId,
        'weightGrams': weightGrams,
        'quantity': quantity,
        'pricePerUnit': pricePerUnit,
      };

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        note: json['note'] as String? ?? '',
        link: json['link'] as String?,
        status: ItemStatus.fromWire(json['status'] as String?),
        sourceTemplateId: json['sourceTemplateId'] as String?,
        weightGrams: (json['weightGrams'] as num?)?.toInt(),
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        pricePerUnit: (json['pricePerUnit'] as num?)?.toDouble(),
      );
}
