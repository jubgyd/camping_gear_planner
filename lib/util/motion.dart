import 'package:flutter/material.dart';

/// Shared motion tokens so timing/curves are consistent and easy to tune.
class Motion {
  const Motion._();

  static const fast = Duration(milliseconds: 140);
  static const base = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 340);

  /// Standard easing for UI motion — decelerate into place.
  static const curve = Curves.easeOutCubic;
  static const emphasized = Curves.easeOutQuart;
}

/// A modern page transition: a gentle fade combined with a small upward slide
/// and scale settle. Applied app-wide via [PageTransitionsTheme], so every
/// navigation feels smooth without per-route wiring.
class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Motion.curve,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
          child: child,
        ),
      ),
    );
  }
}
