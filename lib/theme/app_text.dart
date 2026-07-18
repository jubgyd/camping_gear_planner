import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central font helpers matching the design plan:
/// - display: Fraunces (serif) for names/headlines
/// - body:    Inter for regular UI text
/// - mono:    JetBrains Mono for numbers, weights, prices, labels
class AppText {
  const AppText._();

  static TextStyle display(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w600,
    double? height,
  }) =>
      GoogleFonts.fraunces(
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
      );

  static TextStyle body(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w400,
    double? height,
    TextDecoration? decoration,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
        decoration: decoration,
      );

  static TextStyle mono(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w400,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: letterSpacing,
      );

  /// Uppercase, wide-tracked mono label used for section headers in forms.
  static TextStyle sectionLabel(Color color) =>
      mono(11, color: color, weight: FontWeight.w500, letterSpacing: 1.5);
}
