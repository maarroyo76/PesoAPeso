/// RF40–RF43: estadísticas por método de pago.
library;

import '../../data/local/app_database.dart';
import 'billing_period.dart';

/// Grupo de "Sin especificar" en [spentByKind]: gastos sin método o con un
/// método que ya no existe.
const kNoPaymentKind = 'none';

/// RF40: gasto por método de pago; la clave null agrupa "Sin especificar".
/// La suma de los valores es siempre el total de [transactions].
Map<int?, int> spentByPaymentMethod(Iterable<Transaction> transactions) {
  final result = <int?, int>{};
  for (final t in transactions) {
    result[t.paymentMethodId] = (result[t.paymentMethodId] ?? 0) + t.amount;
  }
  return result;
}

/// RF41: gasto por tipo (crédito, débito, efectivo o [kNoPaymentKind]).
Map<String, int> spentByKind(
    Iterable<Transaction> transactions, Map<int, PaymentMethod> methodsById) {
  final result = <String, int>{};
  for (final t in transactions) {
    final kind = methodsById[t.paymentMethodId]?.kind ?? kNoPaymentKind;
    result[kind] = (result[kind] ?? 0) + t.amount;
  }
  return result;
}

/// Porcentajes enteros que suman exactamente 100 (método del mayor resto):
/// redondear cada uno por separado puede dar 99 o 101. Vacío si el total
/// es 0.
Map<K, int> percentagesOf<K>(Map<K, int> amounts) {
  final total = amounts.values.fold<int>(0, (a, b) => a + b);
  if (total <= 0) return {};
  final floors = {
    for (final e in amounts.entries) e.key: e.value * 100 ~/ total,
  };
  var missing = 100 - floors.values.fold<int>(0, (a, b) => a + b);
  final byRemainder = amounts.keys.toList()
    ..sort((a, b) =>
        ((amounts[b]! * 100) % total).compareTo((amounts[a]! * 100) % total));
  for (final key in byRemainder) {
    if (missing == 0) break;
    floors[key] = floors[key]! + 1;
    missing--;
  }
  return floors;
}

/// RF42: deuda en cuotas de cada tarjeta: las cuotas desde el mes siguiente
/// a [currentMonth] (las de este mes ya cuentan en el gasto del mes, igual
/// que en RF36).
Map<int, int> installmentDebtByCard(
    Iterable<Transaction> installmentTransactions, DateTime currentMonth) {
  final from = DateTime(currentMonth.year, currentMonth.month + 1);
  final result = <int, int>{};
  for (final t in installmentTransactions) {
    final card = t.paymentMethodId;
    if (card == null || t.installmentNumber == null || t.date.isBefore(from)) {
      continue;
    }
    result[card] = (result[card] ?? 0) + t.amount;
  }
  return result;
}

/// RF43: estado de cuenta estimado de [card] para el período en curso a
/// [today]: suma las compras y cuotas con esa tarjeta dentro del período.
/// Null si la tarjeta no tiene día de facturación (RF33).
({BillingPeriod period, int amount})? estimatedStatement(
    PaymentMethod card, Iterable<Transaction> transactions, DateTime today) {
  final billingDay = card.billingDay;
  if (billingDay == null) return null;
  final period =
      billingPeriodFor(today, billingDay: billingDay, dueDay: card.dueDay);
  final amount = transactions
      .where((t) => t.paymentMethodId == card.id && period.contains(t.date))
      .fold<int>(0, (a, t) => a + t.amount);
  return (period: period, amount: amount);
}
