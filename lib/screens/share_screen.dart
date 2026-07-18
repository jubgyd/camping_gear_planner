import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/item_status.dart';
import '../models/trip.dart';
import '../state/app_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_text.dart';
import '../util/format.dart';
import '../widgets/ui_kit.dart';

/// Share checklist as plain text (design plan Share). Excludes "not needed"
/// items so recipients only see what's actually being brought.
class ShareScreen extends ConsumerWidget {
  const ShareScreen({super.key, required this.tripId});
  final String tripId;

  String _buildText(Trip trip) {
    final lines = <String>[trip.name];
    if (trip.country != null) {
      lines.add('${trip.country!.flag} ${trip.country!.name}');
    }
    final dl = fmtDateRange(trip.startDate, trip.endDate);
    if (dl != null) lines.add(dl);
    lines.add('');
    for (final cat in trip.categories) {
      final items =
          cat.items.where((i) => i.status != ItemStatus.notNeeded).toList();
      if (items.isEmpty) continue;
      lines.add(cat.name);
      for (final it in items) {
        final mark = it.status == ItemStatus.owned ? '☑' : '☐';
        final qty = it.quantity > 1 ? ' ×${it.quantity}' : '';
        lines.add('$mark ${it.name}$qty');
      }
      lines.add('');
    }
    return lines.join('\n').trim();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final trip =
        ref.watch(appDataProvider).valueOrNull?.trips.firstWhereOrNull((t) => t.id == tripId);
    if (trip == null) {
      return Scaffold(
          backgroundColor: p.bg, body: const Center(child: Text('Trip not found')));
    }
    final text = _buildText(trip);

    void flash(String m) => ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(m), duration: const Duration(milliseconds: 1400)));

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
                      icon: Icon(Icons.arrow_back, color: p.ink),
                      onPressed: () => Navigator.of(context).pop()),
                  const Spacer(),
                  Text('SHARE CHECKLIST',
                      style: AppText.mono(12, color: p.inkMuted, letterSpacing: 1.5)),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: ContentColumn(
                maxWidth: 600,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  children: [
                    Text(trip.name, style: AppText.display(18, color: p.ink)),
                    const SizedBox(height: 12),
                    SurfaceCard(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(text,
                          style: AppText.mono(12, color: p.ink)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '"Not needed" items are left out — whoever you share this with only sees what\'s actually being brought.',
                      style: AppText.body(12, color: p.slate, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            ContentColumn(
              maxWidth: 600,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  children: [
                    _ShareButton(
                      label: '📋 Copy as text',
                      filled: true,
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: text));
                        flash('✓ Copied to clipboard');
                      },
                    ),
                    const SizedBox(height: 10),
                    _ShareButton(
                      label: '📄 Export as PDF',
                      filled: false,
                      onTap: () => flash('PDF export — coming in a later version'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.label, required this.filled, required this.onTap});
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? p.rust : p.surface,
          borderRadius: BorderRadius.circular(12),
          border: filled ? null : Border.all(color: p.border),
        ),
        child: Text(label,
            style: AppText.mono(14, color: filled ? Colors.white : p.ink)),
      ),
    );
  }
}
