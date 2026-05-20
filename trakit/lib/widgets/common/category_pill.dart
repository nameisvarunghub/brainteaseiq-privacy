import 'package:flutter/material.dart';
import '../../data/models/expense_category.dart';

class CategoryPill extends StatelessWidget {
  final ExpenseCategory category;
  final double amount;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact;

  const CategoryPill({
    super.key,
    required this.category,
    this.amount = 0,
    this.selected = false,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 18,
          vertical: compact ? 10 : 14,
        ),
        decoration: BoxDecoration(
          gradient: category.gradient,
          borderRadius: BorderRadius.circular(compact ? 18 : 22),
          boxShadow: [
            BoxShadow(
              color: category.gradient.colors.last
                  .withValues(alpha: selected ? 0.45 : 0.25),
              blurRadius: selected ? 24 : 18,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: selected ? 0.55 : 0.18),
            width: selected ? 1.4 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.emoji,
                style: TextStyle(fontSize: compact ? 16 : 20)),
            SizedBox(width: compact ? 8 : 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 12 : 14,
                    letterSpacing: 0.1,
                  ),
                ),
                if (!compact && amount > 0)
                  Text(
                    '₹${_short(amount)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _short(double n) {
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toStringAsFixed(0);
  }
}
