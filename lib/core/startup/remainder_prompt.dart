import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/budget_resolver.dart';
import '../../core/utils/daily_allowance.dart';
import '../../core/utils/formatting.dart';
import '../../data/repositories/categories_repository.dart';
import '../../data/repositories/savings_repository.dart';
import '../../data/repositories/transactions_repository.dart';

const _kLastOpenYearMonthKey = 'last_open_year_month';

/// Mes cuyo remanente corresponde evaluar: el último mes en que la app se
/// abrió (yyyyMM), siempre que sea anterior al actual. Usar el mes calendario
/// previo fallaría si el usuario estuvo meses sin abrir la app: ese mes no
/// tiene gastos y todo su presupuesto parecería "sin gastar".
DateTime? remainderMonthFor(int? lastOpenYm, int currentYm) {
  if (lastOpenYm == null || lastOpenYm >= currentYm) return null;
  final year = lastOpenYm ~/ 100;
  final month = lastOpenYm % 100;
  if (month < 1 || month > 12) return null;
  return DateTime(year, month);
}

/// Lo que quedó libre del presupuesto de [month]. RF04/RF15: se calcula
/// contra el presupuesto TOTAL que el usuario fija directamente
/// (MonthlyBudgets), no contra la suma de presupuestos por categoría.
/// RF51 (corrige I2): los aportes a metas del mes también salen del
/// presupuesto, aunque no sean gasto de ninguna categoría.
Future<int> monthRemainder({
  required CategoriesRepository categories,
  required TransactionsRepository transactions,
  required SavingsRepository savings,
  required DateTime month,
}) async {
  final budget = withTotalAdjustments(
    resolveMonthlyBudgetForMonth(
        await categories.watchAllMonthlyBudgets().first, month),
    adjustmentsForMonth(await categories.watchAllAdjustments().first, month),
  );
  final spent = (await transactions.watchTransactionsForMonth(month).first)
      .fold<int>(0, (a, t) => a + t.amount);
  return availableThisMonth(
    budget: budget,
    spent: spent,
    saved: await savings.totalContributedInMonth(month),
  );
}

/// RF15: al abrir la app en un mes distinto al de la última sesión, si el
/// mes anterior cerró con presupuesto sin gastar, pregunta una sola vez si
/// sumarlo al presupuesto del mes actual (total o de una categoría) o
/// aportarlo a una meta. Guarda el mes ya revisado para no repetir el aviso.
///
/// RF50 (corrige I1): sumarlo al presupuesto crea un ajuste que vale solo
/// para el mes actual. Antes se escribía en la fila de presupuesto del mes,
/// que se hereda, y el remanente quedaba sumado en todos los meses siguientes.
Future<void> checkPreviousMonthRemainder(
    BuildContext context, WidgetRef ref) async {
  final settings = ref.read(settingsRepositoryProvider);
  final now = DateTime.now();
  final currentYm = now.year * 100 + now.month;

  final lastOpenStr = await settings.get(_kLastOpenYearMonthKey);
  final lastOpenYm = lastOpenStr == null ? null : int.tryParse(lastOpenStr);

  final prevMonth = remainderMonthFor(lastOpenYm, currentYm);
  if (prevMonth != null) {
    final remainder = await monthRemainder(
      categories: ref.read(categoriesRepositoryProvider),
      transactions: ref.read(transactionsRepositoryProvider),
      savings: ref.read(savingsRepositoryProvider),
      month: prevMonth,
    );

    if (remainder > 0 && context.mounted) {
      await _showRemainderDialog(context, ref,
          remainder: remainder, prevMonth: prevMonth, now: now);
    }
  }

  await settings.set(_kLastOpenYearMonthKey, currentYm.toString());
}

Future<void> _showRemainderDialog(
  BuildContext context,
  WidgetRef ref, {
  required int remainder,
  required DateTime prevMonth,
  required DateTime now,
}) async {
  final categories =
      await ref.read(categoriesRepositoryProvider).watchCategories().first;
  final goals = await ref.read(savingsRepositoryProvider).watchGoals().first;
  if (!context.mounted) return;

  var targetKind = 'total';
  String? categoryId = categories.isNotEmpty ? categories.first.id : null;
  int? goalId = goals.isNotEmpty ? goals.first.id : null;

  final apply = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: context.colors.paper,
        title: Text('Presupuesto sin gastar',
            style: TextStyle(fontSize: 16, color: context.colors.ink)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${capitalizeMonth(prevMonth, monthFmt)} cerró con '
                '${currencyFmt.format(remainder)} sin gastar del presupuesto. '
                '¿Qué quieres hacer con ese saldo?',
                style: TextStyle(color: context.colors.inkSoft, fontSize: 13),
              ),
              const SizedBox(height: 12),
              RadioGroup<String>(
                groupValue: targetKind,
                onChanged: (v) => setDialogState(() => targetKind = v!),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text('Sumar al presupuesto total de este mes'),
                      value: 'total',
                    ),
                    if (categoryId != null)
                      const RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text('Sumar a una categoría, solo este mes'),
                        value: 'category',
                      ),
                    if (goalId != null)
                      const RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text('Aportar a una meta de ahorro'),
                        value: 'goal',
                      ),
                  ],
                ),
              ),
              if (categoryId != null && targetKind == 'category')
                DropdownButton<String>(
                  value: categoryId,
                  isExpanded: true,
                  items: categories
                      .map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => categoryId = v),
                ),
              if (goalId != null && targetKind == 'goal')
                DropdownButton<int>(
                  value: goalId,
                  isExpanded: true,
                  items: goals
                      .map((g) =>
                          DropdownMenuItem(value: g.id, child: Text(g.name)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => goalId = v),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Ignorar',
                style: TextStyle(color: context.colors.inkSoft)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.colors.ink),
            onPressed: (targetKind == 'category' && categoryId == null) ||
                    (targetKind == 'goal' && goalId == null)
                ? null
                : () => Navigator.pop(ctx, true),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    ),
  );

  if (apply != true) return;

  final reason = 'Remanente de ${capitalizeMonth(prevMonth, monthFmt)}';
  if (targetKind == 'total' ||
      (targetKind == 'category' && categoryId != null)) {
    await ref.read(categoriesRepositoryProvider).addAdjustment(
          month: DateTime(now.year, now.month),
          categoryId: targetKind == 'category' ? categoryId : null,
          amount: remainder,
          reason: reason,
        );
  } else if (targetKind == 'goal' && goalId != null) {
    // El aporte va al último día del mes del remanente, no al actual: esa
    // plata ya era de ese mes y no debe descontarse del presupuesto de este
    // (RF51).
    await ref.read(savingsRepositoryProvider).addContribution(
          goalId: goalId!,
          amount: remainder,
          date: DateTime(prevMonth.year, prevMonth.month + 1, 0),
          note: reason,
        );
  }
}
