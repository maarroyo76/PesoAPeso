import 'package:flutter/material.dart';

import '../../data/local/app_database.dart';

/// Nombre visible de cada tipo de método de pago (RF31).
String paymentKindLabel(String kind) => switch (kind) {
      kPaymentKindCash => 'Efectivo',
      kPaymentKindDebit => 'Débito',
      kPaymentKindCredit => 'Crédito',
      _ => kind,
    };

IconData paymentKindIcon(String kind) => switch (kind) {
      kPaymentKindCash => Icons.payments_outlined,
      kPaymentKindCredit => Icons.credit_card,
      _ => Icons.account_balance_outlined,
    };

/// Texto de un gasto sin método: los anteriores a v10 y los no asignados.
const kNoPaymentMethodLabel = 'Sin especificar';

/// "CMR ···· 1234", o solo el alias si no tiene dígitos.
String paymentMethodLabel(PaymentMethod method) => method.last4 == null
    ? method.alias
    : '${method.alias} ···· ${method.last4}';

/// RF32: etiqueta del método de un gasto para los listados, o null si no
/// tiene (o el método ya no existe): ahí no se muestra nada.
String? transactionPaymentLabel(
        Transaction tx, Map<int, PaymentMethod> methodsById) =>
    tx.fundedByGoalId != null
        ? kFundedBySavingsLabel
        : switch (tx.paymentMethodId) {
            final id? when methodsById.containsKey(id) =>
              paymentMethodLabel(methodsById[id]!),
            _ => null,
          };

/// RF52: etiqueta de un gasto pagado con el ahorro de una meta.
const kFundedBySavingsLabel = 'Pagado con ahorro';

/// Mapa id → método a partir de la lista del provider.
Map<int, PaymentMethod> paymentMethodsById(List<PaymentMethod>? methods) =>
    {for (final m in methods ?? const <PaymentMethod>[]) m.id: m};
