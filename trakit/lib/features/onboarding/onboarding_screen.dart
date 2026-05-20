import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../data/providers/providers.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/cards/glass_card.dart';
import '../../widgets/common/aurora_background.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pc = PageController();
  int _i = 0;

  static const _pages = <_Page>[
    _Page(
      emoji: '📸',
      title: 'Forget typing.\nDrop a screenshot.',
      body:
          'PhonePe, GPay, Swiggy, Amazon — TrakIt reads them all and logs the expense in seconds.',
      gradient: AppGradients.brand,
    ),
    _Page(
      emoji: '🧠',
      title: 'AI that gets your money.',
      body:
          'Categories, merchants, payment modes — handled automatically. You barely lift a finger.',
      gradient: AppGradients.sunrise,
    ),
    _Page(
      emoji: '✨',
      title: 'See where it really goes.',
      body:
          'Beautiful insights, weekly nudges, late-night ordering streaks. Your money, finally legible.',
      gradient: AppGradients.hero,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _DotsBar(count: _pages.length, index: _i),
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        'Skip',
                        style: context.text.titleSmall?.copyWith(
                          color: context.scheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pc,
                  itemCount: _pages.length,
                  onPageChanged: (v) => setState(() => _i = v),
                  itemBuilder: (_, i) => _OnboardPage(page: _pages[i], index: i),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: GradientButton(
                  expand: true,
                  label: _i == _pages.length - 1 ? 'Get started' : 'Continue',
                  icon: _i == _pages.length - 1
                      ? Icons.arrow_forward_rounded
                      : Icons.arrow_forward_ios_rounded,
                  gradient: _pages[_i].gradient,
                  onPressed: () {
                    if (_i == _pages.length - 1) {
                      _finish();
                    } else {
                      _pc.nextPage(
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _finish() async {
    await ref.read(storageProvider).setOnboarded(true);
    if (!mounted) return;
    context.go('/home');
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }
}

class _Page {
  final String emoji;
  final String title;
  final String body;
  final LinearGradient gradient;
  const _Page({
    required this.emoji,
    required this.title,
    required this.body,
    required this.gradient,
  });
}

class _OnboardPage extends StatelessWidget {
  final _Page page;
  final int index;
  const _OnboardPage({required this.page, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: page.gradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: page.gradient.colors.last
                                .withValues(alpha: 0.45),
                            blurRadius: 40,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(page.emoji, style: const TextStyle(fontSize: 56)),
                    )
                        .animate(key: ValueKey('emoji-$index'))
                        .scale(
                          begin: const Offset(0.7, 0.7),
                          end: const Offset(1, 1),
                          duration: 500.ms,
                          curve: Curves.easeOutBack,
                        )
                        .fade(duration: 400.ms),
                    const SizedBox(height: 28),
                    Text(
                      page.title,
                      textAlign: TextAlign.center,
                      style: context.text.displaySmall,
                    )
                        .animate(key: ValueKey('title-$index'))
                        .fade(delay: 150.ms, duration: 500.ms)
                        .moveY(begin: 14, end: 0, duration: 500.ms),
                    const SizedBox(height: 12),
                    Text(
                      page.body,
                      textAlign: TextAlign.center,
                      style: context.text.bodyLarge,
                    )
                        .animate(key: ValueKey('body-$index'))
                        .fade(delay: 280.ms, duration: 500.ms)
                        .moveY(begin: 10, end: 0, duration: 500.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotsBar extends StatelessWidget {
  final int count;
  final int index;
  const _DotsBar({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(right: 6),
          width: active ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? context.scheme.primary
                : AppColors.textMuted.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}
