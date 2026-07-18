import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../util/motion.dart';

// Ridge silhouette control points in a 200×44 space (design plan RIDGE).
const _ridge = <Offset>[
  Offset(0, 34), Offset(20, 14), Offset(40, 27), Offset(60, 7),
  Offset(80, 23), Offset(100, 12), Offset(120, 30), Offset(140, 9),
  Offset(160, 25), Offset(180, 16), Offset(200, 30),
];

double _ridgeYAt(double pct) {
  final x = (pct / 100) * 200;
  for (var i = 0; i < _ridge.length - 1; i++) {
    final a = _ridge[i], b = _ridge[i + 1];
    if (x >= a.dx && x <= b.dx) {
      final t = (x - a.dx) / (b.dx - a.dx);
      return a.dy + t * (b.dy - a.dy);
    }
  }
  return _ridge.last.dy;
}

/// A small mountain silhouette that fills with color up to [pct], with a marker
/// at the frontier — the app's "progress bar" (design plan `ProgressRidge`).
class ProgressRidge extends StatelessWidget {
  const ProgressRidge({super.key, required this.pct, this.onDark = false});

  final int pct;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final track = onDark ? Colors.white.withValues(alpha: 0.28) : p.slateSoft;
    final fill = onDark ? const Color(0xFF8FB08C) : p.moss;
    final markerStroke = onDark ? p.ink : Colors.white;
    return SizedBox(
      height: 28,
      width: double.infinity,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: pct.clamp(0, 100).toDouble()),
        duration: Motion.slow,
        curve: Motion.curve,
        builder: (_, value, __) => CustomPaint(
          painter: _RidgePainter(
            pct: value,
            track: track,
            fill: fill,
            markerStroke: markerStroke,
          ),
        ),
      ),
    );
  }
}

class _RidgePainter extends CustomPainter {
  _RidgePainter({
    required this.pct,
    required this.track,
    required this.fill,
    required this.markerStroke,
  });

  final double pct;
  final Color track, fill, markerStroke;

  Path _buildPath(double sx, double sy) {
    final path = Path()..moveTo(_ridge.first.dx * sx, _ridge.first.dy * sy);
    for (var i = 1; i < _ridge.length; i++) {
      path.lineTo(_ridge[i].dx * sx, _ridge[i].dy * sy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 200;
    final sy = size.height / 44;
    final path = _buildPath(sx, sy);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = track,
    );

    final frontierX = (pct / 100) * 200 * sx;
    final frontierY = _ridgeYAt(pct) * sy;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, frontierX, size.height));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = fill,
    );
    canvas.restore();

    // Dashed drop line to the baseline.
    final dash = Paint()
      ..strokeWidth = 1
      ..color = fill.withValues(alpha: 0.6);
    for (var y = frontierY; y < size.height - 2; y += 4) {
      canvas.drawLine(Offset(frontierX, y), Offset(frontierX, y + 2), dash);
    }

    // Frontier marker.
    canvas.drawCircle(Offset(frontierX, frontierY), 3.5, Paint()..color = fill);
    canvas.drawCircle(
      Offset(frontierX, frontierY),
      3.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = markerStroke,
    );
  }

  @override
  bool shouldRepaint(_RidgePainter old) =>
      old.pct != pct || old.fill != fill || old.track != track;
}
