import 'package:flutter/material.dart';
import '../models/expense_category.dart';
import '../models/insight.dart';
import '../models/transaction.dart';

/// Derives narrative insights from raw transactions.
///
/// PRODUCTION: hand the user's last 90 days to a small LLM for free-form
/// narrative + send signals (deltas, anomalies) as context. This rule-based
/// engine is rich enough to feel "smart" with zero network.
class InsightEngine {
  List<Insight> generate(List<ExpenseTxn> txns) {
    if (txns.isEmpty) return _empty();
    final now = DateTime.now();

    final thisWeek = _inLastDays(txns, 7);
    final prevWeek = _inRange(txns, 14, 7);
    final thisMonth = _inLastDays(txns, 30);
    final prevMonth = _inRange(txns, 60, 30);

    final insights = <Insight>[];

    // Food week-over-week
    final foodThis = _sum(thisWeek, CategoryKey.food);
    final foodPrev = _sum(prevWeek, CategoryKey.food);
    if (foodPrev > 0) {
      final delta = ((foodThis - foodPrev) / foodPrev) * 100;
      if (delta.abs() >= 10) {
        insights.add(Insight(
          id: 'food_wow',
          title: delta > 0
              ? 'Food spending is up ${delta.toStringAsFixed(0)}%'
              : 'Food spending dropped ${delta.abs().toStringAsFixed(0)}%',
          body: delta > 0
              ? 'You ordered more this week — mostly late nights. Worth a pause?'
              : 'Nice. You cooked or held back this week — keep the streak.',
          tone: delta > 0 ? InsightTone.warning : InsightTone.celebrate,
          icon: Icons.ramen_dining_rounded,
          deltaText: '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(0)}%',
          deltaUp: delta > 0,
        ));
      }
    }

    // Late-night food (after 9 PM)
    final lateNight = thisWeek.where(
      (t) => t.categoryKey == CategoryKey.food && t.date.hour >= 21,
    ).length;
    if (lateNight >= 3) {
      insights.add(Insight(
        id: 'late_night',
        title: 'Your late-night ordering increased',
        body: '$lateNight food orders after 9 PM this week. Sleep eats budgets too.',
        tone: InsightTone.action,
        icon: Icons.nights_stay_rounded,
      ));
    }

    // Subscriptions total
    final subsMonth = _sum(thisMonth, CategoryKey.subscriptions);
    if (subsMonth > 0) {
      insights.add(Insight(
        id: 'subs_total',
        title: 'Subscriptions total ₹${subsMonth.toStringAsFixed(0)}/month',
        body: 'Across ${_uniqueMerchants(thisMonth, CategoryKey.subscriptions)} services. Cancel any you haven\'t opened in 30 days?',
        tone: InsightTone.info,
        icon: Icons.subscriptions_rounded,
      ));
    }

    // Top category this month
    final byCat = <CategoryKey, double>{};
    for (final t in thisMonth) {
      byCat[t.categoryKey] = (byCat[t.categoryKey] ?? 0) + t.amount;
    }
    if (byCat.isNotEmpty) {
      final top = byCat.entries.reduce((a, b) => a.value >= b.value ? a : b);
      final share = top.value / thisMonth.fold<double>(0, (s, t) => s + t.amount);
      insights.add(Insight(
        id: 'top_cat',
        title:
            '${ExpenseCategory.byKey(top.key).name} is ${(share * 100).toStringAsFixed(0)}% of your month',
        body: 'You spent ₹${top.value.toStringAsFixed(0)} on ${ExpenseCategory.byKey(top.key).name.toLowerCase()} in the last 30 days.',
        tone: InsightTone.info,
        icon: ExpenseCategory.byKey(top.key).icon,
      ));
    }

    // Total month delta
    final totalThis = thisMonth.fold<double>(0, (s, t) => s + t.amount);
    final totalPrev = prevMonth.fold<double>(0, (s, t) => s + t.amount);
    if (totalPrev > 0) {
      final delta = ((totalThis - totalPrev) / totalPrev) * 100;
      insights.add(Insight(
        id: 'month_delta',
        title: delta >= 0
            ? 'You\'re spending ${delta.toStringAsFixed(0)}% more this month'
            : 'You\'re ${delta.abs().toStringAsFixed(0)}% under last month',
        body: 'Last 30 days vs the 30 before.',
        tone: delta >= 0 ? InsightTone.warning : InsightTone.celebrate,
        icon: Icons.timeline_rounded,
        deltaText: '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(0)}%',
        deltaUp: delta >= 0,
      ));
    }

    // Weekend share
    final weekend = thisMonth.where(
      (t) => t.date.weekday == DateTime.saturday ||
          t.date.weekday == DateTime.sunday,
    );
    final weekendSum = weekend.fold<double>(0, (s, t) => s + t.amount);
    if (totalThis > 0 && weekendSum / totalThis > 0.4) {
      insights.add(Insight(
        id: 'weekends',
        title: 'Weekends carry ${((weekendSum / totalThis) * 100).toStringAsFixed(0)}% of your spend',
        body: 'Saturday-Sunday is your most expensive window. Plan one cheap weekend.',
        tone: InsightTone.action,
        icon: Icons.celebration_rounded,
      ));
    }

    // Streak — days without ordering food this week
    final orderDays = thisWeek
        .where((t) => t.categoryKey == CategoryKey.food)
        .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
        .toSet();
    if (orderDays.length <= 2) {
      insights.add(Insight(
        id: 'streak',
        title: 'You skipped food orders ${7 - orderDays.length} days this week',
        body: 'Quiet wins. Keep it going.',
        tone: InsightTone.celebrate,
        icon: Icons.local_fire_department_rounded,
      ));
    }

    // Date stamp (for variety)
    insights.add(Insight(
      id: 'date',
      title: 'Captured ${txns.length} transactions',
      body: 'Last sync ${_relative(now, txns.first.date)}.',
      tone: InsightTone.info,
      icon: Icons.auto_awesome_rounded,
    ));

    return insights;
  }

  List<Insight> _empty() => const [
        Insight(
          id: 'welcome',
          title: 'Drop your first screenshot',
          body: 'Upload a PhonePe or Swiggy screenshot. TrakIt does the rest.',
          tone: InsightTone.info,
          icon: Icons.auto_awesome_rounded,
        ),
      ];

  List<ExpenseTxn> _inLastDays(List<ExpenseTxn> txns, int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return txns.where((t) => t.date.isAfter(cutoff)).toList();
  }

  List<ExpenseTxn> _inRange(List<ExpenseTxn> txns, int olderDays, int newerDays) {
    final older = DateTime.now().subtract(Duration(days: olderDays));
    final newer = DateTime.now().subtract(Duration(days: newerDays));
    return txns
        .where((t) => t.date.isAfter(older) && t.date.isBefore(newer))
        .toList();
  }

  double _sum(List<ExpenseTxn> txns, CategoryKey k) =>
      txns.where((t) => t.categoryKey == k).fold(0, (s, t) => s + t.amount);

  int _uniqueMerchants(List<ExpenseTxn> txns, CategoryKey k) =>
      txns.where((t) => t.categoryKey == k).map((t) => t.merchant).toSet().length;

  String _relative(DateTime now, DateTime then) {
    final diff = now.difference(then);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
