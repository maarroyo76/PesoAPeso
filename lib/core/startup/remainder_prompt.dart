import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/budget_resolver.dart';
import '../../core/utils/formatting.dart';

const _kLastOpenYearMonthKey = 'last_open_year_month';

/// RF15: al abrir la app en un mes distinto al de la última sesión, si el
/// mes anterior cerró con presupuesto sin gastar, pregunta una sola vez si
/// sumarlo al presupuesto del mes actual o aportarlo a una meta. Guarda el
/// mes ya revisado para no repetir el aviso.
Future<void> checkPreviousMonthRemainder(
    BuildContext context, WidgetRef ref) async {
  final settings = ref.read(settingsRepositoryProvider);
  final now = DateTime.now();
  final currentYm = now.year * 100 + now.month;

  final lastOpenStr = await settings.get(_kLastOpenYearMonthKey);
  final lastOpenYm = lastOpenStr == null ? null : int.tryParse(lastOpenStr);

  if (lastOpenYm != currentYm && lastOpenYm != null) {
    final prevMonth = DateTime(now.year, now.month - 1);
    // RF04/RF15: el remanente se calcula contra el presupuesto TOTAL que el
    // usuario fija directamente (MonthlyBudgets), no contra la suma de
    // presupuestos por categoría.
    final allMonthlyBudgets = await ref
        .read(categoriesRepositoryProvider)
        .watchAllMonthlyBudgets()
        .first;
    final totalBudgetPrev =
        resolveMonthlyBudgetForMonth(allMonthlyBudgets, prevMonth);
    final txPrev = await ref
        .read(transactionsRepositoryProvider)
        .watchTransactionsForMonth(prevMonth)
        .first;
    final totalSpentPrev = txPrev.fold<int>(0, (a, t) => a + t.amount);
    final remainder = totalBudgetPrev - totalSpentPrev;

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

  var targetKind = 'category';
  String? categoryId = categories.isNotEmpty ? categories.first.id : null;
  int? goalId = goals.isNotEmpty ? goals.first.id : null;
  if (categoryId == null) targetKind = 'goal';

  final apply = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: const Text('Presupuesto sin gastar',
            style: TextStyle(fontSize: 16, color: AppColors.ink)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${capitalizeMonth(prevMonth, monthFmt)} cerró con '
                '${currencyFmt.format(remainder)} sin gastar del presupuesto. '
                '¿Qué quieres hacer con ese saldo?',
                style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
              ),
              const SizedBox(height: 12),
              RadioGroup<String>(
                groupValue: targetKind,
                onChanged: (v) => setDialogState(() => targetKind = v!),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (categoryId != null)
                      const RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text('Sumar al presupuesto de una categoría'),
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
            child: const Text('Ignorar',
                style: TextStyle(color: AppColors.inkSoft)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
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

  if (targetKind == 'category' && categoryId != null) {
    final currentMonth = DateTime(now.year, now.month);
    final allBudgets =
        await ref.read(categoriesRepositoryProvider).watchAllBudgets().first;
    final currentBudgets = resolveBudgetsForMonth(allBudgets, currentMonth);
    final newAmount = (currentBudgets[categoryId] ?? 0) + remainder;
    await ref
        .read(categoriesRepositoryProvider)
        .setBudgetForMonth(categoryId!, currentMonth, newAmount);
  } else if (targetKind == 'goal' && goalId != null) {
    await ref.read(savingsRepositoryProvider).addContribution(
          goalId: goalId!,
          amount: remainder,
          date: now,
          note: 'Remanente de ${capitalizeMonth(prevMonth, monthFmt)}',
        );
  }
}
