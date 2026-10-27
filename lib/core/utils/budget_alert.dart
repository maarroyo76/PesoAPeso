import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/categories_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/transactions_repository.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'budget_resolver.dart';

/// RF18/RF55: información para el aviso inmediato en pantalla cuando un
/// gasto deja a una categoría, o al presupuesto total, en 80% o más.
class BudgetAlertInfo {
  const BudgetAlertInfo({
    required this.categoryName,
    required this.ratio,
  });

  /// null = presupuesto total del mes (RF55).
  final String? categoryName;
  final double ratio;

  bool get isTotal => categoryName == null;
  bool get isOverBudget => ratio >= 1.0;

  String get message {
    final pct = (ratio * 100).round();
    if (isTotal) {
      return isOverBudget
          ? 'Superaste tu presupuesto total del mes ($pct%).'
          : 'Llevas el $pct% de tu presupuesto total del mes.';
    }
    return isOverBudget
        ? '$categoryName superó su presupuesto del mes ($pct%).'
        : '$categoryName llegó al $pct% de su presupuesto del mes.';
  }
}

/// RF55: umbral del presupuesto total que corresponde avisar (80 o 100), o
/// null si no llegó al 80% o ese umbral ya se avisó este mes.
int? totalAlertThreshold({
  required int spent,
  required int budget,
  required int alreadyNotified,
}) {
  if (budget <= 0) return null;
  final ratio = spent / budget;
  final threshold = ratio >= 1 ? 100 : (ratio >= 0.8 ? 80 : null);
  if (threshold == null || threshold <= alreadyNotified) return null;
  return threshold;
}

/// Clave en AppSettings con el último umbral del total ya avisado en el mes.
String totalAlertSettingKey(DateTime month) =>
    'total_budget_alert_${month.year * 100 + month.month}';

/// RF55: revisa el presupuesto total del mes de [date] después de un gasto.
/// Cada umbral (80% y 100%) avisa una sola vez por mes: el umbral avisado
/// queda guardado en AppSettings.
Future<BudgetAlertInfo?> evaluateTotalBudgetAlert({
  required CategoriesRepository categories,
  required TransactionsRepository transactions,
  required SettingsRepository settings,
  required DateTime date,
}) async {
  final month = DateTime(date.year, date.month);
  final budget = withTotalAdjustments(
    resolveMonthlyBudgetForMonth(
        await categories.watchAllMonthlyBudgets().first, month),
    adjustmentsForMonth(await categories.watchAllAdjustments().first, month),
  );
  if (budget <= 0) return null;
  final spent = (await transactions.watchTransactionsForMonth(month).first)
      .fold<int>(0, (a, t) => a + t.amount);

  final key = totalAlertSettingKey(month);
  final notified = int.tryParse(await settings.get(key) ?? '') ?? 0;
  final threshold = totalAlertThreshold(
      spent: spent, budget: budget, alreadyNotified: notified);
  if (threshold == null) return null;
  await settings.set(key, '$threshold');
  return BudgetAlertInfo(categoryName: null, ratio: spent / budget);
}

/// Alertas que corresponden después de registrar o editar un gasto: la de
/// su categoría (RF18) y la del presupuesto total (RF55).
Future<List<BudgetAlertInfo>> checkBudgetAlerts(
  WidgetRef ref, {
  required String categoryId,
  required DateTime date,
}) async {
  final category =
      await checkBudgetAlert(ref, categoryId: categoryId, date: date);
  final total = await evaluateTotalBudgetAlert(
    categories: ref.read(categoriesRepositoryProvider),
    transactions: ref.read(transactionsRepositoryProvider),
    settings: ref.read(settingsRepositoryProvider),
    date: date,
  );
  return [if (category != null) category, if (total != null) total];
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

  final categoriesRepo = ref.read(categoriesRepositoryProvider);
  final allBudgets = await categoriesRepo.watchAllBudgets().first;
  final allAdjustments = await categoriesRepo.watchAllAdjustments().first;
  final budget = withCategoryAdjustments(
        resolveBudgetsForMonth(allBudgets, month),
        adjustmentsForMonth(allAdjustments, month),
      )[categoryId] ??
      0;
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

/// Muestra los avisos como un banner persistente (no una notificación del
/// sistema) en la parte superior del contenido. Nada si [alerts] está vacía.
void showBudgetAlertBanner(BuildContext context, List<BudgetAlertInfo> alerts) {
  if (alerts.isEmpty) return;
  final messenger = ScaffoldMessenger.of(context);
  final over = alerts.any((a) => a.isOverBudget);
  messenger.clearMaterialBanners();
  messenger.showMaterialBanner(
    MaterialBanner(
      backgroundColor: context.colors.rust.withValues(alpha: 0.12),
      leading: Icon(
        over ? Icons.error_outline : Icons.warning_amber_outlined,
        color: context.colors.rust,
      ),
      content: Text(
        alerts.map((a) => a.message).join('\n'),
        style: TextStyle(color: context.colors.ink, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: messenger.hideCurrentMaterialBanner,
          child: Text('OK', style: TextStyle(color: context.colors.ink)),
        ),
      ],
    ),
  );
}
