import 'package:equatable/equatable.dart';
import 'expense_category.dart';

enum CaptureSource { screenshot, gmail, manual, receipt, bankSync }

enum PaymentMode { upi, card, cash, wallet, netbanking, unknown }

class ExpenseTxn extends Equatable {
  final String id;
  final double amount;
  final String merchant;
  final CategoryKey categoryKey;
  final DateTime date;
  final PaymentMode payment;
  final CaptureSource source;
  final String? note;
  final String? rawSourceText; // raw OCR / email blob for traceability

  const ExpenseTxn({
    required this.id,
    required this.amount,
    required this.merchant,
    required this.categoryKey,
    required this.date,
    required this.payment,
    required this.source,
    this.note,
    this.rawSourceText,
  });

  ExpenseCategory get category => ExpenseCategory.byKey(categoryKey);

  ExpenseTxn copyWith({
    String? id,
    double? amount,
    String? merchant,
    CategoryKey? categoryKey,
    DateTime? date,
    PaymentMode? payment,
    CaptureSource? source,
    String? note,
    String? rawSourceText,
  }) {
    return ExpenseTxn(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      categoryKey: categoryKey ?? this.categoryKey,
      date: date ?? this.date,
      payment: payment ?? this.payment,
      source: source ?? this.source,
      note: note ?? this.note,
      rawSourceText: rawSourceText ?? this.rawSourceText,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'merchant': merchant,
        'categoryKey': categoryKey.name,
        'date': date.toIso8601String(),
        'payment': payment.name,
        'source': source.name,
        'note': note,
        'rawSourceText': rawSourceText,
      };

  factory ExpenseTxn.fromJson(Map<String, dynamic> json) => ExpenseTxn(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        merchant: json['merchant'] as String,
        categoryKey: CategoryKey.values.firstWhere(
          (e) => e.name == json['categoryKey'],
          orElse: () => CategoryKey.other,
        ),
        date: DateTime.parse(json['date'] as String),
        payment: PaymentMode.values.firstWhere(
          (e) => e.name == json['payment'],
          orElse: () => PaymentMode.unknown,
        ),
        source: CaptureSource.values.firstWhere(
          (e) => e.name == json['source'],
          orElse: () => CaptureSource.manual,
        ),
        note: json['note'] as String?,
        rawSourceText: json['rawSourceText'] as String?,
      );

  @override
  List<Object?> get props =>
      [id, amount, merchant, categoryKey, date, payment, source, note];
}
