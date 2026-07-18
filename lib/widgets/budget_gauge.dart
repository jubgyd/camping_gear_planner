import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_text.dart';
import '../util/format.dart';

/// Two-layer budget bar: a solid fill for money already spent (owned items) and
/// a lighter fill for projected/committed spend (need-to-buy), over a
/// tick-marked track. Turns rust and shows an overflow note when projected >
/// budget (design plan `BudgetGauge`).
class BudgetGauge extends StatelessWidget {
  const BudgetGauge({
    super.key,
    required this.spent,
    required this.projected,
    required this.budget,
    this.onDark = false,
  });

  final double spent;
  final double projected;
  final double budget;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (budget <= 0) return const SizedBox.shrink();
    final over = projected > budget;
    final double pctSpent = (spent / budget).clamp(0.0, 1.0).toDouble();
    final double pctProjected = (projected / budget).clamp(0.0, 1.0).toDouble();

    final track = onDark ? Colors.white.withValues(alpha: 0.2) : p.slateSoft;
    final solid = over ? p.rust : p.moss;
    final light = over
        ? const Color(0xFFE7B49B)
        : (onDark ? const Color(0xFF8FB08C) : p.mossSoft);
    final tick = onDark
        ? Colors.black.withValues(alpha: 0.25)
        : Colors.white.withValues(alpha: 0.7);
    final captionColor = onDark ? const Color(0xFFC8CCB8) : p.inkMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 8,
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                return Stack(
                  children: [
                    Container(color: track),
                    Container(width: w * pctProjected, color: light),
                    Container(width: w * pctSpent, color: solid),
                    for (final t in const [0.25, 0.5, 0.75])
                      Positioned(
                        left: w * t,
                        top: 0,
                        bottom: 0,
                        child: Container(width: 1, color: tick),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Spent ${fmtPrice(spent)} · Planned ${fmtPrice(projected)} / ${fmtPrice(budget)}',
                style: AppText.mono(10, color: captionColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (over)
              Text('+${fmtPrice(projected - budget)} over',
                  style: AppText.mono(10, color: p.rust)),
          ],
        ),
      ],
    );
  }
}
