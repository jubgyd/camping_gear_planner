import 'package:flutter/material.dart';

/// The two hand-tuned palettes from the design plan. Dark mode is NOT an
/// inverted light mode — surfaces get their own dark values and the moss/rust
/// accents are brightened so they stay legible on dark surfaces.
///
/// Exposed as a [ThemeExtension] so every widget reads `context.palette` and
/// the light/dark switch reflows the whole tree automatically.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bg,
    required this.surface,
    required this.ink,
    required this.inkMuted,
    required this.moss,
    required this.mossSoft,
    required this.rust,
    required this.rustSoft,
    required this.slate,
    required this.slateSoft,
    required this.border,
    required this.headerBg,
    required this.selectedBg,
    required this.onHeaderMuted,
    required this.isDark,
  });

  final Color bg;
  final Color surface;
  final Color ink;
  final Color inkMuted;
  final Color moss;
  final Color mossSoft;
  final Color rust;
  final Color rustSoft;
  final Color slate;
  final Color slateSoft;
  final Color border;
  final Color headerBg;
  final Color selectedBg;

  /// Muted text color that reads well on the dark header band in both themes.
  final Color onHeaderMuted;
  final bool isDark;

  static const light = AppPalette(
    bg: Color(0xFFEDEFE5),
    surface: Color(0xFFFBFBF5),
    ink: Color(0xFF23291D),
    inkMuted: Color(0xFF6B7263),
    moss: Color(0xFF4B6A4A),
    mossSoft: Color(0xFFDCE6D8),
    rust: Color(0xFFBD5B28),
    rustSoft: Color(0xFFF3DFD1),
    slate: Color(0xFFA9A79C),
    slateSoft: Color(0xFFE8E7DD),
    border: Color(0xFFDCDCC9),
    headerBg: Color(0xFF23291D),
    selectedBg: Color(0xFF23291D),
    onHeaderMuted: Color(0xFFC8CCB8),
    isDark: false,
  );

  static const dark = AppPalette(
    bg: Color(0xFF171B15),
    surface: Color(0xFF20251D),
    ink: Color(0xFFEAEBE0),
    inkMuted: Color(0xFF9CA08D),
    moss: Color(0xFF7FB37A),
    mossSoft: Color(0xFF2B3526),
    rust: Color(0xFFE58A55),
    rustSoft: Color(0xFF3A2A20),
    slate: Color(0xFF82866F),
    slateSoft: Color(0xFF2A2E23),
    border: Color(0xFF333827),
    headerBg: Color(0xFF11140F),
    selectedBg: Color(0xFF7FB37A),
    onHeaderMuted: Color(0xFFC8CCB8),
    isDark: true,
  );

  @override
  AppPalette copyWith({bool? isDark}) => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return t < 0.5 ? this : other;
  }
}

/// Ergonomic access: `context.palette.moss`.
extension PaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
