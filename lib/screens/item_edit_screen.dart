import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/item.dart';
import '../models/item_status.dart';
import '../models/shopping_entry.dart';
import '../state/app_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_text.dart';
import '../util/format.dart';
import '../util/link_price.dart';
import '../util/motion.dart';
import '../widgets/ui_kit.dart';

enum _Fetch { idle, loading, found, empty, error }

/// Add / edit an item (design plan Item Edit): name, status, link + price-fetch,
/// quantity, price/weight, note. Serves both trip items and manual entries.
class ItemEditScreen extends ConsumerStatefulWidget {
  const ItemEditScreen({
    super.key,
    this.tripId,
    this.categoryId,
    this.existing,
    this.manualEntry,
    this.categoryName,
  });

  /// Trip-item mode.
  final String? tripId;
  final String? categoryId;
  final Item? existing;
  final String? categoryName;

  /// Manual-entry mode.
  final ManualEntry? manualEntry;

  bool get isManual => manualEntry != null;

  @override
  ConsumerState<ItemEditScreen> createState() => _ItemEditScreenState();
}

class _ItemEditScreenState extends ConsumerState<ItemEditScreen> {
  late final TextEditingController _name;
  late final TextEditingController _note;
  late final TextEditingController _link;
  late final TextEditingController _price;
  late final TextEditingController _weight;
  late int _quantity;
  late ItemStatus _status;
  _Fetch _fetch = _Fetch.idle;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final m = widget.manualEntry;
    _name = TextEditingController(text: e?.name ?? m?.name ?? '');
    _note = TextEditingController(text: e?.note ?? m?.note ?? '');
    _link = TextEditingController(text: e?.link ?? m?.link ?? '');
    _price = TextEditingController(
        text: (e?.pricePerUnit ?? m?.pricePerUnit)?.toString() ?? '');
    _weight = TextEditingController(
        text: (e?.weightGrams ?? m?.weightGrams)?.toString() ?? '');
    _quantity = e?.quantity ?? m?.quantity ?? 1;
    _status = e?.status ?? ItemStatus.needToBuy;
  }

  @override
  void dispose() {
    for (final c in [_name, _note, _link, _price, _weight]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchLinkInfo() async {
    if (_link.text.trim().isEmpty) return;
    setState(() => _fetch = _Fetch.loading);
    // Downloads the product page and reads og:price / schema.org / microdata.
    // Fails gracefully: bot-blocking or JS-rendered shops yield no price.
    try {
      final info = await const LinkPriceService().fetch(_link.text);
      if (!mounted) return;
      if (info.hasPrice) {
        setState(() {
          _price.text = info.price!.toStringAsFixed(2);
          // Offer the shop's product name if we don't have one yet.
          if (_name.text.trim().isEmpty &&
              info.title != null &&
              info.title!.trim().isNotEmpty) {
            _name.text = info.title!.trim();
          }
          _fetch = _Fetch.found;
        });
      } else {
        setState(() => _fetch = _Fetch.empty);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _fetch = _Fetch.error);
    }
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final c = ref.read(appDataProvider.notifier);
    final price = double.tryParse(_price.text.trim());
    final weight = int.tryParse(_weight.text.trim());
    final link = _link.text.trim().isEmpty ? null : _link.text.trim();

    if (widget.isManual) {
      c.updateManualEntry(widget.manualEntry!.copyWith(
        name: name,
        note: _note.text.trim(),
        link: () => link,
        pricePerUnit: () => price,
        weightGrams: () => weight,
        quantity: _quantity,
      ));
      Navigator.of(context).pop();
      return;
    }

    final item = Item(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: name,
      note: _note.text.trim(),
      link: link,
      status: _status,
      sourceTemplateId: widget.existing?.sourceTemplateId,
      weightGrams: weight,
      quantity: _quantity,
      pricePerUnit: price,
    );
    if (widget.existing == null) {
      c.addItem(widget.tripId!, widget.categoryId!, item);
    } else {
      c.updateItem(widget.tripId!, widget.categoryId!, item);
    }
    Navigator.of(context).pop();
  }

  /// True once there is something persisted to delete (existing item or entry).
  bool get _canDelete => widget.isManual || widget.existing != null;

  Future<void> _delete() async {
    final name = _name.text.trim().isEmpty ? 'this item' : '“${_name.text.trim()}”';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('$name will be removed. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final c = ref.read(appDataProvider.notifier);
    if (widget.isManual) {
      c.removeManualEntry(widget.manualEntry!.id);
    } else {
      c.removeItem(widget.tripId!, widget.categoryId!, widget.existing!.id);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final catLabel = widget.isManual
        ? 'Sonstiges'
        : (widget.categoryName ?? 'Item');
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                children: [
                  IconButton(
                      icon: Icon(Icons.close, color: p.ink),
                      onPressed: () => Navigator.of(context).pop()),
                  const Spacer(),
                  Text(catLabel.toUpperCase(),
                      style: AppText.mono(12, color: p.inkMuted, letterSpacing: 1.5)),
                  const Spacer(),
                  TextButton(
                      onPressed: _save,
                      child: Text('Save',
                          style: AppText.mono(14, color: p.rust, weight: FontWeight.w500))),
                ],
              ),
            ),
            Expanded(
              child: ContentColumn(
                maxWidth: 600,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                  children: [
                    TextField(
                      controller: _name,
                      style: AppText.display(24, color: p.ink),
                      cursorColor: p.rust,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Item name',
                        hintStyle: AppText.display(24, color: p.slate),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: p.border, width: 2)),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: p.rust, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (!widget.isManual) ...[
                      const SectionLabel('Status'),
                      const SizedBox(height: 10),
                      _StatusSelector(
                        status: _status,
                        onSelect: (s) => setState(() => _status = s),
                      ),
                      const SizedBox(height: 22),
                    ],
                    const SectionLabel('Link'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _boxedField(p, _link, 'https://...')),
                        const SizedBox(width: 8),
                        _FetchButton(
                          enabled: _link.text.trim().isNotEmpty &&
                              _fetch != _Fetch.loading,
                          loading: _fetch == _Fetch.loading,
                          onTap: _fetchLinkInfo,
                        ),
                      ],
                    ),
                    if (_fetch == _Fetch.found)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('✓ Price found and filled in below',
                            style: AppText.body(12, color: p.moss)),
                      ),
                    if (_fetch == _Fetch.empty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('No price found on this page — enter it manually',
                            style: AppText.body(12, color: p.inkMuted)),
                      ),
                    if (_fetch == _Fetch.error)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                            "Couldn't reach that page — check the link or enter the price manually",
                            style: AppText.body(12, color: p.inkMuted)),
                      ),
                    const SizedBox(height: 22),
                    const SectionLabel('Quantity'),
                    const SizedBox(height: 10),
                    _QuantityStepper(
                      quantity: _quantity,
                      weightText: _weight.text,
                      onChanged: (q) => setState(() => _quantity = q),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionLabel('Price / unit (€)'),
                              const SizedBox(height: 10),
                              _boxedField(p, _price, '0.00',
                                  mono: true,
                                  borderColor:
                                      _fetch == _Fetch.found ? p.moss : null),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionLabel('Weight / unit (g)'),
                              const SizedBox(height: 10),
                              _boxedField(p, _weight, '0',
                                  mono: true,
                                  onChanged: (_) => setState(() {})),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const SectionLabel('Note'),
                    const SizedBox(height: 10),
                    _boxedField(p, _note, '', maxLines: 3),
                    if (_canDelete) ...[
                      const SizedBox(height: 28),
                      OutlinedButton.icon(
                        onPressed: _delete,
                        icon: Icon(Icons.delete_outline,
                            size: 18, color: Colors.red.shade600),
                        label: Text('Delete item',
                            style: AppText.body(14, color: Colors.red.shade600)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.red.shade200),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _boxedField(
    AppPalette p,
    TextEditingController controller,
    String hint, {
    bool mono = false,
    int maxLines = 1,
    Color? borderColor,
    ValueChanged<String>? onChanged,
  }) {
    final style = mono
        ? AppText.mono(13, color: p.ink)
        : AppText.body(14, color: p.ink);
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged ?? (_) => setState(() {}),
      style: style,
      cursorColor: p.rust,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        hintText: hint,
        hintStyle: mono
            ? AppText.mono(13, color: p.slate)
            : AppText.body(14, color: p.slate),
        filled: true,
        fillColor: p.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor ?? p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor ?? p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor ?? p.rust),
        ),
      ),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  const _StatusSelector({required this.status, required this.onSelect});
  final ItemStatus status;
  final ValueChanged<ItemStatus> onSelect;

  static const _opts = [
    (ItemStatus.owned, 'Owned'),
    (ItemStatus.needToBuy, 'Need to buy'),
    (ItemStatus.notNeeded, 'N/A'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        for (final o in _opts)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelect(o.$1),
                child: AnimatedContainer(duration: Motion.base, curve: Motion.curve,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: status == o.$1 ? p.selectedBg : p.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: status == o.$1 ? p.selectedBg : p.border,
                        width: 1.5),
                  ),
                  child: Text(o.$2,
                      style: AppText.body(12,
                          color: status == o.$1 ? p.bg : p.ink)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FetchButton extends StatelessWidget {
  const _FetchButton({required this.enabled, required this.loading, required this.onTap});
  final bool enabled, loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(duration: Motion.base, curve: Motion.curve,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: enabled ? p.rust : p.slateSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(loading ? 'Fetching…' : 'Fetch info',
            style: AppText.mono(12, color: enabled ? Colors.white : p.slate)),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.weightText,
    required this.onChanged,
  });
  final int quantity;
  final String weightText;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget btn(String label, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(duration: Motion.base, curve: Motion.curve,
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: p.border),
            ),
            child: Text(label, style: AppText.body(18, color: p.ink)),
          ),
        );
    final w = int.tryParse(weightText.trim());
    return Row(
      children: [
        btn('−', () => onChanged(quantity > 1 ? quantity - 1 : 1)),
        const SizedBox(width: 12),
        Container(
          width: 56,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: p.border),
          ),
          child: Text('$quantity', style: AppText.mono(14, color: p.ink)),
        ),
        const SizedBox(width: 12),
        btn('+', () => onChanged(quantity + 1)),
        if (quantity > 1 && w != null && w > 0) ...[
          const SizedBox(width: 14),
          Text('${fmtWeight(w * quantity)} total',
              style: AppText.mono(12, color: p.inkMuted)),
        ],
      ],
    );
  }
}
