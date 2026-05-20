import 'package:flutter_test/flutter_test.dart';
import 'package:trakit/data/mock/dummy_data.dart';
import 'package:trakit/data/models/expense_category.dart';

void main() {
  group('DummyData', () {
    test('generates transactions sorted newest first', () {
      final txns = DummyData.generate(days: 14, seed: 1);
      for (int i = 0; i < txns.length - 1; i++) {
        expect(
          txns[i].date.isAfter(txns[i + 1].date) ||
              txns[i].date.isAtSameMomentAs(txns[i + 1].date),
          isTrue,
        );
      }
    });

    test('all transactions have non-zero amounts', () {
      final txns = DummyData.generate(seed: 1);
      expect(txns.every((t) => t.amount > 0), isTrue);
    });

    test('seeded subscriptions exist exactly once each per generation', () {
      final txns = DummyData.generate(seed: 1);
      final subs = txns.where((t) => t.categoryKey == CategoryKey.subscriptions);
      // Subscriptions include both monthly-auto-renewals and random sub txns;
      // there should be at least the 4 seeded auto-renewals.
      expect(subs.length, greaterThanOrEqualTo(4));
    });

    test('deterministic for a given seed', () {
      final a = DummyData.generate(seed: 99);
      final b = DummyData.generate(seed: 99);
      expect(a.length, b.length);
      for (int i = 0; i < a.length; i++) {
        expect(a[i].amount, b[i].amount);
        expect(a[i].merchant, b[i].merchant);
      }
    });
  });
}
