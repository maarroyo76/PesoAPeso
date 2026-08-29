import '../local/app_database.dart';

class CategoriesRepository {
  CategoriesRepository(this._db);
  final AppDatabase _db;

  Stream<List<Category>> watchCategories() => _db.watchCategories();

  Future<void> createCategory(
          {required String id,
          required String name,
          required int colorValue,
          required String iconKey}) =>
      _db.insertCategory(
          id: id, name: name, colorValue: colorValue, iconKey: iconKey);

  Future<void> updateCategoryInfo(String id,
          {required String name,
          required int colorValue,
          required String iconKey}) =>
      _db.updateCategoryInfo(id,
          name: name, colorValue: colorValue, iconKey: iconKey);

  /// false si la categoría tiene gastos registrados, o está referenciada por
  /// un gasto recurrente (RF12) o un acceso rápido (RF24) — en ambos casos
  /// borrarla dejaría transacciones futuras con un categoryId huérfano.
  Future<bool> canDeleteCategory(String id) async {
    if ((await _db.countTransactionsForCategory(id)) != 0) return false;
    if ((await _db.countRecurringTemplatesForCategory(id)) != 0) return false;
    if ((await _db.countQuickExpenseTemplatesForCategory(id)) != 0)
      return false;
    return true;
  }

  Future<void> deleteCategory(String id) => _db.deleteCategory(id);

  Stream<List<CategoryBudget>> watchAllBudgets() => _db.watchAllBudgets();

  Future<void> setBudgetForMonth(
          String categoryId, DateTime month, int amount) =>
      _db.setBudgetForMonth(categoryId, month, amount);

  /// RF04 (corrección): presupuesto TOTAL del mes, fijado directamente por
  /// el usuario — independiente de la suma de presupuestos por categoría.
  Stream<List<MonthlyBudget>> watchAllMonthlyBudgets() =>
      _db.watchAllMonthlyBudgets();

  Future<void> setMonthlyBudgetForMonth(DateTime month, int amount) =>
      _db.setMonthlyBudgetForMonth(month, amount);
}
