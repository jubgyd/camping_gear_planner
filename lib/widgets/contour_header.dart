import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// Subtle topographic contour-line texture, used in the dark header bands only
/// (design plan `ContourTexture`). Painted with cubic-bezier ridgelines that
/// fade toward the bottom.
class _ContourPainter extends CustomPainter {
  _ContourPainter(this.color, this.baseOpacity);
  final Color color;
  final double baseOpacity;

  static const _ys = <double>[8, 22, 36, 50, 66, 84, 104];

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 400;
    final sy = size.height / 140;
    Offset p(double x, double y) => Offset(x * sx, y * sy);

    for (var i = 0; i < _ys.length; i++) {
      final y = _ys[i];
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color.withValues(
            alpha: (baseOpacity - i * 0.012).clamp(0.0, 1.0).toDouble());
      final path = Path()
        ..moveTo(-20 * sx, y * sy)
        ..cubicTo(p(60, y - 14).dx, p(60, y - 14).dy, p(140, y + 16).dx,
            p(140, y + 16).dy, p(220, y - 6).dx, p(220, y - 6).dy)
        // smooth continuation (reflected control point of the previous curve)
        ..cubicTo(p(300, y - 28).dx, p(300, y - 28).dy, p(380, y + 10).dx,
            p(380, y + 10).dy, p(440, y).dx, p(440, y).dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_ContourPainter old) =>
      old.color != color || old.baseOpacity != baseOpacity;
}

/// A dark header band with the contour texture behind arbitrary [child] content.
class ContourHeader extends StatelessWidget {
  const ContourHeader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 20, 24, 20),
    this.opacity = 0.16,
  });

  final Widget child;
  final EdgeInsets padding;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRect(
      child: Container(
        width: double.infinity,
        color: p.headerBg,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _ContourPainter(p.onHeader, opacity)),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}
