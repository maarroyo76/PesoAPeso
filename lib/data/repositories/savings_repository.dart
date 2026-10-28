import '../local/app_database.dart';

class SavingsRepository {
  SavingsRepository(this._db);
  final AppDatabase _db;

  Stream<List<SavingsGoal>> watchGoals() => _db.watchSavingsGoals();

  Future<int> createGoal({required String name, required int targetAmount}) =>
      _db.insertSavingsGoal(name: name, targetAmount: targetAmount);

  Future<void> updateGoal(int id,
          {required String name, required int targetAmount}) =>
      _db.updateSavingsGoal(id, name: name, targetAmount: targetAmount);

  Future<void> deleteGoal(int id) => _db.deleteSavingsGoal(id);

  /// Saldo de cada meta: aportes menos lo usado en gastos (RF52).
  Stream<Map<int, int>> watchGoalBalances() => _db.watchGoalBalances();

  /// RF52: gastos pagados con el ahorro de la meta.
  Stream<List<Transaction>> watchGoalSpending(int goalId) =>
      _db.watchGoalSpending(goalId);

  /// RF52: "Usar ahorro". Falla si [amount] supera el saldo de la meta.
  Future<int> spendFromGoal({
    required int goalId,
    required String categoryId,
    required int amount,
    required DateTime date,
    String note = '',
  }) =>
      _db.spendFromGoal(
          goalId: goalId,
          categoryId: categoryId,
          amount: amount,
          date: date,
          note: note);

  Stream<List<SavingsContribution>> watchContributions(int goalId) =>
      _db.watchContributionsForGoal(goalId);

  /// RF51: total aportado a metas en el mes de [month].
  Stream<int> watchContributedInMonth(DateTime month) =>
      _db.watchContributedInMonth(month);

  Future<int> totalContributedInMonth(DateTime month) =>
      watchContributedInMonth(month).first;

  Future<void> addContribution(
          {required int goalId,
          required int amount,
          required DateTime date,
          String note = ''}) =>
      _db.addContribution(
          goalId: goalId, amount: amount, date: date, note: note);

  Future<void> deleteContribution(int id) => _db.deleteContribution(id);

  /// UX02: borra y devuelve cómo deshacerlo.
  Future<Future<void> Function()> deleteContributionUndoable(int id) =>
      _db.deleteContributionUndoable(id);

  Stream<List<SavingsQuickAdd>> watchQuickAdds(int goalId) =>
      _db.watchQuickAddsForGoal(goalId);

  Future<void> createQuickAdd(
          {required int goalId,
          required String label,
          required String mode,
          required int value}) =>
      _db.insertSavingsQuickAdd(
          goalId: goalId, label: label, mode: mode, value: value);

  Future<void> updateQuickAdd(int id,
          {required String label, required String mode, required int value}) =>
      _db.updateSavingsQuickAdd(id, label: label, mode: mode, value: value);

  Future<void> deleteQuickAdd(int id) => _db.deleteSavingsQuickAdd(id);
}
