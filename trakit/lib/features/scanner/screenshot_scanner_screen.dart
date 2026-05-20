import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/expense_category.dart';
import '../../data/models/transaction.dart';
import '../../data/providers/providers.dart';
import '../../data/services/ai_parser_service.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/cards/glass_card.dart';
import '../../widgets/common/aurora_background.dart';

class ScreenshotScannerScreen extends ConsumerStatefulWidget {
  const ScreenshotScannerScreen({super.key});

  @override
  ConsumerState<ScreenshotScannerScreen> createState() =>
      _ScreenshotScannerScreenState();
}

enum _Stage { idle, scanning, parsed, error }

class _ScreenshotScannerScreenState
    extends ConsumerState<ScreenshotScannerScreen> {
  _Stage _stage = _Stage.idle;
  ParsedDraft? _draft;
  String? _rawText;

  Future<void> _simulateUpload() async {
    HapticFeedback.lightImpact();
    setState(() => _stage = _Stage.scanning);
    final ocr = ref.read(ocrServiceProvider);
    final ai = ref.read(aiParserProvider);
    try {
      final raw = await ocr.recognizeFromImagePath('demo://sample');
      final draft = ai.parseOcrText(raw, source: CaptureSource.screenshot);
      setState(() {
        _rawText = raw;
        _draft = draft;
        _stage = _Stage.parsed;
      });
      HapticFeedback.mediumImpact();
    } catch (_) {
      setState(() => _stage = _Stage.error);
    }
  }

  Future<void> _save() async {
    final d = _draft;
    if (d == null) return;
    await ref.read(transactionsProvider.notifier).add(
          ExpenseTxn(
            id: const Uuid().v4(),
            amount: d.amount,
            merchant: d.merchant,
            categoryKey: d.categoryKey,
            date: d.date,
            payment: d.payment,
            source: CaptureSource.screenshot,
            rawSourceText: _rawText,
          ),
        );
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                    Text('Screenshot scanner', style: context.text.titleLarge),
                  ],
                ),
              ),
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    switch (_stage) {
      case _Stage.idle:
        return _IdleView(onPick: _simulateUpload);
      case _Stage.scanning:
        return const _ScanningView();
      case _Stage.parsed:
        return _ParsedView(
          draft: _draft!,
          rawText: _rawText ?? '',
          onSave: _save,
          onRetry: () => setState(() => _stage = _Stage.idle),
        );
      case _Stage.error:
        return _ErrorView(onRetry: () => setState(() => _stage = _Stage.idle));
    }
  }
}

class _IdleView extends StatelessWidget {
  final VoidCallback onPick;
  const _IdleView({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Drop a payment screenshot',
                style: context.text.displaySmall),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Anything from PhonePe, GPay, Paytm, Swiggy, Zomato, Amazon, Uber — TrakIt reads it.',
              style: context.text.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GestureDetector(
              onTap: onPick,
              child: DottedBox(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          gradient: AppGradients.brand,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brand.withValues(alpha: 0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add_photo_alternate_rounded,
                            color: Colors.white, size: 38),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.05, 1.05),
                            duration: 1300.ms,
                          ),
                      const SizedBox(height: 18),
                      Text('Tap to upload',
                          style: context.text.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        'PNG, JPG or your gallery',
                        style: context.text.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: 'Pick from gallery',
            icon: Icons.image_outlined,
            expand: true,
            onPressed: onPick,
          ),
          const SizedBox(height: 12),
          Text(
            'Demo mode: a sample screenshot is auto-generated.',
            style: context.text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class DottedBox extends StatelessWidget {
  final Widget child;
  const DottedBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: context.scheme.primary.withValues(alpha: 0.4),
          width: 1.4,
          style: BorderStyle.solid,
        ),
      ),
      child: child,
    );
  }
}

class _ScanningView extends StatelessWidget {
  const _ScanningView();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: AppGradients.brand,
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // fake screenshot bars
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _bar(60, 10),
                          const SizedBox(height: 8),
                          _bar(110, 8),
                          const SizedBox(height: 8),
                          _bar(80, 8),
                          const Spacer(),
                          _bar(100, 18),
                        ],
                      ),
                    ),
                  ),
                  // sweep line
                  _SweepLine(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Reading screenshot…', style: context.text.headlineSmall),
          const SizedBox(height: 6),
          Text('Extracting amount, merchant and category',
              style: context.text.bodyMedium),
          const SizedBox(height: 20),
          SizedBox(
            width: 180,
            child: LinearProgressIndicator(
              backgroundColor:
                  context.scheme.onSurface.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation(AppColors.brand),
              minHeight: 4,
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(double w, double h) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(4),
        ),
      );
}

class _SweepLine extends StatefulWidget {
  @override
  State<_SweepLine> createState() => _SweepLineState();
}

class _SweepLineState extends State<_SweepLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
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
      builder: (_, __) => Positioned(
        top: 200 * _c.value - 14,
        left: 0,
        right: 0,
        child: Container(
          height: 6,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0.9),
                Colors.white.withValues(alpha: 0),
              ],
            ),
            boxShadow: [
              BoxShadow(color: Colors.white.withValues(alpha: 0.6), blurRadius: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParsedView extends StatelessWidget {
  final ParsedDraft draft;
  final String rawText;
  final VoidCallback onSave;
  final VoidCallback onRetry;
  const _ParsedView({
    required this.draft,
    required this.rawText,
    required this.onSave,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cat = ExpenseCategory.byKey(draft.categoryKey);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 22),
              const SizedBox(width: 6),
              Text('Parsed', style: context.text.titleLarge),
            ],
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: cat.gradient,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child:
                          Text(cat.emoji, style: const TextStyle(fontSize: 28)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(draft.merchant,
                              style: context.text.headlineSmall),
                          Text(
                            '${cat.name} · ${draft.payment.name.toUpperCase()} · ${Dates.human(draft.date)}',
                            style: context.text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Amount', style: context.text.labelMedium),
                    const Spacer(),
                    Text(Money.inr(draft.amount),
                        style: context.text.displaySmall),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.scheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Source text', style: context.text.labelSmall),
                      const SizedBox(height: 6),
                      Text(rawText, style: context.text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  onTap: onRetry,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text('Try another',
                        style: context.text.titleMedium),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GradientButton(
                  label: 'Save',
                  icon: Icons.check_rounded,
                  expand: true,
                  onPressed: onSave,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🥲', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text("Couldn't read that.",
                style: context.text.headlineSmall),
            const SizedBox(height: 6),
            Text('Try a cleaner screenshot — most apps work great.',
                style: context.text.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            GradientButton(label: 'Retry', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
