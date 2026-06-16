import 'package:flutter_test/flutter_test.dart';
import 'package:trakit/data/mock/dummy_data.dart';
import 'package:trakit/data/models/insight.dart';
import 'package:trakit/data/services/insight_engine.dart';

void main() {
  group('InsightEngine', () {
    test('emits welcome insight for empty transactions', () {
      final insights = InsightEngine().generate([]);
      expect(insights, isNotEmpty);
      expect(insights.first.tone, InsightTone.info);
    });

    test('produces 3+ insights from seeded dummy data', () {
      final txns = DummyData.generate(seed: 7);
      final insights = InsightEngine().generate(txns);
      expect(insights.length, greaterThanOrEqualTo(3));
    });

    test('always includes a subscriptions total when subs exist', () {
      final txns = DummyData.generate(seed: 7);
      final insights = InsightEngine().generate(txns);
      expect(
        insights.any((i) => i.title.contains('Subscriptions total')),
        isTrue,
      );
    });

    test('each insight has non-empty title and body', () {
      final txns = DummyData.generate(seed: 1);
      for (final i in InsightEngine().generate(txns)) {
        expect(i.title, isNotEmpty);
        expect(i.body, isNotEmpty);
      }
    });
  });
}
