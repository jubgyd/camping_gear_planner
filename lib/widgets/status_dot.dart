import 'package:flutter/material.dart';

import '../models/item_status.dart';
import '../theme/app_palette.dart';
import '../util/motion.dart';

/// The tap-to-cycle status glyph (design plan `StatusIcon`):
/// moss check = owned, rust bag = need to buy, outlined dot = not needed.
class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.status, this.onTap});

  final ItemStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget dot;
    switch (status) {
      case ItemStatus.owned:
        dot = Container(
          key: const ValueKey('owned'),
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: p.moss, shape: BoxShape.circle),
          child: const Icon(Icons.check, size: 14, color: Colors.white),
        );
      case ItemStatus.needToBuy:
        dot = Container(
          key: const ValueKey('need'),
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: p.rust, shape: BoxShape.circle),
          child: const Icon(Icons.shopping_bag, size: 12, color: Colors.white),
        );
      case ItemStatus.notNeeded:
        dot = Container(
          key: const ValueKey('na'),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: p.slate, width: 1.5),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: p.slate, shape: BoxShape.circle),
            ),
          ),
        );
    }
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
        child: AnimatedSwitcher(
          duration: Motion.fast,
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: Tween<double>(begin: 0.6, end: 1).animate(anim),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: dot,
        ),
      ),
    );
  }
}
