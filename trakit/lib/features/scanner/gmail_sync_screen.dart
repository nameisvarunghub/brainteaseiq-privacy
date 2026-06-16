import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/expense_category.dart';
import '../../data/providers/providers.dart';
import '../../data/services/gmail_sync_service.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/cards/glass_card.dart';
import '../../widgets/common/aurora_background.dart';

class GmailSyncScreen extends ConsumerStatefulWidget {
  const GmailSyncScreen({super.key});
  @override
  ConsumerState<GmailSyncScreen> createState() => _GmailSyncScreenState();
}

class _GmailSyncScreenState extends ConsumerState<GmailSyncScreen> {
  bool _running = false;
  bool _done = false;
  double _progress = 0;
  String _label = 'Tap connect to start';

  Future<void> _connect() async {
    setState(() {
      _running = true;
      _done = false;
    });
    final svc = ref.read(gmailSyncProvider);
    await for (final p in svc.scan()) {
      if (!mounted) return;
      setState(() {
        _progress = p.progress;
        _label = p.label;
        _done = p.done;
      });
    }
    final txns = svc.harvest();
    await ref.read(transactionsProvider.notifier).addMany(txns);
    if (!mounted) return;
    setState(() => _running = false);
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
                    Text('Gmail sync', style: context.text.titleLarge),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Connect your Gmail',
                          style: context.text.displaySmall),
                      const SizedBox(height: 6),
                      Text(
                        'We only read transaction emails. Nothing is sent to a server.',
                        style: context.text.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      _GmailCard(
                        progress: _progress,
                        label: _label,
                        running: _running,
                        done: _done,
                      ),
                      const SizedBox(height: 24),
                      Text('What we scan', style: context.text.titleLarge),
                      const SizedBox(height: 10),
                      ..._reasons.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: context.scheme.primary
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(e.$1,
                                      color: context.scheme.primary, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(e.$2,
                                      style: context.text.bodyLarge),
                                ),
                              ],
                            ),
                          )),
                      const Spacer(),
                      if (_done)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: GlassCard(
                            tint: AppColors.success.withValues(alpha: 0.15),
                            border: Border.all(
                                color:
                                    AppColors.success.withValues(alpha: 0.4)),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: AppColors.success),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Imported recent receipts. Check your Timeline.',
                                    style: context.text.titleMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      GradientButton(
                        label: _done
                            ? 'Back to home'
                            : (_running ? 'Connecting…' : 'Connect Gmail'),
                        icon: _done
                            ? Icons.arrow_forward_rounded
                            : Icons.alternate_email_rounded,
                        expand: true,
                        onPressed: _running
                            ? null
                            : (_done ? () => context.go('/home') : _connect),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _reasons = <(IconData, String)>[
    (Icons.receipt_long_rounded,
        'Razorpay, Cashfree and bank receipt emails.'),
    (Icons.local_dining_rounded, 'Swiggy and Zomato order confirmations.'),
    (Icons.shopping_cart_rounded, 'Amazon, Flipkart, Myntra invoices.'),
    (Icons.subscriptions_rounded, 'Subscription renewals (Netflix, Spotify…).'),
  ];
}

class _GmailCard extends StatelessWidget {
  final double progress;
  final String label;
  final bool running;
  final bool done;

  const _GmailCard({
    required this.progress,
    required this.label,
    required this.running,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFFE6E6), Color(0xFFFFC2C2)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Text('M',
                    style: TextStyle(
                      color: Color(0xFFEA4335),
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    )),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gmail', style: context.text.titleLarge),
                    Text(label, style: context.text.bodySmall),
                  ],
                ),
              ),
              if (done) const Icon(Icons.check_circle_rounded, color: AppColors.success),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: running || done ? progress : 0,
              minHeight: 6,
              backgroundColor:
                  context.scheme.onSurface.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation(AppColors.brand),
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms).scale(
          begin: const Offset(0.96, 0.96),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.easeOut,
        );
  }
}
