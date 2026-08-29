import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'budget_resolver.dart';

/// RF18: información para el aviso inmediato en pantalla cuando un gasto
/// deja a una categoría en 80% o más de su presupuesto del mes.
class BudgetAlertInfo {
  const BudgetAlertInfo({
    required this.categoryName,
    required this.ratio,
  });

  final String categoryName;
  final double ratio;

  bool get isOverBudget => ratio >= 1.0;
}

/// Revisa el estado de [categoryId] en el mes de [date] DESPUÉS de un gasto
/// recién registrado. Devuelve null si no llegó al 80% (o si la categoría no
/// tiene presupuesto asignado ese mes).
Future<BudgetAlertInfo?> checkBudgetAlert(
  WidgetRef ref, {
  required String categoryId,
  required DateTime date,
}) async {
  final month = DateTime(date.year, date.month);
  final categories =
      await ref.read(categoriesRepositoryProvider).watchCategories().first;

  String? categoryName;
  for (final c in categories) {
    if (c.id == categoryId) {
      categoryName = c.name;
      break;
    }
  }
  if (categoryName == null) return null;

  final allBudgets =
      await ref.read(categoriesRepositoryProvider).watchAllBudgets().first;
  final budget = resolveBudgetsForMonth(allBudgets, month)[categoryId] ?? 0;
  if (budget <= 0) return null;

  final txs = await ref
      .read(transactionsRepositoryProvider)
      .watchTransactionsForMonth(month)
      .first;
  final spent = txs
      .where((t) => t.categoryId == categoryId)
      .fold<int>(0, (a, t) => a + t.amount);
  final ratio = spent / budget;
  if (ratio < 0.8) return null;

  return BudgetAlertInfo(categoryName: categoryName, ratio: ratio);
}

/// Muestra el aviso como un banner persistente (no una notificación del
/// sistema) en la parte superior del contenido.
void showBudgetAlertBanner(BuildContext context, BudgetAlertInfo info) {
  final messenger = ScaffoldMessenger.of(context);
  final pct = (info.ratio * 100).round();
  messenger.clearMaterialBanners();
  messenger.showMaterialBanner(
    MaterialBanner(
      backgroundColor: AppColors.rust.withValues(alpha: 0.12),
      leading: Icon(
        info.isOverBudget ? Icons.error_outline : Icons.warning_amber_outlined,
        color: AppColors.rust,
      ),
      content: Text(
        info.isOverBudget
            ? '${info.categoryName} superó su presupuesto del mes ($pct%).'
            : '${info.categoryName} llegó al $pct% de su presupuesto del mes.',
        style: const TextStyle(color: AppColors.ink, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: messenger.hideCurrentMaterialBanner,
          child: const Text('OK', style: TextStyle(color: AppColors.ink)),
        ),
      ],
    ),
  );
}
