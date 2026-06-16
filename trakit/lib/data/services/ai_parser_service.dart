import 'package:flutter/foundation.dart';

import '../models/expense_category.dart';
import '../models/transaction.dart';
import 'claude_service.dart';

/// Translates raw human / OCR text into structured transactions.
///
/// When `ClaudeService.isConfigured` is true we ask Haiku 4.5 to do it; the
/// deterministic rule engine below is the fallback (no API key, network
/// failure, or malformed model output). Both paths produce the same
/// [ParsedDraft] shape, so callers don't care which fired.
class AiParserService {
  final ClaudeService _claude;
  AiParserService({ClaudeService? claude})
      : _claude = claude ?? ClaudeService();

  bool get usingLlm => _claude.isConfigured;

  /// Quick-add: a free-form line like "₹350 Zomato" or "120 petrol".
  Future<ParsedDraft> parseQuickAdd(String text) async {
    if (_claude.isConfigured) {
      final llm = await _tryLlm(text, source: 'quick_add');
      if (llm != null) return llm;
    }
    return _parseQuickAddLocal(text);
  }

  /// Receipt / screenshot OCR text → draft transaction.
  Future<ParsedDraft> parseOcrText(
    String ocrText, {
    required CaptureSource source,
  }) async {
    if (_claude.isConfigured) {
      final llm = await _tryLlm(ocrText, source: source.name);
      if (llm != null) return llm;
    }
    return _parseOcrLocal(ocrText, source);
  }

