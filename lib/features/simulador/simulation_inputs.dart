import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/utils/formatting.dart';
import '../../core/utils/projection.dart';
import '../../core/utils/purchase_simulation.dart';

/// RF58: simula [option] comprada en [today] con los datos actuales de la
/// base. Null mientras algún dato no termina de cargar.
Projection? simulateWithCurrentData(
    WidgetRef ref, PurchaseOption option, DateTime today) {
  final transactions = ref.watch(allTransactionsProvider).valueOrNull;
  final templates = ref.watch(recurringTemplatesProvider).valueOrNull;
  final budgets = ref.watch(monthlyBudgetsProvider).valueOrNull;
  final adjustments = ref.watch(monthlyAdjustmentsProvider).valueOrNull;
  final saved = ref.watch(monthContributedProvider(monthOf(today)));
  if (transactions == null ||
      templates == null ||
      budgets == null ||
      adjustments == null ||
      !saved.hasValue) {
    return null;
  }
  return simulatePurchase(
    today: today,
    purchaseDate: today,
    installmentAmounts: option.amounts,
    transactions: transactions,
    templates: templates,
    monthlyBudgets: budgets,
    adjustments: adjustments,
    savedThisMonth: saved.value!,
  );
}

/// Una línea que dice si la compra alcanza en los meses que abarca.
String outcomeLabel(Projection projection) {
  if (projection.basis == ProjectionBasis.none) {
    return 'Define un presupuesto total para saber si te alcanza.';
  }
  final (:monthsBelowZero, :worstShortfall) = projectionOutcome(projection);
  if (monthsBelowZero == 0) return 'Alcanza';
  return '$monthsBelowZero ${monthsBelowZero == 1 ? 'mes' : 'meses'} sin '
      'alcanzar · faltan hasta ${currencyFmt.format(worstShortfall)}';
}
