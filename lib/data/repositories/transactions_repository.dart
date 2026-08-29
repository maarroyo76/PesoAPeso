import 'package:drift/drift.dart';

import '../local/app_database.dart';

class TransactionsRepository {
  TransactionsRepository(this._db);
  final AppDatabase _db;

  Stream<List<Transaction>> watchTransactionsForMonth(DateTime month) =>
      _db.watchTransactionsForMonth(month);

  Future<void> deleteTransaction(int id) => _db.deleteTransaction(id);

  Future<void> updateTransaction({
    required int id,
    required String categoryId,
    required int amount,
    required DateTime date,
    String note = '',
    bool isRecurring = false,
  }) {
    return _db.updateTransaction(
      id: id,
      categoryId: categoryId,
      amount: amount,
      date: date,
      note: note,
      isRecurring: isRecurring,
    );
  }

  Future<void> addTransaction({
    required String categoryId,
    required int amount,
    required DateTime date,
    String note = '',
    bool isRecurring = false,
  }) {
    return _db.into(_db.transactions).insert(
          TransactionsCompanion.insert(
            categoryId: categoryId,
            amount: amount,
            date: date,
            note: Value(note),
            isRecurring: Value(isRecurring),
          ),
        );
  }
}