  Future<ParsedDraft?> _tryLlm(String text, {required String source}) async {
    try {
      final json = await _claude.extractExpense(
        inputText: text,
        captureSource: source,
      );
      if (json == null) return null;
      return ParsedDraft(
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        merchant: (json['merchant'] as String?)?.trim() ?? 'Unknown',
        categoryKey: ExpenseCategory.byName(
          (json['category'] as String?) ?? 'Other',
        ).key,
        date: DateTime.now(),
        payment: PaymentMode.values.firstWhere(
          (e) => e.name == json['payment_mode'],
          orElse: () => PaymentMode.unknown,
        ),
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.7,
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('Claude parser failed, falling back: $e\n$st');
      return null;
    }
  }

  // ---------------------------------------------------------------- rules

  ParsedDraft _parseQuickAddLocal(String text) {
    final cleaned = text.trim();
    final amount = _extractAmount(cleaned);
    final merchant = _extractMerchant(cleaned, amount);
    final category = _classify(merchant.isEmpty ? cleaned : merchant);
    return ParsedDraft(
      amount: amount,
      merchant: merchant.isEmpty ? _titleCase(cleaned) : merchant,
      categoryKey: category,
      date: DateTime.now(),
      payment: PaymentMode.upi,
      confidence: amount > 0 ? 0.82 : 0.4,
    );
  }

  ParsedDraft _parseOcrLocal(String ocrText, CaptureSource source) {
    final amount = _extractAmount(ocrText);
    final merchant = _extractMerchantFromOcr(ocrText);
    final category = _classify(merchant);
    return ParsedDraft(
      amount: amount,
      merchant: merchant,
      categoryKey: category,
      date: DateTime.now(),
      payment: _guessPaymentMode(ocrText),
      confidence: 0.78,
    );
  }

  // Naive number scanning fooled by reference numbers, card suffixes, and
  // order IDs. We classify each match by what precedes it and prefer:
  //   1. amounts after "total/amount/paid/bill/grand" keywords
  //   2. amounts with a ₹ / Rs. / INR marker
  //   3. everything else (largest of the remaining)
  // We exclude matches that follow blacklist words like "ref" / "ending" /
  // "card" / "#" — those are identifiers, not money.
  double _extractAmount(String text) {
    final re = RegExp(
      r'(\d{1,3}(?:[,]?\d{2,3})*(?:\.\d{1,2})?)',
      caseSensitive: false,
    );
    final preferred = <double>[];
    final currency = <double>[];
    final rest = <double>[];

    final lower = text.toLowerCase();
    for (final m in re.allMatches(text)) {
      final raw = m.group(1)?.replaceAll(',', '');
      final v = double.tryParse(raw ?? '');
      if (v == null || v <= 0 || v >= 1000000) continue;

      // Look back up to ~24 chars for context — enough to catch "Visa ending"
      // or "Order #" but short enough that we don't bind across unrelated lines.
      final start = m.start;
      final ctxStart = (start - 24).clamp(0, lower.length);
      final ctx = lower.substring(ctxStart, start);

      if (_blacklist.hasMatch(ctx)) continue; // reference / card / id
      if (_totalish.hasMatch(ctx)) {
        preferred.add(v);
        continue;
      }
      if (_currencyish.hasMatch(ctx)) {
        currency.add(v);
        continue;
      }
      rest.add(v);
    }

    if (preferred.isNotEmpty) return preferred.reduce(_max);
    if (currency.isNotEmpty) return currency.reduce(_max);
    if (rest.isNotEmpty) return rest.reduce(_max);
    return 0;
  }

  static double _max(double a, double b) => a > b ? a : b;

  static final RegExp _blacklist = RegExp(
    r'(?:ref|ending|card|visa|mastercard|rupay|amex|#|order|txn|transaction|id|invoice|otp|cvv|account|a/c|imps|neft|utr|sequence|approved)\s*[:#-]?\s*$',
    caseSensitive: false,
  );
  static final RegExp _totalish = RegExp(
    r'(?:total|amount\s*paid|grand\s*total|bill|amount|paid|payable|due|net)\s*[:#-]?\s*$',
    caseSensitive: false,
  );
  static final RegExp _currencyish = RegExp(
    r'(?:₹|rs\.?|inr)\s*$',
    caseSensitive: false,
  );

  String _extractMerchant(String text, double amount) {
    var t = text;
    if (amount > 0) {
      t = t.replaceAll(
        RegExp(r'(?:₹|rs\.?|inr)?\s*\d[\d,\.]*', caseSensitive: false),
        ' ',
      );
    }
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return _titleCase(t);
  }

  String _extractMerchantFromOcr(String ocr) {
    for (final line in ocr.split('\n')) {
      final l = line.trim();
      if (l.isEmpty) continue;
      if (RegExp(r'^[\d\W]+$').hasMatch(l)) continue;
      if (l.length > 40) continue;
      return _titleCase(l);
    }
    return 'Unknown';
  }

  CategoryKey _classify(String text) {
    final l = text.toLowerCase();
    for (final entry in _keywordMap.entries) {
      for (final kw in entry.value) {
        if (l.contains(kw)) return entry.key;
      }
    }
    return CategoryKey.other;
  }

  PaymentMode _guessPaymentMode(String ocr) {
    final l = ocr.toLowerCase();
    if (l.contains('upi') ||
        l.contains('phonepe') ||
        l.contains('gpay') ||
        l.contains('paytm')) return PaymentMode.upi;
    if (l.contains('card') ||
        l.contains('visa') ||
        l.contains('mastercard')) return PaymentMode.card;
    if (l.contains('cash')) return PaymentMode.cash;
    if (l.contains('netbanking') ||
        l.contains('imps') ||
        l.contains('neft')) return PaymentMode.netbanking;
    return PaymentMode.unknown;
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  static const Map<CategoryKey, List<String>> _keywordMap = {
    CategoryKey.food: [
      'swiggy', 'zomato', 'eat', 'restaurant', 'cafe', 'coffee', 'pizza',
      'burger', 'biryani', 'dosa', 'starbucks', 'domino', 'kfc', 'mcd',
    ],
    CategoryKey.groceries: [
      'blinkit', 'zepto', 'bigbasket', 'grocer', 'reliance fresh', 'dmart',
      'instamart', 'milk', 'vegetable',
    ],
    CategoryKey.entertainment: [
      'bookmyshow', 'pvr', 'inox', 'cinema', 'movie', 'steam', 'playstation',
      'concert',
    ],
    CategoryKey.travel: [
      'uber', 'ola', 'rapido', 'indigo', 'vistara', 'irctc', 'metro',
      'petrol', 'fuel', 'cab', 'flight',
    ],
    CategoryKey.shopping: [
      'amazon', 'flipkart', 'myntra', 'nykaa', 'ajio', 'decathlon', 'ikea',
      'h&m', 'zara',
    ],
    CategoryKey.bills: [
      'airtel', 'jio', 'vi ', 'tata power', 'bescom', 'electricity', 'water',
      'gas', 'recharge', 'broadband',
    ],
    CategoryKey.health: [
      'pharmeasy', 'apollo', 'medplus', 'cult', 'gym', 'fitness', 'doctor',
      'clinic', 'hospital',
    ],
    CategoryKey.subscriptions: [
      'netflix', 'spotify', 'youtube premium', 'icloud', 'prime', 'hotstar',
      'jiosaavn', 'apple music',
    ],
    CategoryKey.banking: [
      'emi', 'loan', 'credit card', 'interest', 'sbi', 'hdfc', 'icici',
    ],
  };
}

class ParsedDraft {
  final double amount;
  final String merchant;
  final CategoryKey categoryKey;
  final DateTime date;
  final PaymentMode payment;
  final double confidence;

  const ParsedDraft({
    required this.amount,
    required this.merchant,
    required this.categoryKey,
    required this.date,
    required this.payment,
    required this.confidence,
  });
}
