import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../models/template.dart';
import '../state/app_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_text.dart';
import '../util/format.dart';
import '../widgets/contour_header.dart';
import '../widgets/ui_kit.dart';

/// Template library / suggestions (design plan). When opened with a [tripId] the
/// list is filtered to the trip's camp style and each item gets an "Add"
/// action; otherwise it's a read-only browse of the whole library.
class TemplateScreen extends ConsumerStatefulWidget {
  const TemplateScreen({super.key, this.tripId});
  final String? tripId;

  @override
  ConsumerState<TemplateScreen> createState() => _TemplateScreenState();
}

class _TemplateScreenState extends ConsumerState<TemplateScreen> {
  bool _showAllStyles = false;
  final Set<String> _added = {};

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final data = ref.watch(appDataProvider).valueOrNull;
    final library = data?.templateLibrary ?? const <TemplateCategory>[];
    final trip = widget.tripId == null
        ? null
        : data?.trips.firstWhereOrNull((t) => t.id == widget.tripId);
    final styleKey = trip?.campStyleKey;
    final canAdd = trip != null;
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
                Text(context.t('template_title'),
                    style: AppText.display(18, color: p.onHeader)),
                const Spacer(),
                if (canAdd && !_showAllStyles && trip.campStyle != null)
                  TagPill(
                    text: '${trip.campStyle!.icon} ${trip.campStyle!.label}',
                    bg: Colors.white.withValues(alpha: 0.14),
                    fg: p.onHeader,
                    mono: false,
                  ),
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
                      for (final cat in library)
                        _buildCategory(context, c, cat, styleKey, canAdd),
                      if (canAdd)
                        TextButton(
                          onPressed: () =>
                              setState(() => _showAllStyles = !_showAllStyles),
                          child: Text(
                            context.t(_showAllStyles
                                ? 'template_show_this'
                                : 'template_show_all'),
                            style: AppText.mono(12, color: p.inkMuted),
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

  Widget _buildCategory(
    BuildContext context,
    AppController c,
    TemplateCategory cat,
    String? styleKey,
    bool canAdd,
  ) {
    final p = context.palette;
    final items = cat.items
        .where((it) => !canAdd || _showAllStyles || it.matchesStyle(styleKey))
        .toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SurfaceCard(
        clip: true,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: p.border))),
              child: Text(cat.name, style: AppText.display(16, color: p.ink)),
            ),
            for (final it in items)
              _TemplateRow(
                item: it,
                canAdd: canAdd,
                added: _added.contains(it.id),
                onAdd: () {
                  c.addFromTemplate(widget.tripId!, cat.name, it);
                  setState(() => _added.add(it.id));
                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(SnackBar(
                        content: Text(context.t('common_added').replaceFirst('{name}', it.name)),
                        duration: const Duration(milliseconds: 900)));
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _TemplateRow extends StatelessWidget {
  const _TemplateRow({
    required this.item,
    required this.canAdd,
    required this.added,
    required this.onAdd,
  });
  final TemplateItem item;
  final bool canAdd, added;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration:
          BoxDecoration(border: Border(top: BorderSide(color: p.border))),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                        child:
                            Text(item.name, style: AppText.body(13.5, color: p.ink))),
                    if (item.isUniversal) ...[
                      const SizedBox(width: 6),
                      Text('· ${context.t('tmpl_universal')}', style: AppText.body(11, color: p.slate)),
                    ],
                  ],
                ),
                if (item.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(item.note, style: AppText.body(12, color: p.inkMuted)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (item.weightGrams != null)
            Text(fmtWeight(item.weightGrams!),
                style: AppText.mono(12, color: p.inkMuted)),
          if (canAdd) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: added ? null : onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: added ? p.mossSoft : p.rust,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(context.t(added ? 'tmpl_added' : 'tmpl_add'),
                    style: AppText.mono(12,
                        color: added ? p.moss : Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
