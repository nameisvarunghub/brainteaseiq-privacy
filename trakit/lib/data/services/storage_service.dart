import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

/// Lightweight key-value persistence wrapping SharedPreferences.
///
/// In production this should be swapped for Isar/Hive — the API is shaped
/// so the migration is a single class swap. We keep `getAll/saveAll`
/// instead of per-record CRUD so demo data stays consistent in one read.
class StorageService {
  static const _kTxns = 'trakit.txns.v1';
  static const _kOnboarded = 'trakit.onboarded.v1';
  static const _kThemeMode = 'trakit.themeMode.v1';
  static const _kMonthlyBudget = 'trakit.monthlyBudget.v1';

  final SharedPreferences _prefs;
  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  Future<void> saveTransactions(List<ExpenseTxn> txns) async {
    final raw = jsonEncode(txns.map((t) => t.toJson()).toList());
    await _prefs.setString(_kTxns, raw);
  }

  List<ExpenseTxn>? loadTransactions() {
    final raw = _prefs.getString(_kTxns);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => ExpenseTxn.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  bool get hasOnboarded => _prefs.getBool(_kOnboarded) ?? false;
  Future<void> setOnboarded(bool v) => _prefs.setBool(_kOnboarded, v);

  String? get themeMode => _prefs.getString(_kThemeMode);
  Future<void> setThemeMode(String mode) => _prefs.setString(_kThemeMode, mode);

  double? get monthlyBudget => _prefs.getDouble(_kMonthlyBudget);
  Future<void> setMonthlyBudget(double v) =>
      _prefs.setDouble(_kMonthlyBudget, v);
}
