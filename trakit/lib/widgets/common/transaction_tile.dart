import 'package:flutter/material.dart';
import '../../core/extensions/context_ext.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction.dart';

class TransactionTile extends StatelessWidget {
  final ExpenseTxn txn;
  final VoidCallback? onTap;
  final bool showDay;

  const TransactionTile({
    super.key,
    required this.txn,
    this.onTap,
    this.showDay = false,
  });

  @override
  Widget build(BuildContext context) {
    final cat = txn.category;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: cat.gradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: cat.gradient.colors.last.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(cat.emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            txn.merchant,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _SourceChip(source: txn.source),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${cat.name} · ${showDay ? Dates.human(txn.date) + ' · ' : ''}${Dates.time(txn.date)}',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                Money.inr(txn.amount),
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  final CaptureSource source;
  const _SourceChip({required this.source});

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (source) {
      CaptureSource.screenshot => ('Shot', Icons.crop_original_rounded),
      CaptureSource.gmail => ('Gmail', Icons.mail_outline_rounded),
      CaptureSource.manual => ('Quick', Icons.bolt_rounded),
      CaptureSource.receipt => ('Bill', Icons.receipt_long_rounded),
      CaptureSource.bankSync => ('Bank', Icons.account_balance_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: context.scheme.onSurface.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: context.scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
