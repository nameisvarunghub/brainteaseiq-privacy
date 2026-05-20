import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trakit/data/mock/dummy_data.dart';
import 'package:trakit/data/services/storage_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('StorageService', () {
    test('round-trips a list of transactions', () async {
      final storage = await StorageService.init();
      final txns = DummyData.generate(days: 7, seed: 1);
      await storage.saveTransactions(txns);
      final loaded = storage.loadTransactions();
      expect(loaded, isNotNull);
      expect(loaded!.length, txns.length);
      expect(loaded.first.merchant, txns.first.merchant);
      expect(loaded.first.amount, txns.first.amount);
    });

    test('returns null when nothing stored', () async {
      final storage = await StorageService.init();
      expect(storage.loadTransactions(), isNull);
    });

    test('onboarded flag round-trips', () async {
      final storage = await StorageService.init();
      expect(storage.hasOnboarded, isFalse);
      await storage.setOnboarded(true);
      expect(storage.hasOnboarded, isTrue);
    });

    test('survives a malformed cached blob', () async {
      SharedPreferences.setMockInitialValues({'trakit.txns.v1': '{not json'});
      final storage = await StorageService.init();
      expect(storage.loadTransactions(), isNull);
    });
  });
}
