import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/expense_category.dart';
import '../models/transaction.dart';

/// Generates emotionally believable Indian-context transactions.
///
/// We don't want spreadsheet rows — we want a story: late-night Swiggy
/// streaks, weekend Uber rides, a sneaky Netflix renewal. The generator
/// biases toward weekend spikes and 9-11 PM food orders so demo data
/// "feels real" without hard-coding.
class DummyData {
  DummyData._();

  static const _uuid = Uuid();

  static final _merchants = <CategoryKey, List<_Merchant>>{
    CategoryKey.food: [
      _Merchant('Swiggy', PaymentMode.upi),
      _Merchant('Zomato', PaymentMode.upi),
      _Merchant('Blue Tokai Coffee', PaymentMode.card),
      _Merchant('Third Wave Coffee', PaymentMode.upi),
      _Merchant('Burger King', PaymentMode.upi),
      _Merchant('Domino\'s', PaymentMode.upi),
    ],
    CategoryKey.groceries: [
      _Merchant('Blinkit', PaymentMode.upi),
      _Merchant('Zepto', PaymentMode.upi),
      _Merchant('BigBasket', PaymentMode.card),
      _Merchant('Reliance Fresh', PaymentMode.card),
    ],
    CategoryKey.entertainment: [
      _Merchant('BookMyShow', PaymentMode.card),
      _Merchant('PVR Inox', PaymentMode.card),
      _Merchant('Steam', PaymentMode.card),
    ],
    CategoryKey.travel: [
      _Merchant('Uber', PaymentMode.upi),
      _Merchant('Ola', PaymentMode.upi),
      _Merchant('Rapido', PaymentMode.upi),
      _Merchant('IndiGo', PaymentMode.card),
      _Merchant('IRCTC', PaymentMode.netbanking),
    ],
    CategoryKey.shopping: [
      _Merchant('Amazon', PaymentMode.card),
      _Merchant('Flipkart', PaymentMode.upi),
      _Merchant('Myntra', PaymentMode.card),
      _Merchant('Nykaa', PaymentMode.upi),
      _Merchant('Decathlon', PaymentMode.card),
    ],
    CategoryKey.bills: [
      _Merchant('Airtel Postpaid', PaymentMode.upi),
      _Merchant('Tata Power', PaymentMode.upi),
      _Merchant('JioFiber', PaymentMode.netbanking),
    ],
    CategoryKey.health: [
      _Merchant('PharmEasy', PaymentMode.upi),
      _Merchant('Cult.fit', PaymentMode.card),
      _Merchant('Apollo Pharmacy', PaymentMode.cash),
    ],
    CategoryKey.subscriptions: [
      _Merchant('Netflix', PaymentMode.card),
      _Merchant('Spotify', PaymentMode.card),
      _Merchant('YouTube Premium', PaymentMode.card),
      _Merchant('iCloud+', PaymentMode.card),
    ],
    CategoryKey.banking: [
      _Merchant('HDFC Credit Card', PaymentMode.netbanking),
      _Merchant('SBI Loan EMI', PaymentMode.netbanking),
    ],
  };

  static List<ExpenseTxn> generate({int days = 60, int seed = 42}) {
    final random = Random(seed);
    final now = DateTime.now();
    final out = <ExpenseTxn>[];

    for (int d = 0; d < days; d++) {
      final day = now.subtract(Duration(days: d));
      final isWeekend = day.weekday == DateTime.saturday ||
          day.weekday == DateTime.sunday;
      // 1-5 txns per day, weekends spike
      final count = (isWeekend ? 3 : 1) + random.nextInt(3);

      for (int i = 0; i < count; i++) {
        final categoryKeys = _merchants.keys.toList();
        // food bias on weekends
        final categoryKey = isWeekend && random.nextDouble() < 0.55
            ? CategoryKey.food
            : categoryKeys[random.nextInt(categoryKeys.length)];

        final merchants = _merchants[categoryKey]!;
        final merchant = merchants[random.nextInt(merchants.length)];
        final amount = _amountFor(categoryKey, random);

        // late-night food bias
        final hour = categoryKey == CategoryKey.food && random.nextDouble() < 0.4
            ? 21 + random.nextInt(3)
            : 8 + random.nextInt(14);
        final minute = random.nextInt(60);

        out.add(
          ExpenseTxn(
            id: _uuid.v4(),
            amount: amount,
            merchant: merchant.name,
            categoryKey: categoryKey,
            date: DateTime(day.year, day.month, day.day, hour, minute),
            payment: merchant.mode,
            source: _sourceFor(random),
            note: null,
          ),
        );
      }
    }

    // monthly subscriptions (deterministic, one per month at 1st)
    final subs = _merchants[CategoryKey.subscriptions]!;
    for (final s in subs) {
      out.add(ExpenseTxn(
        id: _uuid.v4(),
        amount: _subAmount(s.name),
        merchant: s.name,
        categoryKey: CategoryKey.subscriptions,
        date: DateTime(now.year, now.month, 1, 9, 12),
        payment: s.mode,
        source: CaptureSource.gmail,
        note: 'Auto-renewed',
      ));
    }

    out.sort((a, b) => b.date.compareTo(a.date));
    return out;
  }

  static double _amountFor(CategoryKey k, Random r) {
    switch (k) {
      case CategoryKey.food:
        return 120 + r.nextInt(680).toDouble();
      case CategoryKey.groceries:
        return 180 + r.nextInt(1400).toDouble();
      case CategoryKey.entertainment:
        return 250 + r.nextInt(800).toDouble();
      case CategoryKey.travel:
        return 60 + r.nextInt(540).toDouble();
      case CategoryKey.shopping:
        return 350 + r.nextInt(4200).toDouble();
      case CategoryKey.bills:
        return 400 + r.nextInt(1600).toDouble();
      case CategoryKey.health:
        return 150 + r.nextInt(900).toDouble();
      case CategoryKey.subscriptions:
        return 149 + r.nextInt(800).toDouble();
      case CategoryKey.banking:
        return 1500 + r.nextInt(8000).toDouble();
      case CategoryKey.other:
        return 50 + r.nextInt(500).toDouble();
    }
  }

  static double _subAmount(String name) {
    switch (name) {
      case 'Netflix':
        return 649;
      case 'Spotify':
        return 119;
      case 'YouTube Premium':
        return 129;
      case 'iCloud+':
        return 75;
    }
    return 199;
  }

  static CaptureSource _sourceFor(Random r) {
    final n = r.nextDouble();
    if (n < 0.5) return CaptureSource.screenshot;
    if (n < 0.75) return CaptureSource.gmail;
    if (n < 0.9) return CaptureSource.manual;
    return CaptureSource.receipt;
  }
}

class _Merchant {
  final String name;
  final PaymentMode mode;
  const _Merchant(this.name, this.mode);
}
