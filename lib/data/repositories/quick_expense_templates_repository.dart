import '../local/app_database.dart';

/// RF02/RF24: accesos rápidos de gasto, configurables por el usuario.
class QuickExpenseTemplatesRepository {
  QuickExpenseTemplatesRepository(this._db);
  final AppDatabase _db;

  Stream<List<QuickExpenseTemplate>> watchAll() =>
      _db.watchQuickExpenseTemplates();

  Future<int> create(
          {required String label,
          required int amount,
          required String categoryId}) =>
      _db.insertQuickExpenseTemplate(
          label: label, amount: amount, categoryId: categoryId);

  Future<void> update(int id,
          {required String label,
          required int amount,
          required String categoryId}) =>
      _db.updateQuickExpenseTemplate(id,
          label: label, amount: amount, categoryId: categoryId);

  Future<void> delete(int id) => _db.deleteQuickExpenseTemplate(id);
}
