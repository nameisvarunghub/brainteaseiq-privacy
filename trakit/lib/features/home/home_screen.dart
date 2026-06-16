import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/expense_category.dart';
import '../../data/models/insight.dart';
import '../../data/providers/providers.dart';
import '../../widgets/animations/animated_counter.dart';
import '../../widgets/cards/glass_card.dart';
import '../../widgets/charts/spend_sparkline.dart';
import '../../widgets/common/aurora_background.dart';
import '../../widgets/common/category_pill.dart';
import '../../widgets/common/transaction_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthSpend = ref.watch(monthSpendProvider);
    final byCat = ref.watch(monthByCategoryProvider);
    final last7 = ref.watch(last7DaysProvider);
    final txns = ref.watch(transactionsProvider).value ?? const [];
    final insights = ref.watch(insightsProvider);
    final recents = txns.take(5).toList();

    return AuroraBackground(
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              sliver: SliverToBoxAdapter(
                child: _Greeting(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              sliver: SliverToBoxAdapter(
                child: _HeroCard(monthSpend: monthSpend, last7: last7),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Categories',
                  trailing: 'This month',
                ),
              ),
            ),
            SliverToBoxAdapter(child: _CategoryStrip(byCat: byCat)),
            if (insights.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'AI Insights',
                    trailing: 'See all',
                    onTrailing: () => context.go('/insights'),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: _InsightCard(insight: insights.first),
                ),
              ),
            ],
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Recent',
                  trailing: 'Timeline',
                  onTrailing: () => context.go('/timeline'),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverList.separated(
                itemCount: recents.length,
                separatorBuilder: (_, __) => const Divider(height: 6),
                itemBuilder: (_, i) => TransactionTile(
                  txn: recents[i],
                  onTap: () => context.push('/transaction/${recents[i].id}'),
                ).animate().fade(delay: (i * 40).ms, duration: 300.ms).moveY(
                      begin: 12,
                      end: 0,
                      delay: (i * 40).ms,
                      duration: 300.ms,
                      curve: Curves.easeOut,
                    ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: 120 + context.padding.bottom),
            ),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final hello = hour < 12
        ? 'Good morning'
        : (hour < 17 ? 'Good afternoon' : 'Good evening');
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(hello, style: context.text.bodyMedium),
              const SizedBox(height: 2),
              Text('Here\'s your spend', style: context.text.headlineMedium),
            ],
          ),
        ),
        _AvatarBadge(initial: 'V'),
      ],
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  final String initial;
  const _AvatarBadge({required this.initial});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: AppGradients.sunrise,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.accentDeep.withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Colors.white,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final double monthSpend;
  final List<double> last7;
  const _HeroCard({required this.monthSpend, required this.last7});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                'Spend · ${Dates.monthYear(DateTime.now())}',
                style: context.text.labelMedium,
              ),
              const Spacer(),
              _trendChip(context),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedCurrency(value: monthSpend, size: 52),
          const SizedBox(height: 10),
          Text(
            _subline(monthSpend),
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: 4),
          SpendSparkline(
            values: last7,
            line: AppColors.brand,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('7 days ago', style: context.text.bodySmall),
              Text('Today', style: context.text.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  String _subline(double v) {
    if (v == 0) return 'Drop your first receipt — TrakIt does the rest.';
    if (v < 5000) return 'A calm month so far. Keep the streak.';
    if (v < 25000) return 'Steady pace. Worth a quick look at categories.';
    return 'Big spending month — let\'s see where it\'s going.';
  }

  Widget _trendChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.trending_down_rounded,
              size: 12, color: AppColors.success),
          SizedBox(width: 4),
          Text(
            '−8% vs last week',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  final Map<String, double> byCat;
  const _CategoryStrip({required this.byCat});

  @override
  Widget build(BuildContext context) {
    final cats = ExpenseCategory.all
        .where((c) => c.key != CategoryKey.other)
        .toList();

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final c = cats[i];
          final amt = byCat[c.name] ?? 0;
          return Center(
            child: CategoryPill(category: c, amount: amt),
          ).animate().fade(delay: (i * 50).ms, duration: 350.ms).scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1, 1),
                delay: (i * 50).ms,
                duration: 350.ms,
                curve: Curves.easeOutBack,
              );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String trailing;
  final VoidCallback? onTrailing;
  const _SectionHeader({
    required this.title,
    required this.trailing,
    this.onTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: context.text.headlineSmall)),
        InkWell(
          onTap: onTrailing,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(trailing,
                style: context.text.labelMedium?.copyWith(
                  color: context.scheme.primary,
                )),
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final Insight insight;
  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => context.go('/insights'),
      tint: context.isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppGradients.sunrise,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentDeep.withValues(alpha: 0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(insight.icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(insight.title, style: context.text.titleMedium),
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
