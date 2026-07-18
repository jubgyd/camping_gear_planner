import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/gear_item.dart';
import '../state/app_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_text.dart';
import '../util/format.dart';
import '../widgets/contour_header.dart';
import '../widgets/ui_kit.dart';

/// The personal gear catalog ("My Gear"). Opened with a [tripId] it's a picker
/// — each item gets an "Add" that copies it into the trip. Without one it's a
/// manager where you add/edit/delete your gear.
class MyGearScreen extends ConsumerStatefulWidget {
  const MyGearScreen({super.key, this.tripId});
  final String? tripId;

  @override
  ConsumerState<MyGearScreen> createState() => _MyGearScreenState();
}

class _MyGearScreenState extends ConsumerState<MyGearScreen> {
  final Set<String> _added = {};

  bool get _picker => widget.tripId != null;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final gear = ref.watch(appDataProvider).valueOrNull?.gearLibrary ??
        const <GearItem>[];
    final c = ref.read(appDataProvider.notifier);

    // Group by category, preserving first-seen order.
    final groups = <String, List<GearItem>>{};
    for (final g in gear) {
      groups.putIfAbsent(g.category.isEmpty ? 'Sonstiges' : g.category, () => [])
          .add(g);
    }

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          ContourHeader(
            padding: const EdgeInsets.fromLTRB(16, 40, 20, 20),
            child: Row(
              children: [
                IconButton(
                    icon: Icon(Icons.arrow_back, color: p.onHeader, size: 20),
                    onPressed: () => Navigator.of(context).pop()),
                Text(_picker ? 'Aus meinem Fundus' : 'My Gear',
                    style: AppText.display(18, color: p.onHeader)),
                const Spacer(),
                _RoundIconButton(
                    icon: Icons.add, onTap: () => _editGear(context, c, null)),
              ],
            ),
          ),
          Expanded(
            child: gear.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No gear yet.\nTap + to add gear you own, then pick from it when planning trips.',
                        textAlign: TextAlign.center,
                        style: AppText.body(14, color: p.slate, height: 1.5),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      ContentColumn(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final entry in groups.entries)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _GearGroup(
                                  category: entry.key,
                                  items: entry.value,
                                  picker: _picker,
                                  addedIds: _added,
                                  onAdd: (g) {
                                    c.addGearToTrip(widget.tripId!, g);
                                    setState(() => _added.add(g.id));
                                    ScaffoldMessenger.of(context)
                                      ..clearSnackBars()
                                      ..showSnackBar(SnackBar(
                                          content: Text('Added ${g.name}'),
                                          duration:
                                              const Duration(milliseconds: 900)));
                                  },
                                  onEdit: (g) => _editGear(context, c, g),
                                  onDelete: (g) => c.deleteGearItem(g.id),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _editGear(
      BuildContext context, AppController c, GearItem? existing) async {
    final result = await showDialog<GearItem>(
      context: context,
      builder: (_) => _GearEditDialog(existing: existing),
    );
    if (result == null) return;
    if (existing == null) {
      c.addGearItem(result);
    } else {
      c.updateGearItem(result);
    }
  }
}

class _GearGroup extends StatelessWidget {
  const _GearGroup({
    required this.category,
    required this.items,
    required this.picker,
    required this.addedIds,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final String category;
  final List<GearItem> items;
  final bool picker;
  final Set<String> addedIds;
  final void Function(GearItem) onAdd;
  final void Function(GearItem) onEdit;
  final void Function(GearItem) onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SurfaceCard(
      clip: true,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: p.border))),
            child: Text(category, style: AppText.display(15, color: p.ink)),
          ),
          for (final g in items)
            Container(
              decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: p.border))),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: picker ? null : () => onEdit(g),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g.name, style: AppText.body(13.5, color: p.ink)),
                          if (g.note.isNotEmpty)
                            Text(g.note,
                                style: AppText.body(12, color: p.inkMuted)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (g.weightGrams != null)
                    Text(fmtWeight(g.weightGrams!),
                        style: AppText.mono(11, color: p.inkMuted)),
                  if (g.pricePerUnit != null) ...[
                    const SizedBox(width: 8),
                    Text(fmtPrice(g.pricePerUnit!),
                        style: AppText.mono(11, color: p.inkMuted)),
                  ],
                  const SizedBox(width: 10),
                  if (picker)
                    GestureDetector(
                      onTap: addedIds.contains(g.id) ? null : () => onAdd(g),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: addedIds.contains(g.id) ? p.mossSoft : p.rust,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(addedIds.contains(g.id) ? 'Added' : '+ Add',
                            style: AppText.mono(12,
                                color: addedIds.contains(g.id)
                                    ? p.moss
                                    : Colors.white)),
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 18, color: p.slate),
                      onPressed: () => onDelete(g),
                    ),
                ],
              ),
            ),
        ],
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

/// Compact add/edit dialog for a gear catalog entry.
class _GearEditDialog extends StatefulWidget {
  const _GearEditDialog({this.existing});
  final GearItem? existing;

  @override
  State<_GearEditDialog> createState() => _GearEditDialogState();
}

class _GearEditDialogState extends State<_GearEditDialog> {
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _note;
  late final TextEditingController _weight;
  late final TextEditingController _price;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _category = TextEditingController(text: e?.category ?? 'Sonstiges');
    _note = TextEditingController(text: e?.note ?? '');
    _weight = TextEditingController(text: e?.weightGrams?.toString() ?? '');
    _price = TextEditingController(text: e?.pricePerUnit?.toString() ?? '');
  }

  @override
  void dispose() {
    for (final c in [_name, _category, _note, _weight, _price]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final gear = GearItem(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: name,
      note: _note.text.trim(),
      link: widget.existing?.link,
      category: _category.text.trim().isEmpty ? 'Sonstiges' : _category.text.trim(),
      weightGrams: int.tryParse(_weight.text.trim()),
      pricePerUnit: double.tryParse(_price.text.trim().replaceAll(',', '.')),
    );
    Navigator.of(context).pop(gear);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add gear' : 'Edit gear'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 10),
            TextField(
                controller: _category,
                decoration: const InputDecoration(labelText: 'Category')),
            const SizedBox(height: 10),
            TextField(
                controller: _note,
                decoration: const InputDecoration(labelText: 'Note')),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                      controller: _weight,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Weight (g)')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Price', prefixText: '€ ')),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
