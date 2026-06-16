import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/extensions/context_ext.dart';
import '../../core/theme/app_colors.dart';

/// Drifting, blurred color orbs behind primary surfaces.
///
/// We avoid loading shaders or Lottie — a CustomPainter with three radial
/// gradients + a long-running AnimationController is enough to feel alive,
/// and respects `RepaintBoundary` for free.
class AuroraBackground extends StatefulWidget {
  final Widget child;
  const AuroraBackground({super.key, required this.child});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: dark
                  ? [AppColors.bg, AppColors.bgElevated]
                  : [AppColors.bgLight, const Color(0xFFE8DEFF)],
            ),
          ),
        ),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(
              painter: _AuroraPainter(_ctrl.value, dark: dark),
              size: Size.infinite,
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double t;
  final bool dark;
  _AuroraPainter(this.t, {required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final orbs = [
      _Orb(
        color: dark ? AppColors.brand : AppColors.brandDeep,
        baseAlpha: dark ? 0.45 : 0.35,
        speed: 1.0,
        phase: 0,
      ),
      _Orb(
        color: AppColors.accent,
        baseAlpha: dark ? 0.30 : 0.22,
        speed: 0.7,
        phase: 1.2,
      ),
      _Orb(
        color: dark ? const Color(0xFF5AC9EA) : const Color(0xFF7CC8FF),
        baseAlpha: dark ? 0.22 : 0.18,
        speed: 0.85,
        phase: 2.4,
      ),
    ];

    for (final orb in orbs) {
      final tt = (t * orb.speed) + orb.phase;
      final cx = size.width * (0.5 + 0.35 * math.sin(tt * math.pi * 2));
      final cy = size.height * (0.35 + 0.25 * math.cos(tt * math.pi * 2));
      final r = size.shortestSide * 0.7;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            orb.color.withValues(alpha: orb.baseAlpha),
            orb.color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) => old.t != t;
}

class _Orb {
  final Color color;
  final double baseAlpha;
  final double speed;
  final double phase;
  _Orb({
    required this.color,
    required this.baseAlpha,
    required this.speed,
    required this.phase,
  });
}
