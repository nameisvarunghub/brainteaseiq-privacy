import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/expense_category.dart';
import '../models/transaction.dart';

/// Stubs the Gmail OAuth + transaction-email scan pipeline.
///
/// PRODUCTION: wire `googleapis` + `google_sign_in` with the
/// `gmail.readonly` scope, then run regex over Razorpay/Cred/Amazon/Swiggy
/// receipt formats. The demo emits a fixed list and a fake progress
/// stream so the UI can show "Scanning 1,248 emails…" believably.
class GmailSyncService {
  static const _uuid = Uuid();

  Stream<GmailSyncProgress> scan() async* {
    yield const GmailSyncProgress(0, 'Connecting to Gmail…');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    yield const GmailSyncProgress(0.15, 'Searching transaction emails…');
    await Future<void>.delayed(const Duration(milliseconds: 700));
    yield const GmailSyncProgress(0.5, 'Parsing receipts…');
    await Future<void>.delayed(const Duration(milliseconds: 800));
    yield const GmailSyncProgress(0.85, 'Tagging categories with AI…');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    yield GmailSyncProgress(1.0, 'Imported ${_samples.length} expenses', done: true);
  }

  List<ExpenseTxn> harvest() {
    final now = DateTime.now();
    return _samples.asMap().entries.map((e) {
      final i = e.key;
      final s = e.value;
      return ExpenseTxn(
        id: _uuid.v4(),
        amount: s.amount,
        merchant: s.merchant,
        categoryKey: s.category,
        date: now.subtract(Duration(days: i + 1, hours: 2)),
        payment: PaymentMode.card,
        source: CaptureSource.gmail,
        note: 'From Gmail',
      );
    }).toList();
  }

  static const _samples = <_GmailSample>[
    _GmailSample(749, 'Netflix', CategoryKey.subscriptions),
    _GmailSample(2399, 'Amazon', CategoryKey.shopping),
    _GmailSample(1299, 'Myntra', CategoryKey.shopping),
    _GmailSample(449, 'Swiggy', CategoryKey.food),
    _GmailSample(119, 'Spotify', CategoryKey.subscriptions),
  ];
}

class GmailSyncProgress {
  final double progress;
  final String label;
  final bool done;
  const GmailSyncProgress(this.progress, this.label, {this.done = false});
}

class _GmailSample {
  final double amount;
  final String merchant;
  final CategoryKey category;
  const _GmailSample(this.amount, this.merchant, this.category);
}
