import '../mock/dummy_data.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';

class TransactionRepository {
  final StorageService _storage;
  TransactionRepository(this._storage);

  Future<List<ExpenseTxn>> loadInitial() async {
    final cached = _storage.loadTransactions();
    if (cached != null && cached.isNotEmpty) return cached;
    // Seed with rich dummy data so first-launch UI is alive.
    final seeded = DummyData.generate();
    await _storage.saveTransactions(seeded);
    return seeded;
  }

  Future<void> save(List<ExpenseTxn> txns) async {
    await _storage.saveTransactions(txns);
  }
}
