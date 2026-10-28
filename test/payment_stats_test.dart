// RF33: período de facturación. RF40–RF43: estadísticas por método de pago.

import 'package:flutter_test/flutter_test.dart';
import 'package:peso_a_peso/core/utils/billing_period.dart';
import 'package:peso_a_peso/core/utils/payment_stats.dart';
import 'package:peso_a_peso/data/local/app_database.dart';

Transaction _tx(int id, int amount, DateTime date,
        {int? method, int? installment}) =>
    Transaction(
      id: id,
      categoryId: 'ocio',
      amount: amount,
      date: date,
      note: '',
      isRecurring: false,
      paymentMethodId: method,
      installmentNumber: installment,
      installmentPlanId: installment == null ? null : 1,
    );

PaymentMethod _method(int id, String kind, {int? billingDay, int? dueDay}) =>
    PaymentMethod(
        id: id,
        alias: 'M$id',
        kind: kind,
        colorValue: 1,
        billingDay: billingDay,
        dueDay: dueDay);

void main() {
  group('RF33: período de facturación', () {
    test('compra hasta el cierre entra en ese cierre; después, en el otro', () {
      expect(
        billingPeriodFor(DateTime(2026, 10, 20, 23), billingDay: 20, dueDay: 5),
        BillingPeriod(
            start: DateTime(2026, 9, 21),
            closing: DateTime(2026, 10, 20),
            due: DateTime(2026, 11, 5)),
      );
      expect(
        billingPeriodFor(DateTime(2026, 10, 21), billingDay: 20, dueDay: 5),
        BillingPeriod(
            start: DateTime(2026, 10, 21),
            closing: DateTime(2026, 11, 20),
            due: DateTime(2026, 12, 5)),
      );
    });

    test('cierre el 31 se recorta al largo del mes; pago en el mismo mes', () {
      expect(
        billingPeriodFor(DateTime(2027, 2, 15), billingDay: 31, dueDay: 30),
        BillingPeriod(
            start: DateTime(2027, 2, 1),
            closing: DateTime(2027, 2, 28),
            due: DateTime(2027, 3, 30)),
      );
      expect(
        billingPeriodFor(DateTime(2026, 10, 3), billingDay: 10, dueDay: 25).due,
        DateTime(2026, 10, 25),
      );
      expect(
          billingPeriodFor(DateTime(2026, 10, 3), billingDay: 10).due, isNull);
    });
  });

  group('RF40/RF41: gasto por método y por tipo', () {
    final d = DateTime(2026, 10, 5);
    final txs = [
      _tx(1, 1000, d, method: 1),
      _tx(2, 2000, d, method: 2),
      _tx(3, 500, d),
      _tx(4, 1500, d, method: 1),
    ];
    final methods = {
      1: _method(1, kPaymentKindCredit),
      2: _method(2, kPaymentKindCash),
    };

    test('la suma por métodos es el total, con "Sin especificar" aparte', () {
      final byMethod = spentByPaymentMethod(txs);
      expect(byMethod, {1: 2500, 2: 2000, null: 500});
      expect(byMethod.values.reduce((a, b) => a + b), 5000);
    });

    test('por tipo de método', () {
      expect(spentByKind(txs, methods), {
        kPaymentKindCredit: 2500,
        kPaymentKindCash: 2000,
        kNoPaymentKind: 500,
      });
    });

    test('los porcentajes de cada mes suman 100', () {
      expect(
          percentagesOf({'a': 1, 'b': 1, 'c': 1})
              .values
              .reduce((a, b) => a + b),
          100);
      expect(percentagesOf({'a': 2500, 'b': 2000, 'c': 500}),
          {'a': 50, 'b': 40, 'c': 10});
      expect(percentagesOf(<String, int>{}), isEmpty);
    });
  });

  test('RF42: deuda en cuotas por tarjeta, desde el mes siguiente', () {
    final txs = [
      _tx(1, 10000, DateTime(2026, 10, 15), method: 1, installment: 1),
      _tx(2, 10000, DateTime(2026, 11, 15), method: 1, installment: 2),
      _tx(3, 10000, DateTime(2026, 12, 15), method: 1, installment: 3),
      _tx(4, 3000, DateTime(2026, 11, 2), method: 2, installment: 2),
      // El prepago no es una cuota pendiente.
      _tx(5, 7000, DateTime(2026, 11, 30), method: 2),
    ];
    expect(installmentDebtByCard(txs, DateTime(2026, 10)), {1: 20000, 2: 3000});
  });

  test('RF43: estado de cuenta estimado del período en curso', () {
    final card = _method(1, kPaymentKindCredit, billingDay: 20, dueDay: 5);
    final txs = [
      _tx(1, 1000, DateTime(2026, 9, 20), method: 1), // período anterior
      _tx(2, 2000, DateTime(2026, 9, 21), method: 1),
      _tx(3, 3000, DateTime(2026, 10, 20, 22), method: 1, installment: 2),
      _tx(4, 4000, DateTime(2026, 10, 21), method: 1), // período siguiente
      _tx(5, 9000, DateTime(2026, 10, 1), method: 2), // otra tarjeta
    ];
    final statement = estimatedStatement(card, txs, DateTime(2026, 10, 8))!;
    expect(statement.amount, 5000);
    expect(statement.period.closing, DateTime(2026, 10, 20));
    expect(statement.period.due, DateTime(2026, 11, 5));
    expect(
        estimatedStatement(
            _method(2, kPaymentKindCredit), txs, DateTime(2026, 10, 8)),
        isNull,
        reason: 'sin día de facturación no se puede estimar');
  });
}
