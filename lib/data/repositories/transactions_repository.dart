import 'package:drift/drift.dart';

import '../local/app_database.dart';

class TransactionsRepository {
  TransactionsRepository(this._db);
  final AppDatabase _db;

  Stream<List<Transaction>> watchTransactionsForMonth(DateTime month) =>
      _db.watchTransactionsForMonth(month);

  Future<void> deleteTransaction(int id) => _db.deleteTransaction(id);

  /// UX02: borra y devuelve cómo deshacerlo.
  Future<Future<void> Function()> deleteTransactionUndoable(int id) =>
      _db.deleteTransactionUndoable(id);

  Future<void> updateTransaction({
    required int id,
    required String categoryId,
    required int amount,
    required DateTime date,
    String note = '',
    bool isRecurring = false,
    // Requerido aunque sea nullable: omitirlo borraría el método del gasto.
    required int? paymentMethodId,
  }) {
    return _db.updateTransaction(
      id: id,
      categoryId: categoryId,
      amount: amount,
      date: date,
      note: note,
      isRecurring: isRecurring,
      paymentMethodId: paymentMethodId,
    );
  }

  /// Devuelve el id del gasto, para poder deshacerlo (UX01).
  Future<int> addTransaction({
    required String categoryId,
    required int amount,
    required DateTime date,
    String note = '',
    bool isRecurring = false,
    int? recurringTemplateId,
    int? paymentMethodId,
  }) {
    return _db.into(_db.transactions).insert(
          TransactionsCompanion.insert(
            categoryId: categoryId,
            amount: amount,
            date: date,
            note: Value(note),
            isRecurring: Value(isRecurring),
            recurringTemplateId: Value(recurringTemplateId),
            paymentMethodId: Value(paymentMethodId),
          ),
        );
  }

  /// UX03: categoría del último gasto registrado (por orden de registro, no
  /// por fecha del gasto), para preseleccionarla en Agregar.
  Future<String?> lastUsedCategoryId() async {
    final last = await (_db.select(_db.transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(1))
        .getSingleOrNull();
    return last?.categoryId;
  }
}
