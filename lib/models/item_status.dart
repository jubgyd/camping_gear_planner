/// The three-state status that replaces a flat "have it" checkbox (GDD §3).
///
/// - [owned]      — you already have it, packed/ready
/// - [needToBuy]  — flags it for the shopping list automatically
/// - [notNeeded]  — skip without deleting (a declined suggestion)
enum ItemStatus {
  owned,
  needToBuy,
  notNeeded;

  /// Wire value used in the JSON export schema (GDD §4/§12). Kept in snake_case
  /// so hand-editing an exported file reads naturally.
  String get wire => switch (this) {
        ItemStatus.owned => 'owned',
        ItemStatus.needToBuy => 'need_to_buy',
        ItemStatus.notNeeded => 'not_needed',
      };

  static ItemStatus fromWire(String? value) => switch (value) {
        'owned' => ItemStatus.owned,
        'need_to_buy' => ItemStatus.needToBuy,
        'not_needed' => ItemStatus.notNeeded,
        _ => ItemStatus.needToBuy, // safe default for unknown/missing
      };

  String get label => switch (this) {
        ItemStatus.owned => 'Owned',
        ItemStatus.needToBuy => 'Need to buy',
        ItemStatus.notNeeded => 'Not needed',
      };
}
