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

  Stream<Map<int, int>> watchTotalContributedByGoal() =>
      _db.watchTotalContributedByGoal();

  Stream<List<SavingsContribution>> watchContributions(int goalId) =>
      _db.watchContributionsForGoal(goalId);

  Future<void> addContribution(
          {required int goalId,
          required int amount,
          required DateTime date,
          String note = ''}) =>
      _db.addContribution(
          goalId: goalId, amount: amount, date: date, note: note);

  Future<void> deleteContribution(int id) => _db.deleteContribution(id);

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
