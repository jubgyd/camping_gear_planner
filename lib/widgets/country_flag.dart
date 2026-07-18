import 'package:flutter/material.dart';

/// Draws a country's flag with a CustomPainter instead of relying on emoji.
///
/// Windows desktop has no regional-indicator (flag) emoji glyphs, so
/// `Text('🇩🇪')` renders as blank boxes there. Painting the flags keeps them
/// visible on every platform and needs no assets or network. The set matches
/// [Country.all] (mostly stripe flags plus Nordic/Swiss crosses).
class CountryFlag extends StatelessWidget {
  const CountryFlag(this.code, {super.key, this.width = 34, this.height = 22});

  final String code;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: CustomPaint(
        size: Size(width, height),
        painter: _FlagPainter(code),
        // A hairline border keeps white/light flags legible on light surfaces.
        foregroundPainter: _BorderPainter(),
      ),
    );
  }
}

class _BorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.black.withValues(alpha: 0.15);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Offset.zero & size, const Radius.circular(3)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_BorderPainter oldDelegate) => false;
}

class _FlagPainter extends CustomPainter {
  _FlagPainter(this.code);
  final String code;

  static const _white = Colors.white;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()..style = PaintingStyle.fill;
    void fill(Rect r, Color c) {
      p.color = c;
      canvas.drawRect(r, p);
    }

    void horizontal3(Color a, Color b, Color c) {
      fill(Rect.fromLTWH(0, 0, w, h / 3), a);
      fill(Rect.fromLTWH(0, h / 3, w, h / 3), b);
      fill(Rect.fromLTWH(0, 2 * h / 3, w, h - 2 * h / 3), c);
    }

    void vertical3(Color a, Color b, Color c) {
      fill(Rect.fromLTWH(0, 0, w / 3, h), a);
      fill(Rect.fromLTWH(w / 3, 0, w / 3, h), b);
      fill(Rect.fromLTWH(2 * w / 3, 0, w - 2 * w / 3, h), c);
    }

    switch (code) {
      case 'DE':
        horizontal3(const Color(0xFF000000), const Color(0xFFDD0000),
            const Color(0xFFFFCE00));
        break;
      case 'AT':
        horizontal3(const Color(0xFFED2939), _white, const Color(0xFFED2939));
        break;
      case 'HR':
        horizontal3(const Color(0xFFFF0000), _white, const Color(0xFF171796));
        // Approximate the central shield: a small white square with a red core.
        final sq = Rect.fromCenter(
            center: Offset(w / 2, h / 2), width: h * 0.42, height: h * 0.5);
        fill(sq, _white);
        fill(sq.deflate(h * 0.06), const Color(0xFFFF0000));
        break;
      case 'IT':
        vertical3(const Color(0xFF009246), _white, const Color(0xFFCE2B37));
        break;
      case 'FR':
        vertical3(const Color(0xFF0055A4), _white, const Color(0xFFEF4135));
        break;
      case 'SE':
        _nordic(canvas, size, const Color(0xFF006AA7), const Color(0xFFFECC00),
            null);
        break;
      case 'FI':
        _nordic(canvas, size, _white, const Color(0xFF003580), null);
        break;
      case 'NO':
        _nordic(canvas, size, const Color(0xFFBA0C2F), _white,
            const Color(0xFF00205B));
        break;
      case 'IS':
        _nordic(canvas, size, const Color(0xFF02529C), _white,
            const Color(0xFFDC1E35));
        break;
      case 'CH':
        fill(Offset.zero & size, const Color(0xFFD52B1E));
        p.color = _white;
        final t = h * 0.20; // arm thickness
        final len = h * 0.60; // arm length (equal-armed cross)
        canvas.drawRect(
            Rect.fromCenter(
                center: Offset(w / 2, h / 2), width: t, height: len),
            p);
        canvas.drawRect(
            Rect.fromCenter(
                center: Offset(w / 2, h / 2), width: len, height: t),
            p);
        break;
      default:
        fill(Offset.zero & size, const Color(0xFFCCCCCC));
    }
  }

  /// Nordic cross: [field] background, an [cross] cross offset toward the hoist,
  /// optionally with a thinner [inner] cross on top (Norway, Iceland).
  void _nordic(Canvas canvas, Size size, Color field, Color cross,
      Color? inner) {
    final w = size.width, h = size.height;
    final p = Paint()..style = PaintingStyle.fill;
    p.color = field;
    canvas.drawRect(Offset.zero & size, p);

    final vx = w * 0.36; // vertical bar centre, shifted to the hoist
    final cy = h * 0.5;
    final outer = h * 0.30;
    final innerT = h * 0.14;

    p.color = cross;
    canvas.drawRect(
        Rect.fromCenter(center: Offset(vx, cy), width: outer, height: h), p);
    canvas.drawRect(Rect.fromLTWH(0, cy - outer / 2, w, outer), p);

    if (inner != null) {
      p.color = inner;
      canvas.drawRect(
          Rect.fromCenter(center: Offset(vx, cy), width: innerT, height: h), p);
      canvas.drawRect(Rect.fromLTWH(0, cy - innerT / 2, w, innerT), p);
    }
  }

  @override
  bool shouldRepaint(_FlagPainter oldDelegate) => oldDelegate.code != code;
}
