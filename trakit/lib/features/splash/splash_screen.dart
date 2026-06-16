import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_gradients.dart';
import '../../data/providers/providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      final hasOnboarded = ref.read(storageProvider).hasOnboarded;
      context.go(hasOnboarded ? '/home' : '/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.hero),
        child: SafeArea(
          child: Stack(
            children: [
              // background drifting glow
              const Positioned.fill(child: _GlowField()),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _Logo()
                        .animate()
                        .scale(
                            begin: const Offset(0.6, 0.6),
                            end: const Offset(1, 1),
                            duration: 700.ms,
                            curve: Curves.easeOutBack)
                        .fade(duration: 500.ms),
                    const SizedBox(height: 24),
                    Text(
                      'TrakIt',
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(color: Colors.white),
                    )
                        .animate()
                        .fade(delay: 400.ms, duration: 600.ms)
                        .moveY(begin: 12, end: 0, duration: 600.ms),
                    const SizedBox(height: 8),
                    Text(
                      'Your AI money companion',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                    )
                        .animate()
                        .fade(delay: 700.ms, duration: 600.ms)
                        .moveY(begin: 10, end: 0, duration: 600.ms),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.8)),
                    ).animate().fade(delay: 900.ms, duration: 400.ms),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withValues(alpha: 0.16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Center(
        child: Text('₹', style: TextStyle(
          fontSize: 52,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1.0,
        )),
      ),
    );
  }
}

class _GlowField extends StatefulWidget {
  const _GlowField();
  @override
  State<_GlowField> createState() => _GlowFieldState();
}

class _GlowFieldState extends State<_GlowField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Stack(
          children: [
            Positioned(
              top: 80 + (_c.value * 40),
              left: -60,
              child: _blob(160, Colors.white.withValues(alpha: 0.16)),
            ),
            Positioned(
              bottom: 60 + (_c.value * 20),
              right: -40,
              child: _blob(220, Colors.white.withValues(alpha: 0.1)),
            ),
          ],
        );
      },
    );
  }

  Widget _blob(double s, Color c) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c,
          boxShadow: [
            BoxShadow(color: c, blurRadius: 80, spreadRadius: 30),
          ],
        ),
      );
}
