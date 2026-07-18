import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../util/motion.dart';
import 'app_palette.dart';

/// Builds the light/dark [ThemeData], attaching [AppPalette] as a theme
/// extension. Most widgets style themselves explicitly from `context.palette`;
/// this sets sensible global defaults (scaffold bg, default text font, selection).
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(AppPalette.light, Brightness.light);
  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      extensions: [p],
      colorScheme: ColorScheme.fromSeed(
        seedColor: p.moss,
        brightness: brightness,
      ).copyWith(
        surface: p.surface,
        primary: p.moss,
        secondary: p.rust,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: p.ink,
        displayColor: p.ink,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.rust,
        selectionColor: p.mossSoft,
        selectionHandleColor: p.rust,
      ),
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SmoothPageTransitionsBuilder(),
          TargetPlatform.iOS: SmoothPageTransitionsBuilder(),
          TargetPlatform.linux: SmoothPageTransitionsBuilder(),
          TargetPlatform.macOS: SmoothPageTransitionsBuilder(),
          TargetPlatform.windows: SmoothPageTransitionsBuilder(),
        },
      ),
    );
  }
}
