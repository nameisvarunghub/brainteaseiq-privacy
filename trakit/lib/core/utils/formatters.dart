import 'package:intl/intl.dart';

class Money {
  Money._();

  static final _full = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final _withPaise = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final _compact = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 1,
  );

  static String inr(num amount, {bool paise = false}) =>
      (paise ? _withPaise : _full).format(amount);

  static String compact(num amount) => _compact.format(amount);
}

class Dates {
  Dates._();
  static String human(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(d);
    return DateFormat('d MMM').format(d);
  }

  static String time(DateTime d) => DateFormat('h:mm a').format(d);
  static String monthYear(DateTime d) => DateFormat('MMMM yyyy').format(d);
  static String fullStamp(DateTime d) =>
      DateFormat('d MMM yyyy · h:mm a').format(d);
}
