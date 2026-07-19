import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_strings.dart';
import '../models/packing_list.dart';
import '../models/template.dart';
import '../state/app_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_text.dart';
import '../util/format.dart';
import '../widgets/ui_kit.dart';

const _uuid = Uuid();

/// Creates an editable custom copy of [source] (fresh ids), stores it, and
/// returns it. Used by "Duplicate to edit" on built-in premades.
PackingList duplicateList(WidgetRef ref, PackingList source, String copySuffix) {
  final copy = PackingList(
    id: _uuid.v4(),
    name: '${source.name}$copySuffix',
    description: source.description,
    categories: [
      for (final c in source.categories)
        TemplateCategory(
          id: _uuid.v4(),
          name: c.name,
          order: c.order,
          items: [
            for (final it in c.items)
              TemplateItem(
                id: _uuid.v4(),
                name: it.name,
                note: it.note,
                link: it.link,
                weightGrams: it.weightGrams,
                styles: it.styles,
              ),
          ],
        ),
    ],
  );
  ref.read(appDataProvider.notifier).addPackingList(copy);
  return copy;
}

/// Full editor for a custom packing list: name, description, and categories of
/// items (add / rename / delete throughout). Edits a working copy and persists
/// on Save. Built-in premades open [readOnly] and offer "Duplicate to edit".
class ListEditScreen extends ConsumerStatefulWidget {
  const ListEditScreen({super.key, this.existing, this.readOnly = false});

  /// The list being edited, or null to create a new one.
  final PackingList? existing;
  final bool readOnly;

  @override
  ConsumerState<ListEditScreen> createState() => _ListEditScreenState();
}

