import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';

class AnimatedCurrency extends StatelessWidget {
  final double value;
  final Duration duration;
  final double size;
  final Color? color;
  final String prefix;
  final int decimals;

  const AnimatedCurrency({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 900),
    this.size = 56,
    this.color,
    this.prefix = '₹',
    this.decimals = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final intPart = v.truncate();
        final fracPart = (v - intPart).abs();
        final s = _format(intPart);
        final f = decimals > 0
            ? '.${fracPart.toStringAsFixed(decimals).split('.').last}'
            : '';
        return RichText(
          text: TextSpan(
            style: AppTextStyles.currency(context, size: size, color: color),
            children: [
              TextSpan(
                text: prefix,
                style: AppTextStyles.currency(
                  context,
                  size: size * 0.55,
                  color: (color ?? Theme.of(context).colorScheme.onSurface)
                      .withValues(alpha: 0.8),
                ),
              ),
              const TextSpan(text: ' '),
              TextSpan(text: s),
              if (decimals > 0) TextSpan(text: f),
            ],
          ),
        );
      },
    );
  }

  String _format(int n) {
    final s = n.toString();
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    final rest = s.substring(0, s.length - 3);
    final buf = StringBuffer();
    for (int i = 0; i < rest.length; i++) {
      buf.write(rest[i]);
      final remaining = rest.length - i - 1;
      if (remaining > 0 && remaining.isEven) buf.write(',');
    }
    return '${buf.toString()},$last3';
  }
}
