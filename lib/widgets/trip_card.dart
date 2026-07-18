import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../theme/app_palette.dart';
import '../theme/app_text.dart';
import '../util/format.dart';
import 'budget_gauge.dart';
import 'country_flag.dart';
import 'progress_ridge.dart';
import 'ui_kit.dart';

/// A trip summary card for the Camps list (design plan `renderCard`).
class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.trip, required this.onTap, this.muted = false});

  final Trip trip;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dateLabel = fmtDateRange(trip.startDate, trip.endDate);
    final cd = daysUntil(trip.startDate, trip.endDate);

    return Opacity(
      opacity: muted ? 0.7 : 1,
      child: SurfaceCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (trip.country != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 10, top: 3),
                    child: CountryFlag(trip.country!.code,
                        width: 30, height: 20),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(trip.name,
                                style: AppText.display(18, color: p.ink)),
                          ),
                          if (trip.campStyle != null) ...[
                            const SizedBox(width: 6),
                            Text(trip.campStyle!.icon,
                                style: const TextStyle(fontSize: 15)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (trip.season != null)
                            '${trip.season!.icon} ${trip.season!.label}',
                          if (trip.subtitle.isNotEmpty) trip.subtitle,
                        ].join(' · '),
                        style: AppText.body(13, color: p.inkMuted),
                      ),
                      if (dateLabel != null) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('🗓 $dateLabel',
                                style: AppText.mono(10, color: p.slate)),
                            if (cd != null &&
                                cd.state == CountdownState.upcoming)
                              TagPill(
                                  text: cd.label,
                                  bg: p.rustSoft,
                                  fg: p.rust),
                            if (cd != null &&
                                cd.state == CountdownState.ongoing)
                              TagPill(
                                  text: 'happening now',
                                  bg: p.mossSoft,
                                  fg: p.moss),
                            if (muted)
                              TagPill(
                                  text: 'archived',
                                  bg: p.slateSoft,
                                  fg: p.slate),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: p.slate),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: ProgressRidge(pct: trip.readyPercent)),
                const SizedBox(width: 12),
                Text('${trip.readyPercent}%',
                    style: AppText.mono(12, color: p.inkMuted)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Packed ${fmtWeight(trip.ownedWeightGrams)} · Full ${fmtWeight(trip.fullWeightGrams)}',
              style: AppText.mono(12, color: p.inkMuted),
            ),
            if (trip.budget != null) ...[
              const SizedBox(height: 12),
              BudgetGauge(
                  spent: trip.spent,
                  projected: trip.projected,
                  budget: trip.budget!),
            ],
          ],
        ),
      ),
    );
  }
}
