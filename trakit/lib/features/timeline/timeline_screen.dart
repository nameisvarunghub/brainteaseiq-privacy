import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/expense_category.dart';
import '../../data/models/transaction.dart';
import '../../data/providers/providers.dart';
import '../../widgets/cards/glass_card.dart';
import '../../widgets/common/aurora_background.dart';
import '../../widgets/common/category_pill.dart';
import '../../widgets/common/transaction_tile.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  CategoryKey? _filter;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(transactionsProvider).value ?? const [];
    final filtered = all.where((t) {
      if (_filter != null && t.categoryKey != _filter) return false;
      if (_query.isEmpty) return true;
      return t.merchant.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    final grouped = groupBy<ExpenseTxn, String>(
      filtered,
      (t) => Dates.human(t.date),
    );

    return AuroraBackground(
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Timeline', style: context.text.displaySmall),
                    ),
                    GlassCard(
                      padding: const EdgeInsets.all(10),
                      onTap: () => setState(() {
                        _filter = null;
                        _query = '';
                      }),
                      child: const Icon(Icons.filter_alt_outlined, size: 20),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              sliver: SliverToBoxAdapter(
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  radius: const BorderRadius.all(Radius.circular(18)),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    style: context.text.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Search merchant, e.g. Swiggy',
                      hintStyle: context.text.bodyMedium,
                      border: InputBorder.none,
                      icon: const Icon(Icons.search_rounded),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: 60,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: ExpenseCategory.all.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final c = ExpenseCategory.all[i];
                      return Center(
                        child: CategoryPill(
                          category: c,
                          compact: true,
                          selected: _filter == c.key,
                          onTap: () => setState(() {
                            _filter = _filter == c.key ? null : c.key;
                          }),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyTimeline(onClear: () {
                  setState(() {
                    _filter = null;
                    _query = '';
                  });
                }),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverList.builder(
                  itemCount: grouped.length,
                  itemBuilder: (_, i) {
                    final day = grouped.keys.elementAt(i);
                    final items = grouped[day]!;
                    final total = items.fold<double>(0, (s, t) => s + t.amount);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            children: [
                              Text(day, style: context.text.titleLarge),
                              const Spacer(),
                              Text(
                                Money.inr(total),
                                style: context.text.titleMedium?.copyWith(
                                  color: context.scheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        GlassCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          child: Column(
                            children: [
                              for (int k = 0; k < items.length; k++) ...[
                                if (k > 0) const Divider(height: 6),
                                TransactionTile(
                                  txn: items[k],
                                  onTap: () => context
                                      .push('/transaction/${items[k].id}'),
                                ),
                              ],
                            ],
                          ),
                        )
                            .animate()
                            .fade(delay: (i * 60).ms, duration: 360.ms)
                            .moveY(
                              begin: 18,
                              end: 0,
                              delay: (i * 60).ms,
                              duration: 360.ms,
                              curve: Curves.easeOut,
                            ),
                      ],
                    );
                  },
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

class _EmptyTimeline extends StatelessWidget {
  final VoidCallback onClear;
  const _EmptyTimeline({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🪶', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text('Nothing matches your filter',
                style: context.text.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Try clearing the search or pick a different category.',
              style: context.text.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: onClear, child: const Text('Clear filters')),
          ],
        ),
      ),
    );
  }
}
