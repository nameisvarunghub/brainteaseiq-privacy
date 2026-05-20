import '../models/expense_category.dart';
import '../models/transaction.dart';

/// Translates raw human / OCR text into structured transactions.
///
/// PRODUCTION: route to an on-device tiny LLM (e.g. Gemma 2B int4) or a
/// hosted Claude/GPT endpoint. This scaffold uses deterministic rules so
/// the demo behaves identically without an API key.
class AiParserService {
  AiParserService();

  /// Quick-add: a free-form line like "₹350 Zomato" or "120 petrol".
  ParsedDraft parseQuickAdd(String text) {
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
      confidence: amount > 0 ? 0.92 : 0.4,
    );
  }

  /// Receipt / screenshot OCR text → draft transaction.
  ParsedDraft parseOcrText(String ocrText, {required CaptureSource source}) {
    final amount = _extractAmount(ocrText);
    final merchant = _extractMerchantFromOcr(ocrText);
    final category = _classify(merchant);
    return ParsedDraft(
      amount: amount,
      merchant: merchant,
      categoryKey: category,
      date: DateTime.now(),
      payment: _guessPaymentMode(ocrText),
      confidence: 0.86,
    );
  }

  double _extractAmount(String text) {
    final re = RegExp(r'(?:₹|rs\.?|inr)?\s*(\d{1,3}(?:[,]?\d{2,3})*(?:\.\d{1,2})?)',
        caseSensitive: false);
    final matches = re.allMatches(text).toList();
    if (matches.isEmpty) return 0;
    // Pick the largest sane number — receipts often list line items, total is biggest.
    double best = 0;
    for (final m in matches) {
      final raw = m.group(1)?.replaceAll(',', '');
      final v = double.tryParse(raw ?? '');
      if (v != null && v > best && v < 1000000) best = v;
    }
    return best;
  }

  String _extractMerchant(String text, double amount) {
    var t = text;
    if (amount > 0) {
      t = t.replaceAll(RegExp(r'(?:₹|rs\.?|inr)?\s*\d[\d,\.]*',
          caseSensitive: false), ' ');
    }
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return _titleCase(t);
  }

  String _extractMerchantFromOcr(String ocr) {
    // First non-empty line that isn't a number/date is usually the brand.
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
    if (l.contains('upi') || l.contains('phonepe') || l.contains('gpay') ||
        l.contains('paytm')) return PaymentMode.upi;
    if (l.contains('card') || l.contains('visa') || l.contains('mastercard')) {
      return PaymentMode.card;
    }
    if (l.contains('cash')) return PaymentMode.cash;
    if (l.contains('netbanking') || l.contains('imps') || l.contains('neft')) {
      return PaymentMode.netbanking;
    }
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
