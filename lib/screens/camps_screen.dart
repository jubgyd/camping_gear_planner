import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/trip.dart';
import '../state/app_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_text.dart';
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
  bool _archivedExpanded = false;

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
              Text('Camps', style: AppText.display(26, color: p.bg)),
              _RoundIconButton(icon: Icons.add, onTap: _openAddTrip),
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

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  ContentColumn(
                    maxWidth: 900,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (active.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 48),
                            child: Text('No active trips — tap + to plan one.',
                                textAlign: TextAlign.center,
                                style: AppText.body(14, color: p.slate)),
                          ),
                        _TripGrid(
                            trips: active,
                            wide: wide,
                            onOpen: _openTrip,
                            muted: false),
                        if (archived.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _ArchivedHeader(
                            count: archived.length,
                            expanded: _archivedExpanded,
                            onTap: () => setState(
                                () => _archivedExpanded = !_archivedExpanded),
                          ),
                          if (_archivedExpanded)
                            _TripGrid(
                                trips: archived,
                                wide: wide,
                                onOpen: _openTrip,
                                muted: true),
                        ],
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

class _ArchivedHeader extends StatelessWidget {
  const _ArchivedHeader({
    required this.count,
    required this.expanded,
    required this.onTap,
  });
  final int count;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ARCHIVED ($count)',
                style: AppText.mono(12, color: p.inkMuted, letterSpacing: 1.5)),
            Icon(expanded ? Icons.expand_less : Icons.expand_more,
                size: 18, color: p.slate),
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
          width: 38,
          height: 38,
          child: Icon(icon, size: 18, color: p.bg),
        ),
      ),
    );
  }
}
