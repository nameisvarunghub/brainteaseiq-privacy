import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/insight.dart';
import '../../data/providers/providers.dart';
import '../../widgets/cards/glass_card.dart';
import '../../widgets/charts/category_donut.dart';
import '../../widgets/common/aurora_background.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(insightsProvider);
    final byCat = ref.watch(monthByCategoryProvider);
    final monthSpend = ref.watch(monthSpendProvider);

    return AuroraBackground(
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded,
                            color: AppColors.brand),
                        const SizedBox(width: 8),
                        Text('AI Insights', style: context.text.displaySmall),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'TrakIt narrates your last 30 days.',
                      style: context.text.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            if (byCat.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: GlassCard(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                    child: Column(
                      children: [
                        Text(
                          'Where your money went',
                          style: context.text.labelMedium,
                        ),
                        const SizedBox(height: 12),
                        CategoryDonut(byCategory: byCat),
                        const SizedBox(height: 12),
                        Text(Money.inr(monthSpend),
                            style: context.text.headlineLarge),
                        const SizedBox(height: 4),
                        Text(Dates.monthYear(DateTime.now()),
                            style: context.text.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Text('Notes from your money',
                    style: context.text.headlineSmall),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverList.separated(
                itemCount: insights.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _InsightTile(insight: insights[i])
                    .animate()
                    .fade(delay: (i * 70).ms, duration: 350.ms)
                    .moveY(
                      begin: 18,
                      end: 0,
                      delay: (i * 70).ms,
                      duration: 350.ms,
                      curve: Curves.easeOut,
                    ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: 140 + context.padding.bottom),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final Insight insight;
  const _InsightTile({required this.insight});

  @override
  Widget build(BuildContext context) {
    final (gradient, accent) = switch (insight.tone) {
      InsightTone.warning => (AppGradients.sunrise, AppColors.danger),
      InsightTone.celebrate => (
          const LinearGradient(colors: [Color(0xFF7BE495), Color(0xFF36C998)]),
          AppColors.success,
        ),
      InsightTone.info => (AppGradients.brand, AppColors.brand),
      InsightTone.action => (
          const LinearGradient(colors: [Color(0xFF94EAFF), Color(0xFF5AC9EA)]),
          AppColors.info,
        ),
    };

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(insight.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(insight.title,
                          style: context.text.titleMedium),
                    ),
                    if (insight.deltaText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (insight.deltaUp
                                  ? AppColors.danger
                                  : AppColors.success)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          insight.deltaText!,
                          style: TextStyle(
                            color: insight.deltaUp
                                ? AppColors.danger
                                : AppColors.success,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(insight.body, style: context.text.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
