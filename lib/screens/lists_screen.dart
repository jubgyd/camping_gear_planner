import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/packing_list.dart';
import '../state/app_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_text.dart';
import '../widgets/contour_header.dart';
import '../widgets/ui_kit.dart';

/// Manage starting lists: built-in premades (read-only) and the user's saved
/// custom lists (deletable). Lists are applied when creating a trip.
class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final lists = ref.watch(availableListsProvider);
    final c = ref.read(appDataProvider.notifier);

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
                Text('Lists', style: AppText.display(18, color: p.onHeader)),
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
                          'Start a trip from one of these. Save any trip as a custom list from its ⋯ menu.',
                          style: AppText.body(12, color: p.slate, height: 1.5),
                        ),
                      ),
                      for (final l in lists)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ListCard(
                            list: l,
                            onDelete: l.builtin
                                ? null
                                : () => _confirmDelete(context, c, l),
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

  Future<void> _confirmDelete(
      BuildContext context, AppController c, PackingList l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete “${l.name}”?'),
        content: const Text('This removes the saved list. Trips already created from it are unaffected.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) c.deletePackingList(l.id);
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({required this.list, this.onDelete});
  final PackingList list;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SurfaceCard(
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
                      text: list.builtin ? 'Vorlage' : 'Eigene',
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
                Text('${list.itemCount} items · ${list.categories.length} categories',
                    style: AppText.mono(11, color: p.slate)),
              ],
            ),
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
