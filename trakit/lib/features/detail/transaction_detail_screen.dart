import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction.dart';
import '../../data/providers/providers.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/cards/glass_card.dart';
import '../../widgets/common/aurora_background.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String id;
  const TransactionDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(transactionsProvider).value ?? const [];
    final t = all.where((e) => e.id == id).firstOrNull;
    if (t == null) {
      return Scaffold(
        body: Center(child: Text('Transaction not found', style: context.text.titleLarge)),
      );
    }
    final cat = t.category;

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
                    const Spacer(),
                    IconButton(
                      onPressed: () => _confirmDelete(context, ref, t),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 28),
                      decoration: BoxDecoration(
                        gradient: cat.gradient,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: cat.gradient.colors.last
                                .withValues(alpha: 0.45),
                            blurRadius: 30,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(cat.emoji,
                                  style: const TextStyle(fontSize: 36)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(t.merchant,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        )),
                                    Text('${cat.name} · ${t.payment.name.toUpperCase()}',
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.85),
                                          fontWeight: FontWeight.w600,
                                        )),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            Money.inr(t.amount, paise: true),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            Dates.fullStamp(t.date),
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    GlassCard(
                      child: Column(
                        children: [
                          _Row(label: 'Captured via', value: _sourceLabel(t.source)),
                          const Divider(height: 18),
                          _Row(
                            label: 'Category',
                            value: cat.name,
                            trailing: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                gradient: cat.gradient,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const Divider(height: 18),
                          _Row(
                              label: 'Payment',
                              value: t.payment.name.toUpperCase()),
                          const Divider(height: 18),
                          _Row(
                              label: 'Transaction ID',
                              value: '#${t.id.substring(0, 8).toUpperCase()}'),
                        ],
                      ),
                    ),
                    if (t.rawSourceText != null && t.rawSourceText!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Source text', style: context.text.labelMedium),
                            const SizedBox(height: 8),
                            Text(t.rawSourceText!,
                                style: context.text.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    GradientButton(
                      label: 'Looks right',
                      icon: Icons.check_rounded,
                      expand: true,
                      onPressed: () => context.go('/home'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _sourceLabel(CaptureSource s) => switch (s) {
        CaptureSource.screenshot => 'Screenshot scan',
        CaptureSource.gmail => 'Gmail receipt',
        CaptureSource.manual => 'Quick add',
        CaptureSource.receipt => 'Receipt photo',
        CaptureSource.bankSync => 'Bank sync',
      };

  void _confirmDelete(BuildContext context, WidgetRef ref, ExpenseTxn t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16 + context.padding.bottom,
          top: 16,
        ),
        child: GlassCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_rounded,
                  color: AppColors.danger, size: 36),
              const SizedBox(height: 8),
              Text('Delete this expense?',
                  style: context.text.headlineSmall),
              const SizedBox(height: 8),
              Text('${t.merchant} · ${Money.inr(t.amount)}',
                  style: context.text.bodyMedium),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      onTap: () => Navigator.of(context).pop(),
                      child: Center(child: Text('Cancel',
                          style: context.text.titleMedium)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GradientButton(
                      label: 'Delete',
                      icon: Icons.delete_rounded,
                      expand: true,
                      gradient: const LinearGradient(colors: [
                        AppColors.danger,
                        AppColors.accentDeep
                      ]),
                      onPressed: () async {
                        await ref
                            .read(transactionsProvider.notifier)
                            .delete(t.id);
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        context.go('/timeline');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;
  const _Row({required this.label, required this.value, this.trailing});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: context.text.bodyMedium),
        const Spacer(),
        if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
        Text(value,
            style: context.text.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            )),
      ],
    );
  }
}

