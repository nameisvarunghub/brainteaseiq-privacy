import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/insight.dart';
import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';
import '../services/ai_parser_service.dart';
import '../services/gmail_sync_service.dart';
import '../services/insight_engine.dart';
import '../services/ocr_service.dart';
import '../services/storage_service.dart';

final storageProvider = Provider<StorageService>((_) {
  throw UnimplementedError('storageProvider must be overridden at app start');
});

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(ref.watch(storageProvider)),
);

final ocrServiceProvider = Provider<OcrService>((_) => OcrService());
final aiParserProvider = Provider<AiParserService>((_) => AiParserService());
final gmailSyncProvider = Provider<GmailSyncService>((_) => GmailSyncService());
final insightEngineProvider = Provider<InsightEngine>((_) => InsightEngine());

class TransactionsController extends StateNotifier<AsyncValue<List<ExpenseTxn>>> {
  final TransactionRepository _repo;
  TransactionsController(this._repo) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final txns = await _repo.loadInitial();
      state = AsyncValue.data(txns);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(ExpenseTxn t) async {
    final current = state.value ?? const <ExpenseTxn>[];
    final next = [t, ...current]..sort((a, b) => b.date.compareTo(a.date));
    state = AsyncValue.data(next);
    await _repo.save(next);
  }

  Future<void> addMany(List<ExpenseTxn> ts) async {
    final current = state.value ?? const <ExpenseTxn>[];
    final next = [...ts, ...current]..sort((a, b) => b.date.compareTo(a.date));
    state = AsyncValue.data(next);
    await _repo.save(next);
  }

  Future<void> delete(String id) async {
    final current = state.value ?? const <ExpenseTxn>[];
    final next = current.where((t) => t.id != id).toList();
    state = AsyncValue.data(next);
    await _repo.save(next);
  }

  Future<void> reset() async {
    state = const AsyncValue.data([]);
    await _repo.save(const []);
  }
}

final transactionsProvider =
    StateNotifierProvider<TransactionsController, AsyncValue<List<ExpenseTxn>>>(
  (ref) => TransactionsController(ref.watch(transactionRepositoryProvider)),
);

/// Derived: total spend this month.
final monthSpendProvider = Provider<double>((ref) {
  final txns = ref.watch(transactionsProvider).value ?? const [];
  final now = DateTime.now();
  return txns
      .where((t) => t.date.year == now.year && t.date.month == now.month)
      .fold<double>(0, (s, t) => s + t.amount);
});

/// Derived: spend by category for this month.
final monthByCategoryProvider = Provider<Map<String, double>>((ref) {
  final txns = ref.watch(transactionsProvider).value ?? const [];
  final now = DateTime.now();
  final out = <String, double>{};
  for (final t in txns) {
    if (t.date.year != now.year || t.date.month != now.month) continue;
    out[t.category.name] = (out[t.category.name] ?? 0) + t.amount;
  }
  return out;
});

/// Derived: last 7-day daily totals (oldest → newest).
final last7DaysProvider = Provider<List<double>>((ref) {
  final txns = ref.watch(transactionsProvider).value ?? const [];
  final now = DateTime.now();
  final out = List<double>.filled(7, 0);
  for (final t in txns) {
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(t.date.year, t.date.month, t.date.day))
        .inDays;
    if (diff >= 0 && diff < 7) out[6 - diff] += t.amount;
  }
  return out;
});

final insightsProvider = Provider<List<Insight>>((ref) {
  final txns = ref.watch(transactionsProvider).value ?? const [];
  return ref.watch(insightEngineProvider).generate(txns);
});

/// Theme mode (persisted).
class ThemeModeController extends StateNotifier<ThemeMode> {
  final StorageService _storage;
  ThemeModeController(this._storage)
      : super(_storage.themeMode == 'light'
            ? ThemeMode.light
            : _storage.themeMode == 'dark'
                ? ThemeMode.dark
                : ThemeMode.dark);

  void set(ThemeMode mode) {
    state = mode;
    _storage.setThemeMode(mode.name);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) => ThemeModeController(ref.watch(storageProvider)),
);
