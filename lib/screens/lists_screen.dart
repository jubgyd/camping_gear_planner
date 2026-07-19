import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../models/packing_list.dart';
import '../state/app_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_text.dart';
import '../widgets/contour_header.dart';
import '../widgets/ui_kit.dart';
import 'list_edit_screen.dart';

/// The Lists tab (left-bar nav): built-in premades (read-only, duplicable) and
/// the user's custom lists (editable + deletable). Lists seed a trip's whole
/// checklist when creating a trip.
class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});

  void _open(BuildContext context, PackingList l) =>
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ListEditScreen(existing: l, readOnly: l.builtin)));

  void _newList(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const ListEditScreen()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final lists = ref.watch(availableListsProvider);
    final c = ref.read(appDataProvider.notifier);

    return Column(
      children: [
        ContourHeader(
          padding: const EdgeInsets.fromLTRB(24, 44, 24, 22),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.t('lists_title'),
                  style: AppText.display(26, color: p.onHeader)),
              _RoundIconButton(
                  icon: Icons.add, onTap: () => _newList(context)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              ContentColumn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 4),
                      child: Text(
                        context.t('lists_help'),
                        style: AppText.body(12, color: p.slate, height: 1.5),
                      ),
                    ),
                    for (final l in lists)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ListCard(
                          list: l,
                          onTap: () => _open(context, l),
                          onDelete:
                              l.builtin ? null : () => _confirmDelete(context, c, l),
                          onDuplicate: l.builtin
                              ? () {
                                  final copy = duplicateList(
                                      ref, l, context.t('list_copy_suffix'));
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) =>
                                          ListEditScreen(existing: copy)));
                                }
                              : null,
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

  Future<void> _confirmDelete(
      BuildContext context, AppController c, PackingList l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('lists_delete_title').replaceFirst('{name}', l.name)),
        content: Text(context.t('lists_delete_body')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.t('common_cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.t('common_delete'))),
        ],
      ),
    );
    if (ok == true) c.deletePackingList(l.id);
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.list,
    required this.onTap,
    this.onDelete,
    this.onDuplicate,
  });
  final PackingList list;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                        child: Text(list.name,
                            style: AppText.display(16, color: p.ink))),
                    const SizedBox(width: 8),
                    TagPill(
                      text: context.t(
                          list.builtin ? 'addtrip_template' : 'addtrip_custom'),
                      bg: list.builtin ? p.slateSoft : p.mossSoft,
                      fg: list.builtin ? p.inkMuted : p.moss,
                    ),
                  ],
                ),
                if (list.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(list.description,
                      style: AppText.body(12.5, color: p.inkMuted)),
                ],
                const SizedBox(height: 4),
                Text('${list.itemCount} ${context.t('addtrip_items')} · ${list.categories.length} ${context.t('lists_categories')}',
                    style: AppText.mono(11, color: p.slate)),
              ],
            ),
          ),
          if (onDuplicate != null)
            IconButton(
              tooltip: context.t('list_duplicate'),
              icon: Icon(Icons.copy_all_outlined, size: 18, color: p.slate),
              onPressed: onDuplicate,
            ),
          if (onDelete != null)
            IconButton(
              icon: Icon(Icons.delete_outline, size: 18, color: p.slate),
              onPressed: onDelete,
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
          width: 38,
          height: 38,
          child: Icon(icon, size: 18, color: p.onHeader),
        ),
      ),
    );
  }
}
