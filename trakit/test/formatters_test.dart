import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:trakit/core/utils/formatters.dart';

void main() {
  setUpAll(initializeDateFormatting);

  group('Money', () {
    test('Indian comma format', () {
      expect(Money.inr(1299), startsWith('₹'));
      expect(Money.inr(1299).replaceAll(' ', ''), contains('1,299'));
    });

    test('compact', () {
      expect(Money.compact(15000), contains('₹'));
    });

    test('respects paise flag', () {
      expect(Money.inr(199.5, paise: true), contains('.50'));
    });
  });

  group('Dates.human', () {
    test('today returns "Today"', () {
      expect(Dates.human(DateTime.now()), 'Today');
    });
    test('yesterday returns "Yesterday"', () {
      expect(
        Dates.human(DateTime.now().subtract(const Duration(days: 1))),
        'Yesterday',
      );
    });
    test('older than a week returns date string', () {
      final d = DateTime.now().subtract(const Duration(days: 30));
      expect(Dates.human(d), isNot(equals('Today')));
    });
  });
}
