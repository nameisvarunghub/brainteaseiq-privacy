import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/expense_category.dart';
import '../../data/models/transaction.dart';
import '../../data/providers/providers.dart';
import '../../data/services/ai_parser_service.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/cards/glass_card.dart';
import '../../widgets/common/aurora_background.dart';

class QuickAddScreen extends ConsumerStatefulWidget {
  const QuickAddScreen({super.key});

  @override
  ConsumerState<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends ConsumerState<QuickAddScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  ParsedDraft? _draft;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    if (v.trim().isEmpty) {
      setState(() => _draft = null);
      return;
    }
    final parsed = ref.read(aiParserProvider).parseQuickAdd(v);
    setState(() => _draft = parsed);
  }

  Future<void> _save() async {
    final d = _draft;
    if (d == null || d.amount <= 0) return;
    HapticFeedback.mediumImpact();
    final txn = ExpenseTxn(
      id: const Uuid().v4(),
      amount: d.amount,
      merchant: d.merchant,
      categoryKey: d.categoryKey,
      date: d.date,
      payment: d.payment,
      source: CaptureSource.manual,
    );
    await ref.read(transactionsProvider.notifier).add(txn);
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
              _TopBar(title: 'Quick add'),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Type it like you\'d say it.',
                        style: context.text.headlineMedium),
                    const SizedBox(height: 6),
                    Text(
                      'e.g. "₹350 Zomato", "120 petrol", "499 Netflix".',
                      style: context.text.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassCard(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    onChanged: _onChanged,
                    textCapitalization: TextCapitalization.sentences,
                    style: context.text.headlineSmall,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '₹350 Swiggy',
                      hintStyle: context.text.headlineSmall?.copyWith(
                        color: context.scheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (_draft != null && _draft!.amount > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _DraftPreview(draft: _draft!),
                ).animate().fade(duration: 220.ms).moveY(begin: 8, end: 0),
              const Spacer(),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + context.padding.bottom),
                child: GradientButton(
                  label: 'Save expense',
                  icon: Icons.check_rounded,
                  expand: true,
                  gradient: AppGradients.brand,
                  onPressed: _draft != null && _draft!.amount > 0 ? _save : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 4),
          Text(title, style: context.text.titleLarge),
        ],
      ),
    );
  }
}

class _DraftPreview extends StatelessWidget {
  final ParsedDraft draft;
  const _DraftPreview({required this.draft});

  @override
  Widget build(BuildContext context) {
    final cat = ExpenseCategory.byKey(draft.categoryKey);
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 14),
              const SizedBox(width: 6),
              Text('AI parsed', style: context.text.labelMedium),
              const Spacer(),
              Text(
                'Confidence ${(draft.confidence * 100).toStringAsFixed(0)}%',
                style: context.text.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: cat.gradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(cat.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(draft.merchant, style: context.text.titleLarge),
                    Text('${cat.name} · ${draft.payment.name.toUpperCase()}',
                        style: context.text.bodySmall),
                  ],
                ),
              ),
              Text(Money.inr(draft.amount), style: context.text.headlineSmall),
            ],
          ),
        ],
      ),
    );
  }
}
