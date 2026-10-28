import 'package:drift/drift.dart';

import '../local/app_database.dart';

/// RF31/RF32: métodos de pago (efectivo, débito, crédito) con alias.
class PaymentMethodsRepository {
  PaymentMethodsRepository(this._db);
  final AppDatabase _db;

  Stream<List<PaymentMethod>> watchPaymentMethods() =>
      _db.watchPaymentMethods();

  Future<int> createPaymentMethod({
    required String alias,
    required String kind,
    required int colorValue,
    String? last4,
    int? billingDay,
    int? dueDay,
  }) =>
      _db.insertPaymentMethod(PaymentMethodsCompanion.insert(
        alias: alias,
        kind: kind,
        colorValue: colorValue,
        last4: Value(last4),
        billingDay: Value(kind == kPaymentKindCredit ? billingDay : null),
        dueDay: Value(kind == kPaymentKindCredit ? dueDay : null),
      ));

  Future<void> updatePaymentMethod(
    int id, {
    required String alias,
    required String kind,
    required int colorValue,
    String? last4,
    int? billingDay,
    int? dueDay,
  }) =>
      _db.updatePaymentMethod(
        id,
        PaymentMethodsCompanion(
          alias: Value(alias),
          kind: Value(kind),
          colorValue: Value(colorValue),
          last4: Value(last4),
          // RF33: los días solo aplican a crédito; al cambiar de tipo se borran.
          billingDay: Value(kind == kPaymentKindCredit ? billingDay : null),
          dueDay: Value(kind == kPaymentKindCredit ? dueDay : null),
        ),
      );

  /// RF31: false si el método tiene gastos, compras en cuotas o gastos
  /// habituales (RF47) asociados, igual que las categorías.
  Future<bool> canDeletePaymentMethod(int id) async =>
      await _db.countTransactionsForPaymentMethod(id) == 0 &&
      await _db.countInstallmentPlansForPaymentMethod(id) == 0 &&
      await _db.countRecurringTemplatesForPaymentMethod(id) == 0;

  Future<void> deletePaymentMethod(int id) => _db.deletePaymentMethod(id);

  Future<int?> lastUsedPaymentMethodId() => _db.lastUsedPaymentMethodId();
}
