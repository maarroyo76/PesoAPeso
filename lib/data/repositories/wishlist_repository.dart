import 'package:drift/drift.dart' show Value;

import '../local/app_database.dart';

/// RF61/RF62: lista de espera de compras no urgentes.
class WishlistRepository {
  WishlistRepository(this._db);
  final AppDatabase _db;

  Stream<List<WishlistItem>> watchAll() => _db.watchWishlist();

  Future<int> create({
    required String name,
    required int amount,
    required int installmentCount,
    double monthlyRate = 0,
    int? paymentMethodId,
    String? categoryId,
    required DateTime createdAt,
    required DateTime dueAt,
  }) =>
      _db.insertWish(WishlistItemsCompanion.insert(
        name: name,
        amount: amount,
        installmentCount: Value(installmentCount),
        monthlyRate: Value(monthlyRate),
        paymentMethodId: Value(paymentMethodId),
        categoryId: Value(categoryId),
        createdAt: createdAt,
        dueAt: dueAt,
      ));

  Future<void> update(
    int id, {
    required String name,
    required int amount,
    required int installmentCount,
    required DateTime dueAt,
  }) =>
      _db.updateWish(
          id,
          WishlistItemsCompanion(
            name: Value(name),
            amount: Value(amount),
            installmentCount: Value(installmentCount),
            dueAt: Value(dueAt),
          ));

  Future<Future<void> Function()> deleteUndoable(int id) =>
      _db.deleteWishUndoable(id);

  Future<void> markBought(int id,
          {int? installmentPlanId, int? transactionId, DateTime? at}) =>
      _db.decideWish(id,
          status: kWishBought,
          at: at ?? DateTime.now(),
          installmentPlanId: installmentPlanId,
          transactionId: transactionId);

  Future<void> discard(int id, {DateTime? at}) =>
      _db.decideWish(id, status: kWishDiscarded, at: at ?? DateTime.now());

  Future<Future<void> Function()> saveToGoal(int id,
          {required int goalId, DateTime? at}) =>
      _db.saveWishToGoal(id, goalId: goalId, at: at ?? DateTime.now());

  Future<void> reset(int id) => _db.resetWish(id);
}
