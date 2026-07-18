import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/trip.dart';
import '../state/app_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_text.dart';
import '../util/backup.dart';
import '../util/motion.dart';
import '../widgets/contour_header.dart';
import '../widgets/trip_card.dart';
import '../widgets/ui_kit.dart';
import 'add_trip_screen.dart';
import 'trip_detail_screen.dart';

/// Trip list — the home tab (design plan Camps tab, §8.1).
class CampsScreen extends ConsumerStatefulWidget {
  const CampsScreen({super.key});

  @override
  ConsumerState<CampsScreen> createState() => _CampsScreenState();
}

class _CampsScreenState extends ConsumerState<CampsScreen> {
  int _tab = 0; // 0 = active, 1 = archived

  void _openAddTrip() =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddTripScreen()));

  void _openTrip(String id) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => TripDetailScreen(tripId: id)));

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dataAsync = ref.watch(appDataProvider);

    return Column(
      children: [
        ContourHeader(
          padding: const EdgeInsets.fromLTRB(24, 44, 24, 22),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Camps', style: AppText.display(26, color: p.onHeader)),
              Row(
                children: [
                  _BackupMenuButton(
                    onSave: () => saveBackup(context, ref),
                    onLoad: () => loadBackup(context, ref),
                  ),
                  const SizedBox(width: 12),
                  _RoundIconButton(icon: Icons.add, onTap: _openAddTrip),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: dataAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load: $e')),
            data: (data) {
              final active = data.trips.where((t) => !t.archived).toList();
              final archived = data.trips.where((t) => t.archived).toList();
              final wide = isWide(context);
              final showing = _tab == 0 ? active : archived;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  ContentColumn(
                    maxWidth: 900,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TripTabs(
                          index: _tab,
                          activeCount: active.length,
                          archivedCount: archived.length,
                          onSelect: (i) => setState(() => _tab = i),
                        ),
                        const SizedBox(height: 16),
                        if (showing.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 48),
                            child: Text(
                                _tab == 0
                                    ? 'No active trips — tap + to plan one.'
                                    : 'No archived trips yet.',
                                textAlign: TextAlign.center,
                                style: AppText.body(14, color: p.slate)),
                          ),
                        _TripGrid(
                            trips: showing,
                            wide: wide,
                            onOpen: _openTrip,
                            muted: _tab == 1),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TripGrid extends StatelessWidget {
  const _TripGrid({
    required this.trips,
    required this.wide,
    required this.onOpen,
    required this.muted,
  });

  final List<Trip> trips;
  final bool wide;
  final ValueChanged<String> onOpen;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) return const SizedBox.shrink();
    final cards = [
      for (final t in trips)
        TripCard(trip: t, muted: muted, onTap: () => onOpen(t.id)),
    ];
    if (!wide) {
      return Column(
        children: [
          for (final c in cards)
            Padding(padding: const EdgeInsets.only(bottom: 12), child: c),
        ],
      );
    }
    // Two-column masonry-ish grid on wide screens.
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final c in cards)
          SizedBox(width: 430, child: c),
      ],
    );
  }
}

/// Active / Archived segmented tabs at the top of the trip list.
class _TripTabs extends StatelessWidget {
  const _TripTabs({
    required this.index,
    required this.activeCount,
    required this.archivedCount,
    required this.onSelect,
  });
  final int index;
  final int activeCount;
  final int archivedCount;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget seg(int i, String label) {
      final on = index == i;
      return Expanded(
        child: GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: Motion.base,
            curve: Motion.curve,
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? p.selectedBg : p.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: on ? p.selectedBg : p.border, width: 1.5),
            ),
            child: Text(label,
                style: AppText.body(13, color: on ? p.bg : p.ink)),
          ),
        ),
      );
    }

    return Row(
      children: [
        seg(0, 'Active ($activeCount)'),
        const SizedBox(width: 8),
        seg(1, 'Archived ($archivedCount)'),
      ],
    );
  }
}

/// Save / load a backup. A round header button (identical to the + button)
/// that opens a small menu anchored just beneath itself.
class _BackupMenuButton extends StatelessWidget {
  const _BackupMenuButton({required this.onSave, required this.onLoad});
  final VoidCallback onSave;
  final VoidCallback onLoad;

  Future<void> _open(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(box.size.bottomLeft(Offset.zero), ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    final choice = await showMenu<String>(
      context: context,
      position: position,
      items: const [
        PopupMenuItem(value: 'save', child: Text('💾  Save a backup')),
        PopupMenuItem(value: 'load', child: Text('📂  Load a backup')),
      ],
    );
    if (choice == 'save') onSave();
    if (choice == 'load') onLoad();
  }

  @override
  Widget build(BuildContext context) {
    // Builder gives a context whose render object is this button, so the menu
    // anchors correctly.
    return Builder(
      builder: (context) => _RoundIconButton(
        icon: Icons.save_alt,
        onTap: () => _open(context),
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