class _ListEditScreenState extends ConsumerState<ListEditScreen> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late List<TemplateCategory> _cats;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _desc = TextEditingController(text: e?.description ?? '');
    // Deep-ish copy so edits don't mutate the stored list until Save.
    _cats = [
      for (final c in e?.categories ?? const <TemplateCategory>[])
        TemplateCategory(
            id: c.id, name: c.name, order: c.order, items: [...c.items]),
    ];
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  bool get _readOnly => widget.readOnly;

  int get _itemCount => _cats.fold(0, (s, c) => s + c.items.length);

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final list = PackingList(
      id: widget.existing?.id ?? _uuid.v4(),
      name: name,
      description: _desc.text.trim(),
      categories: _cats,
    );
    final c = ref.read(appDataProvider.notifier);
    if (widget.existing == null) {
      c.addPackingList(list);
    } else {
      c.updatePackingList(list);
    }
    Navigator.of(context).pop();
  }

  Future<void> _deleteList() async {
    final e = widget.existing;
    if (e == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text(context.t('lists_delete_title').replaceFirst('{name}', e.name)),
        content: Text(context.t('lists_delete_body')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.t('common_cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.t('common_delete')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    ref.read(appDataProvider.notifier).deletePackingList(e.id);
    if (mounted) Navigator.of(context).pop();
  }

  void _duplicate() {
    final src = PackingList(
      id: widget.existing?.id ?? _uuid.v4(),
      name: _name.text.trim(),
      description: _desc.text.trim(),
      categories: _cats,
    );
    final copy = duplicateList(ref, src, context.t('list_copy_suffix'));
    // Swap the read-only view for an editable editor on the new copy.
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ListEditScreen(existing: copy)));
  }

  // --- Category ops -------------------------------------------------------

  Future<void> _addCategory() async {
    final name = await _promptText(
        title: context.t('td_newcat_title'), hint: context.t('td_newcat_hint'));
    if (name == null || name.trim().isEmpty) return;
    setState(() => _cats.add(TemplateCategory(
        id: _uuid.v4(), name: name.trim(), order: _cats.length)));
  }

  Future<void> _renameCategory(int i) async {
    final name = await _promptText(
        title: context.t('list_cat_rename'),
        hint: context.t('td_newcat_hint'),
        initial: _cats[i].name);
    if (name == null || name.trim().isEmpty) return;
    setState(() => _cats[i] = TemplateCategory(
        id: _cats[i].id,
        name: name.trim(),
        order: _cats[i].order,
        items: _cats[i].items));
  }

  void _deleteCategory(int i) => setState(() => _cats.removeAt(i));

  // --- Item ops -----------------------------------------------------------

  Future<void> _addItem(int catIndex) async {
    final item = await _itemDialog();
    if (item == null) return;
    setState(() {
      final c = _cats[catIndex];
      _cats[catIndex] = TemplateCategory(
          id: c.id, name: c.name, order: c.order, items: [...c.items, item]);
    });
  }

  Future<void> _editItem(int catIndex, int itemIndex) async {
    final existing = _cats[catIndex].items[itemIndex];
    final item = await _itemDialog(existing: existing);
    if (item == null) return;
    setState(() {
      final c = _cats[catIndex];
      final items = [...c.items];
      items[itemIndex] = item;
      _cats[catIndex] =
          TemplateCategory(id: c.id, name: c.name, order: c.order, items: items);
    });
  }

  void _deleteItem(int catIndex, int itemIndex) => setState(() {
        final c = _cats[catIndex];
        final items = [...c.items]..removeAt(itemIndex);
        _cats[catIndex] = TemplateCategory(
            id: c.id, name: c.name, order: c.order, items: items);
      });

  // --- Dialog helpers -----------------------------------------------------

  Future<String?> _promptText(
      {required String title, required String hint, String? initial}) {
    final ctl = TextEditingController(text: initial ?? '');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctl,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.t('common_cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctl.text),
              child: Text(context.t('common_save'))),
        ],
      ),
    );
  }

  /// Add/edit dialog for a single item: name (required), weight, note, link.
  Future<TemplateItem?> _itemDialog({TemplateItem? existing}) {
    final name = TextEditingController(text: existing?.name ?? '');
    final weight =
        TextEditingController(text: existing?.weightGrams?.toString() ?? '');
    final note = TextEditingController(text: existing?.note ?? '');
    final link = TextEditingController(text: existing?.link ?? '');
    return showDialog<TemplateItem>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t(
            existing == null ? 'td_add_item' : 'list_item_edit')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: name,
                  autofocus: true,
                  decoration:
                      InputDecoration(labelText: context.t('item_name_hint'))),
              const SizedBox(height: 10),
              TextField(
                  controller: weight,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(labelText: context.t('item_weight_unit'))),
              const SizedBox(height: 10),
              TextField(
                  controller: note,
                  decoration:
                      InputDecoration(labelText: context.t('item_note'))),
              const SizedBox(height: 10),
              TextField(
                  controller: link,
                  decoration: InputDecoration(
                      labelText: context.t('item_link'), hintText: 'https://...')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.t('common_cancel'))),
          FilledButton(
            onPressed: () {
              final n = name.text.trim();
              if (n.isEmpty) return;
              Navigator.pop(
                  ctx,
                  TemplateItem(
                    id: existing?.id ?? _uuid.v4(),
                    name: n,
                    note: note.text.trim(),
                    link: link.text.trim().isEmpty ? null : link.text.trim(),
                    weightGrams: int.tryParse(weight.text.trim()),
                    styles: existing?.styles ?? const [],
                  ));
            },
            child: Text(context.t('common_save')),
          ),
        ],
      ),
    );
  }

  // --- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final title = _readOnly
        ? (widget.existing?.name ?? context.t('lists_title'))
        : context.t(widget.existing == null ? 'list_new_title' : 'list_edit_title');

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
                  Text(title.toUpperCase(),
                      style: AppText.mono(12,
                          color: p.inkMuted, letterSpacing: 1.5)),
                  const Spacer(),
                  if (_readOnly)
                    const SizedBox(width: 48)
                  else
                    TextButton(
                        onPressed: _save,
                        child: Text(context.t('common_save'),
                            style: AppText.mono(14,
                                color: p.rust, weight: FontWeight.w500))),
                ],
              ),
            ),
            Expanded(
              child: ContentColumn(
                maxWidth: 640,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                  children: [
                    if (_readOnly)
                      _readOnlyHeader(p)
                    else ...[
                      TextField(
                        controller: _name,
                        style: AppText.display(24, color: p.ink),
                        cursorColor: p.rust,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: context.t('list_name_hint'),
                          hintStyle: AppText.display(24, color: p.slate),
                          enabledBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: p.border, width: 2)),
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: p.rust, width: 2)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _desc,
                        style: AppText.body(14, color: p.ink),
                        cursorColor: p.rust,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: context.t('list_desc_hint'),
                          hintStyle: AppText.body(14, color: p.slate),
                          filled: true,
                          fillColor: p.surface,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: p.border)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: p.border)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: p.rust)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 11),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (_cats.isEmpty && _readOnly)
                      const SizedBox()
                    else if (_cats.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(context.t('list_empty_cats'),
                            textAlign: TextAlign.center,
                            style: AppText.body(13, color: p.slate)),
                      ),
                    for (var i = 0; i < _cats.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _categoryCard(p, i),
                      ),
                    if (!_readOnly) ...[
                      const SizedBox(height: 4),
                      TextButton.icon(
                        onPressed: _addCategory,
                        icon: Icon(Icons.add, size: 18, color: p.rust),
                        label: Text(context.t('td_add_category'),
                            style: AppText.body(14, color: p.rust)),
                      ),
                    ],
                    if (_readOnly) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _duplicate,
                        icon: const Icon(Icons.copy_all_outlined, size: 18),
                        label: Text(context.t('list_duplicate')),
                        style: FilledButton.styleFrom(
                          backgroundColor: p.rust,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                    if (!_readOnly && widget.existing != null) ...[
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: _deleteList,
                        icon: Icon(Icons.delete_outline,
                            size: 18, color: Colors.red.shade600),
                        label: Text(context.t('list_delete'),
                            style:
                                AppText.body(14, color: Colors.red.shade600)),
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

  Widget _readOnlyHeader(AppPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.existing?.name ?? '',
            style: AppText.display(24, color: p.ink)),
        if ((widget.existing?.description ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(widget.existing!.description,
              style: AppText.body(13, color: p.inkMuted)),
        ],
        const SizedBox(height: 8),
        Text('$_itemCount ${context.t('addtrip_items')} · ${_cats.length} ${context.t('lists_categories')}',
            style: AppText.mono(11, color: p.slate)),
        const SizedBox(height: 10),
        Text(context.t('list_readonly_note'),
            style: AppText.body(12, color: p.slate, height: 1.4)),
      ],
    );
  }

  Widget _categoryCard(AppPalette p, int i) {
    final cat = _cats[i];
    return SurfaceCard(
      clip: true,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: p.border))),
            child: Row(
              children: [
                Expanded(
                    child: Text(cat.name,
                        style: AppText.display(15, color: p.ink))),
                if (!_readOnly) ...[
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.edit_outlined, size: 16, color: p.slate),
                    onPressed: () => _renameCategory(i),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.delete_outline, size: 16, color: p.slate),
                    onPressed: () => _deleteCategory(i),
                  ),
                ],
              ],
            ),
          ),
          for (var j = 0; j < cat.items.length; j++)
            _itemRow(p, i, j, cat.items[j]),
          if (!_readOnly)
            InkWell(
              onTap: () => _addItem(i),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: p.border))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 16, color: p.rust),
                    const SizedBox(width: 6),
                    Text(context.t('td_add_item'),
                        style: AppText.body(13, color: p.rust)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _itemRow(AppPalette p, int catIndex, int itemIndex, TemplateItem it) {
    final row = Container(
      decoration:
          BoxDecoration(border: Border(top: BorderSide(color: p.border))),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(it.name, style: AppText.body(13.5, color: p.ink)),
                if (it.note.isNotEmpty)
                  Text(it.note, style: AppText.body(12, color: p.inkMuted)),
              ],
            ),
          ),
          if (it.weightGrams != null)
            Text(fmtWeight(it.weightGrams!),
                style: AppText.mono(12, color: p.inkMuted)),
          if (!_readOnly) ...[
            const SizedBox(width: 4),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.delete_outline, size: 16, color: p.slate),
              onPressed: () => _deleteItem(catIndex, itemIndex),
            ),
          ],
        ],
      ),
    );
    if (_readOnly) return row;
    return InkWell(onTap: () => _editItem(catIndex, itemIndex), child: row);
  }
}
