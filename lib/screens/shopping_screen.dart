import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_strings.dart';
import '../models/shopping_entry.dart';
import '../state/app_controller.dart';
import '../state/shopping_view.dart';
import '../theme/app_palette.dart';
import '../theme/app_text.dart';
import '../util/format.dart';
import '../util/motion.dart';
import '../widgets/contour_header.dart';
import '../widgets/product_thumb.dart';
import '../widgets/ui_kit.dart';
import 'item_edit_screen.dart';

/// Global, cross-trip shopping list (design plan Shopping tab). Trip lines are
/// derived from need-to-buy items; manual entries live in "Sonstiges".
class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  ShoppingSort _sort = ShoppingSort.trip;

  /// Selected trip picker (Option B). A [ShoppingGroup.key] (trip id or
  /// `'manual'`), or `null` for "Alle". In-memory only, like [_sort].
  String? _filterKey;

  Future<void> _addManual() async {
    final field = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('shopping_add_title')),
        content: TextField(
            controller: field,
            autofocus: true,
            decoration:
                InputDecoration(hintText: context.t('shopping_add_hint')),
            onSubmitted: (v) => Navigator.pop(ctx, v)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.t('common_cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, field.text),
              child: Text(context.t('common_add'))),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      ref
          .read(appDataProvider.notifier)
          .addManualEntry(ManualEntry(id: const Uuid().v4(), name: name.trim()));
    }
  }

  void _flash(String m) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(m), duration: const Duration(milliseconds: 1400)));

  /// Quick inline edit for the two things you tweak while shopping: price per
  /// unit and quantity. Applies to the manual entry or the underlying trip item.
  Future<void> _editPrice(ShoppingLine line) async {
    final data = ref.read(appDataProvider).valueOrNull;
    if (data == null) return;
    final c = ref.read(appDataProvider.notifier);

    double? currentPrice;
    if (line.isManual) {
      currentPrice = data.manualEntries
          .firstWhereOrNull((e) => e.id == line.manualId)
          ?.pricePerUnit;
    } else {
      currentPrice = data.trips
          .firstWhereOrNull((t) => t.id == line.tripId)
          ?.categories
          .firstWhereOrNull((cc) => cc.id == line.categoryId)
          ?.items
          .firstWhereOrNull((i) => i.id == line.id)
          ?.pricePerUnit;
    }

    final priceCtl =
        TextEditingController(text: currentPrice?.toString() ?? '');
    final qtyCtl = TextEditingController(text: '${line.quantity}');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${context.t('common_edit')} “${line.name}”'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceCtl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: context.t('item_price_label'),
                  prefixText: '€ ',
                  hintText: '0.00'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtl,
              keyboardType: TextInputType.number,
              decoration:
                  InputDecoration(labelText: context.t('item_quantity')),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.t('common_cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.t('common_save'))),
        ],
      ),
    );
    if (saved != true) return;

    final newPrice = double.tryParse(priceCtl.text.trim().replaceAll(',', '.'));
    final newQty = (int.tryParse(qtyCtl.text.trim()) ?? line.quantity).clamp(1, 9999);

    if (line.isManual) {
      final m = data.manualEntries.firstWhere((e) => e.id == line.manualId);
      c.updateManualEntry(
          m.copyWith(pricePerUnit: () => newPrice, quantity: newQty));
    } else {
      final trip = data.trips.firstWhere((t) => t.id == line.tripId);
      final cat = trip.categories.firstWhere((cc) => cc.id == line.categoryId);
      final item = cat.items.firstWhere((i) => i.id == line.id);
      c.updateItem(trip.id, cat.id,
          item.copyWith(pricePerUnit: () => newPrice, quantity: newQty));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final data = ref.watch(appDataProvider).valueOrNull;
    final allGroups =
        data == null ? <ShoppingGroup>[] : buildShoppingGroups(data, _sort);
    // Ignore a stale selection (e.g. the picked trip's last item was bought).
    final activeKey =
        allGroups.any((g) => g.key == _filterKey) ? _filterKey : null;
    final groups = filterShoppingGroups(allGroups, activeKey);
    final total = shoppingTotal(groups);
    final c = ref.read(appDataProvider.notifier);

    return Column(
      children: [
        ContourHeader(
          padding: const EdgeInsets.fromLTRB(24, 44, 24, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.t('shopping_title'),
                      style: AppText.display(24, color: p.onHeader)),
                  _RoundIconButton(icon: Icons.add, onTap: _addManual),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (total > 0)
                    Text('${context.t('shopping_total')} ${fmtPrice(total)}',
                        style: AppText.mono(12, color: p.onHeaderMuted))
                  else
                    const SizedBox(),
                  _SortToggle(
                    sort: _sort,
                    onChanged: (s) => setState(() => _sort = s),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (allGroups.length >= 2)
          _TripFilterBar(
            groups: allGroups,
            activeKey: activeKey,
            onSelect: (k) => setState(() => _filterKey = k),
          ),
        Expanded(
          child: groups.isEmpty
              ? Center(
                  child: Text(context.t('shopping_empty'),
                      style: AppText.body(14, color: p.slate)))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    ContentColumn(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final g in groups)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _GroupCard(
                                group: g,
                                onEditPrice: _editPrice,
                                onBuy: (line) {
                                  if (line.isManual) {
                                    c.setManualBought(line.manualId!, true);
                                  } else {
                                    c.markItemOwned(
                                        line.tripId!, line.categoryId!, line.id);
                                  }
                                  if (line.totalPrice != null) {
                                    _flash(
                                        '+${fmtPrice(line.totalPrice!)} ${context.t('shopping_moved_to_spent')}');
                                  }
                                },
                                onEdit: (line) {
                                  if (line.isManual) {
                                    final m = data!.manualEntries
                                        .firstWhere((e) => e.id == line.manualId);
                                    Navigator.of(context).push(MaterialPageRoute(
                                        builder: (_) =>
                                            ItemEditScreen(manualEntry: m)));
                                  } else {
                                    // Jump straight to the item editor for the
                                    // underlying trip item.
                                    final trip = data!.trips
                                        .firstWhere((t) => t.id == line.tripId);
                                    final cat = trip.categories
                                        .firstWhere((cc) => cc.id == line.categoryId);
                                    final item = cat.items
                                        .firstWhere((i) => i.id == line.id);
                                    Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => ItemEditScreen(
                                        tripId: trip.id,
                                        categoryId: cat.id,
                                        categoryName: cat.name,
                                        existing: item,
                                      ),
                                    ));
                                  }
                                },
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              context.t('shopping_hint'),
                              textAlign: TextAlign.center,
                              style: AppText.body(11, color: p.slate),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.onBuy,
    required this.onEdit,
    required this.onEditPrice,
  });
  final ShoppingGroup group;
  final void Function(ShoppingLine) onBuy;
  final void Function(ShoppingLine) onEdit;
  final void Function(ShoppingLine) onEditPrice;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SurfaceCard(
      clip: true,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: p.border))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(group.name, style: AppText.display(14, color: p.ink)),
                if (group.subtotal > 0)
                  Text(fmtPrice(group.subtotal),
                      style: AppText.mono(12, color: p.inkMuted)),
              ],
            ),
          ),
          for (final line in group.lines)
            _LineRow(
              line: line,
              onBuy: () => onBuy(line),
              onEdit: () => onEdit(line),
              onEditPrice: () => onEditPrice(line),
            ),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.line,
    required this.onBuy,
    required this.onEdit,
    required this.onEditPrice,
  });
  final ShoppingLine line;
  final VoidCallback onBuy, onEdit, onEditPrice;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: p.border))),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onBuy,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(duration: Motion.base, curve: Motion.curve,
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: line.isManual ? p.slate : p.rust, width: 2),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (line.imageFile != null) ...[
            ProductThumb(line.imageFile, size: 40),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: GestureDetector(
              onTap: onEdit,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                          child: Text(line.name,
                              style: AppText.body(13.5, color: p.ink))),
                      if (line.quantity > 1) ...[
                        const SizedBox(width: 6),
                        TagPill(
                            text: '×${line.quantity}',
                            bg: p.slateSoft,
                            fg: p.inkMuted),
                      ],
                    ],
                  ),
                  if (line.note.isNotEmpty)
                    Text(line.note, style: AppText.body(12, color: p.inkMuted)),
                  if (line.link != null && line.link!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_new, size: 11, color: p.rust),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(line.link!,
                                style: AppText.body(12, color: p.rust),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onEditPrice,
            behavior: HitTestBehavior.opaque,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (line.totalPrice != null)
                    TagPill(
                        text: fmtPrice(line.totalPrice!),
                        bg: p.rustSoft,
                        fg: p.rust)
                  else
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: p.rust.withValues(alpha: 0.5)),
                      ),
                      child: Text('+ €', style: AppText.mono(10, color: p.rust)),
                    ),
                  if (line.totalWeightGrams != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(fmtWeight(line.totalWeightGrams!),
                          style: AppText.mono(10, color: p.inkMuted)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortToggle extends StatelessWidget {
  const _SortToggle({required this.sort, required this.onChanged});
  final ShoppingSort sort;
  final ValueChanged<ShoppingSort> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget seg(ShoppingSort s, String label) {
      final active = sort == s;
      return GestureDetector(
        onTap: () => onChanged(s),
        child: AnimatedContainer(duration: Motion.base, curve: Motion.curve,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          color: active ? Colors.white.withValues(alpha: 0.18) : Colors.transparent,
          child: Text(label,
              style: AppText.mono(10,
                  color: active ? p.onHeader : const Color(0xFF9BA08C))),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(duration: Motion.base, curve: Motion.curve,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            seg(ShoppingSort.trip, context.t('sort_trip')),
            seg(ShoppingSort.price, context.t('sort_price')),
          ],
        ),
      ),
    );
  }
}

/// Horizontal trip picker (Option B). "Alle" (null key) plus one pill per
/// group; tapping a pill narrows the list to that trip. Scrolls when the trips
/// outrun the width.
class _TripFilterBar extends StatelessWidget {
  const _TripFilterBar({
    required this.groups,
    required this.activeKey,
    required this.onSelect,
  });
  final List<ShoppingGroup> groups;
  final String? activeKey;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    Widget pill(String label, String? key) {
      final active = key == activeKey;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => onSelect(key),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: Motion.base,
            curve: Motion.curve,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: active ? p.ink : p.surface,
              borderRadius: BorderRadius.circular(999),
              border:
                  Border.all(color: active ? p.ink : p.border, width: 1.5),
            ),
            child: Text(label,
                style: AppText.body(12.5,
                    color: active ? p.bg : p.ink,
                    weight: active ? FontWeight.w500 : FontWeight.w400)),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      color: p.bg,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            pill(context.t('shopping_filter_all'), null),
            for (final g in groups) pill(g.name, g.key),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
            width: 38, height: 38, child: Icon(icon, size: 18, color: p.onHeader)),
      ),
    );
  }
}
