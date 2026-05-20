import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/extensions/context_ext.dart';

/// Frosted-glass card with subtle stroke and inner highlight.
///
/// We blur the underlying scaffold gradient (12-16px) and stack a 1px
/// inner border + soft inner highlight so the surface reads as glass on
/// any backdrop. On light theme we drop the blur and use a tinted card.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry radius;
  final double blur;
  final Color? tint;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = const BorderRadius.all(Radius.circular(24)),
    this.blur = 16,
    this.tint,
    this.shadows,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final bg = tint ??
        (dark ? Colors.white.withValues(alpha: 0.06) : Colors.white);
    final stroke = border ??
        Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        );

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: stroke,
        boxShadow: shadows ??
            (dark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]),
      ),
      child: child,
    );

    if (dark) {
      content = ClipRRect(
        borderRadius: radius is BorderRadius
            ? radius as BorderRadius
            : BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    }

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius is BorderRadius
              ? radius as BorderRadius
              : BorderRadius.circular(24),
          child: content,
        ),
      );
    }

    return content;
  }
}
