import '../local/app_database.dart';

class RecurringTemplatesRepository {
  RecurringTemplatesRepository(this._db);
  final AppDatabase _db;

  Stream<List<RecurringTemplate>> watchTemplates() =>
      _db.watchRecurringTemplates();

  Future<void> createTemplate({
    required String categoryId,
    required int amount,
    required String note,
    required int dayOfMonth,
    required int initialYearMonth,
  }) {
    return _db.insertRecurringTemplate(
      categoryId: categoryId,
      amount: amount,
      note: note,
      dayOfMonth: dayOfMonth,
      initialYearMonth: initialYearMonth,
    );
  }

  Future<List<Transaction>> runCatchUp() => _db.runRecurringCatchUp();

  /// RF25: editar/eliminar un recurrente ya creado.
  Future<void> updateTemplate(
    int id, {
    required String categoryId,
    required int amount,
    required String note,
    required int dayOfMonth,
    required bool active,
  }) {
    return _db.updateRecurringTemplate(
      id,
      categoryId: categoryId,
      amount: amount,
      note: note,
      dayOfMonth: dayOfMonth,
      active: active,
    );
  }

  Future<void> deleteTemplate(int id) => _db.deleteRecurringTemplate(id);
}
