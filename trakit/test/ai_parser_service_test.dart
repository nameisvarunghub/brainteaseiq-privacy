import 'package:flutter_test/flutter_test.dart';
import 'package:trakit/data/models/expense_category.dart';
import 'package:trakit/data/models/transaction.dart';
import 'package:trakit/data/services/ai_parser_service.dart';

void main() {
  group('AiParserService — rule-based fallback', () {
    late AiParserService parser;
    setUp(() => parser = AiParserService());

    test('parses "₹350 Zomato" into Food / Zomato / 350', () async {
      final r = await parser.parseQuickAdd('₹350 Zomato');
      expect(r.amount, 350);
      expect(r.merchant, 'Zomato');
      expect(r.categoryKey, CategoryKey.food);
    });

    test('parses "499 Netflix" as Subscriptions', () async {
      final r = await parser.parseQuickAdd('499 Netflix');
      expect(r.amount, 499);
      expect(r.categoryKey, CategoryKey.subscriptions);
    });

    test('parses "120 petrol" as Travel', () async {
      final r = await parser.parseQuickAdd('120 petrol');
      expect(r.amount, 120);
      expect(r.categoryKey, CategoryKey.travel);
    });

    test('Indian comma format: "1,299" → 1299', () async {
      final r = await parser.parseQuickAdd('1,299 Amazon');
      expect(r.amount, 1299);
      expect(r.categoryKey, CategoryKey.shopping);
    });

    test('picks the largest number when multiple appear (receipt totals)',
        () async {
      final r = await parser.parseOcrText(
        'Amazon\nItem 199\nGST 36\nTotal 235\nVisa 4421',
        source: CaptureSource.screenshot,
      );
      expect(r.amount, 235);
    });

    test('detects UPI payment mode from PhonePe blob', () async {
      final r = await parser.parseOcrText(
        'PhonePe Paid to Swiggy ₹348 UPI Ref 432',
        source: CaptureSource.screenshot,
      );
      expect(r.payment, PaymentMode.upi);
    });

    test('detects card payment mode from "Visa ending"', () async {
      final r = await parser.parseOcrText(
        'Amazon.in\nTotal ₹2499\nVisa ending 4421',
        source: CaptureSource.screenshot,
      );
      expect(r.payment, PaymentMode.card);
      expect(r.categoryKey, CategoryKey.shopping);
    });

    test('falls back to Other when no merchant keywords match', () async {
      final r = await parser.parseQuickAdd('99 random');
      expect(r.categoryKey, CategoryKey.other);
    });

    test('empty input yields zero amount + low confidence', () async {
      final r = await parser.parseQuickAdd('');
      expect(r.amount, 0);
      expect(r.confidence, lessThan(0.5));
    });
  });
}
