import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_text.dart';
import '../util/motion.dart';

/// Wide-screen breakpoint: at/above this the shell uses a side rail and content
/// is centered with a max width; below it, a bottom nav and full-width content.
const double kWideBreakpoint = 820;

bool isWide(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kWideBreakpoint;

/// Centers content and caps its width so it reads well on wide desktop windows.
class ContentColumn extends StatelessWidget {
  const ContentColumn({super.key, required this.child, this.maxWidth = 720});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

/// The rounded surface card used everywhere for content grouping. Carries a
/// soft shadow for depth; interactive cards (with [onTap]) lift on hover and
/// dip slightly on press for a smooth, modern response.
class SurfaceCard extends StatefulWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.radius = 20,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double radius;
  final bool clip;

  @override
  State<SurfaceCard> createState() => _SurfaceCardState();
}

class _SurfaceCardState extends State<SurfaceCard> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final interactive = widget.onTap != null;
    final radius = BorderRadius.circular(widget.radius);
    final lifted = _hover && interactive;

    final shadowBase = p.isDark ? 0.35 : 0.05;
    final shadowLift = p.isDark ? 0.5 : 0.10;
    final shadow = [
      BoxShadow(
        color: Colors.black.withValues(alpha: lifted ? shadowLift : shadowBase),
        blurRadius: lifted ? 24 : 12,
        offset: Offset(0, lifted ? 10 : 4),
      ),
    ];

    Widget content = widget.padding == null
        ? widget.child
        : Padding(padding: widget.padding!, child: widget.child);

    if (interactive) {
      content = InkWell(
        borderRadius: radius,
        onTap: widget.onTap,
        onHighlightChanged: (v) => setState(() => _pressed = v),
        splashColor: p.mossSoft.withValues(alpha: 0.4),
        highlightColor: Colors.transparent,
        child: content,
      );
    }

    Widget card = AnimatedContainer(
      duration: Motion.base,
      curve: Motion.curve,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: radius,
        border: Border.all(color: lifted ? p.moss.withValues(alpha: 0.5) : p.border),
        boxShadow: shadow,
      ),
      clipBehavior:
          widget.clip || interactive ? Clip.antiAlias : Clip.none,
      child: content,
    );

    // Subtle upward lift + press dip.
    card = AnimatedSlide(
      duration: Motion.base,
      curve: Motion.curve,
      offset: Offset(0, lifted ? -0.008 : 0),
      child: AnimatedScale(
        duration: Motion.fast,
        curve: Motion.curve,
        scale: _pressed ? 0.985 : 1,
        child: card,
      ),
    );

    if (!interactive) return card;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: card,
    );
  }
}

/// Uppercase mono section label used above form fields and groups.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: AppText.sectionLabel(context.palette.inkMuted),
      );
}

/// Small rounded pill used for countdown/archived/style tags.
class TagPill extends StatelessWidget {
  const TagPill({
    super.key,
    required this.text,
    required this.bg,
    required this.fg,
    this.mono = true,
  });

  final String text;
  final Color bg, fg;
  final bool mono;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(text,
            style: mono
                ? AppText.mono(10, color: fg)
                : AppText.body(10, color: fg)),
      );
}
