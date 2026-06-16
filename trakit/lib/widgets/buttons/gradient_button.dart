import 'package:flutter/material.dart';
import '../../core/theme/app_gradients.dart';

class GradientButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final LinearGradient gradient;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool expand;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.gradient = AppGradients.brand,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
    this.radius = 22,
    this.expand = false,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
    lowerBound: 0,
    upperBound: 0.04,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => _ctrl.forward(),
      onTapCancel: disabled ? null : () => _ctrl.reverse(),
      onTapUp: disabled ? null : (_) => _ctrl.reverse(),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Transform.scale(
          scale: 1 - _ctrl.value,
          child: Container(
            padding: widget.padding,
            width: widget.expand ? double.infinity : null,
            decoration: BoxDecoration(
              gradient: disabled
                  ? LinearGradient(colors: [
                      widget.gradient.colors.first.withValues(alpha: 0.4),
                      widget.gradient.colors.last.withValues(alpha: 0.4),
                    ])
                  : widget.gradient,
              borderRadius: BorderRadius.circular(widget.radius),
              boxShadow: disabled
                  ? null
                  : [
                      BoxShadow(
                        color: widget.gradient.colors.last
                            .withValues(alpha: 0.35),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                ],
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
