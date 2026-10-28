import '../local/app_database.dart';

/// RF34/RF35/RF36: compras en cuotas con tarjeta de crédito.
class InstallmentsRepository {
  InstallmentsRepository(this._db);
  final AppDatabase _db;

  Stream<List<InstallmentPlan>> watchPlans() => _db.watchInstallmentPlans();

  /// Cuotas y prepagos de todos los planes.
  Stream<List<Transaction>> watchInstallmentTransactions() =>
      _db.watchInstallmentTransactions();

  Future<int> createPlan({
    required int paymentMethodId,
    required String categoryId,
    required String note,
    required int totalAmount,
    required int count,
    required DateTime purchaseDate,
  }) =>
      _db.createInstallmentPlan(
        paymentMethodId: paymentMethodId,
        categoryId: categoryId,
        note: note,
        totalAmount: totalAmount,
        count: count,
        purchaseDate: purchaseDate,
      );

  Future<void> updatePlanInfo(int planId,
          {required String categoryId, required String note}) =>
      _db.updateInstallmentPlanInfo(planId, categoryId: categoryId, note: note);

  Future<void> prepay(int planId) => _db.prepayInstallmentPlan(planId);

  Future<void> deletePlan(int planId) => _db.deleteInstallmentPlan(planId);
}
