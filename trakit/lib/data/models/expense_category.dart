import 'package:flutter/material.dart';
import '../../core/theme/app_gradients.dart';

enum CategoryKey {
  food,
  groceries,
  entertainment,
  travel,
  shopping,
  bills,
  health,
  subscriptions,
  banking,
  other,
}

class ExpenseCategory {
  final CategoryKey key;
  final String name;
  final IconData icon;
  final String emoji;

  const ExpenseCategory({
    required this.key,
    required this.name,
    required this.icon,
    required this.emoji,
  });

  LinearGradient get gradient =>
      AppGradients.category[name] ??
      const LinearGradient(colors: [Color(0xFF8E7BFF), Color(0xFFB084FF)]);

  static const all = <ExpenseCategory>[
    ExpenseCategory(
      key: CategoryKey.food,
      name: 'Food',
      icon: Icons.ramen_dining_rounded,
      emoji: '🍜',
    ),
    ExpenseCategory(
      key: CategoryKey.groceries,
      name: 'Groceries',
      icon: Icons.local_grocery_store_rounded,
      emoji: '🛒',
    ),
    ExpenseCategory(
      key: CategoryKey.entertainment,
      name: 'Entertainment',
      icon: Icons.movie_filter_rounded,
      emoji: '🎬',
    ),
    ExpenseCategory(
      key: CategoryKey.travel,
      name: 'Travel',
      icon: Icons.flight_takeoff_rounded,
      emoji: '✈️',
    ),
    ExpenseCategory(
      key: CategoryKey.shopping,
      name: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      emoji: '🛍️',
    ),
    ExpenseCategory(
      key: CategoryKey.bills,
      name: 'Bills',
      icon: Icons.receipt_long_rounded,
      emoji: '🧾',
    ),
    ExpenseCategory(
      key: CategoryKey.health,
      name: 'Health',
      icon: Icons.favorite_rounded,
      emoji: '🩺',
    ),
    ExpenseCategory(
      key: CategoryKey.subscriptions,
      name: 'Subscriptions',
      icon: Icons.subscriptions_rounded,
      emoji: '🎟️',
    ),
    ExpenseCategory(
      key: CategoryKey.banking,
      name: 'Banking',
      icon: Icons.account_balance_rounded,
      emoji: '🏦',
    ),
    ExpenseCategory(
      key: CategoryKey.other,
      name: 'Other',
      icon: Icons.bubble_chart_rounded,
      emoji: '✨',
    ),
  ];

  static ExpenseCategory byKey(CategoryKey key) =>
      all.firstWhere((c) => c.key == key, orElse: () => all.last);

  static ExpenseCategory byName(String name) => all.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase(),
        orElse: () => all.last,
      );
}
