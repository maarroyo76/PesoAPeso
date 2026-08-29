import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/category_icons.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/ledger_paper.dart';
import '../../core/widgets/section_label.dart';
import '../../data/local/app_database.dart';

class PresupuestosScreen extends ConsumerWidget {
  const PresupuestosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final categoriesAsync = ref.watch(categoriesProvider);
    final txAsync = ref.watch(monthTransactionsProvider(month));
    final budgets = ref.watch(monthBudgetsProvider(month));
    final totalBudget = ref.watch(monthTotalBudgetProvider(month));

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (categories) => txAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (transactions) => _buildContent(context, ref, categories,
            transactions, budgets, totalBudget, month),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories,
    List<Transaction> transactions,
    Map<String, int> budgets,
    int totalBudget,
    DateTime month,
  ) {
    final spentByCategory = <String, int>{};
    for (final t in transactions) {
      spentByCategory[t.categoryId] =
          (spentByCategory[t.categoryId] ?? 0) + t.amount;
    }
    // RF04 (corrección): `totalBudget` es el total que el usuario fija
    // directamente (MonthlyBudgets) — `assignedToCategories` es la suma de
    // los presupuestos por categoría, un número distinto y derivado.
    final assignedToCategories =
        categories.fold<int>(0, (a, c) => a + (budgets[c.id] ?? 0));
    final totalSpent = spentByCategory.values.fold<int>(0, (a, b) => a + b);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        _Header(
            totalBudget: totalBudget,
            assignedToCategories: assignedToCategories,
            totalSpent: totalSpent,
            monthLabel: capitalizeMonth(month, monthFmt),
            onEdit: () =>
                _showEditTotalDialog(context, ref, totalBudget, month)),
        const SizedBox(height: 24),
        const SectionLabel('Presupuesto por categoría'),
        const SizedBox(height: 12),
        ...categories.map(
          (c) => _BudgetRow(
            category: c,
            spent: spentByCategory[c.id] ?? 0,
            budget: budgets[c.id] ?? 0,
            onEdit: () =>
                _showEditDialog(context, ref, c, budgets[c.id] ?? 0, month),
          ),
        ),
      ],
    );
  }

  Future<void> _showEditTotalDialog(BuildContext context, WidgetRef ref,
      int currentTotal, DateTime month) async {
    final controller = TextEditingController(text: currentTotal.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: const Text(
          'Presupuesto total del mes',
          style: TextStyle(fontSize: 16, color: AppColors.ink),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            prefixText: '\$ ',
            border: UnderlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.inkSoft)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val >= 0) Navigator.pop(ctx, val);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null) {
      await ref
          .read(categoriesRepositoryProvider)
          .setMonthlyBudgetForMonth(month, result);
    }
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref,
      Category category, int currentBudget, DateTime month) async {
    final controller = TextEditingController(text: currentBudget.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text(
          'Presupuesto – ${category.name}',
          style: const TextStyle(fontSize: 16, color: AppColors.ink),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            prefixText: '\$ ',
            border: UnderlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.inkSoft)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val >= 0) Navigator.pop(ctx, val);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null) {
      await ref
          .read(categoriesRepositoryProvider)
          .setBudgetForMonth(category.id, month, result);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.totalBudget,
    required this.assignedToCategories,
    required this.totalSpent,
    required this.monthLabel,
    required this.onEdit,
  });
  final int totalBudget;
  final int assignedToCategories;
  final int totalSpent;
  final String monthLabel;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final overSpent = totalSpent > totalBudget && totalBudget > 0;
    // RF04 (corrección): sobre-asignación es cuando lo asignado a categorías
    // supera el total fijado por el usuario — distinto de sobre-gasto.
    final overAllocated = totalBudget > 0 && assignedToCategories > totalBudget;
    final reserve = totalBudget - assignedToCategories;
    final spentRatio =
        totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;
    final barColor = overSpent ? AppColors.rust : AppColors.green;

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.paperDeep,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: overAllocated ? AppColors.rust : AppColors.rule),
        ),
        child: RuledPaperBackground(
          borderRadius: 11,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        overAllocated
                            ? Icons.warning_amber_outlined
                            : Icons.account_balance_wallet_outlined,
                        color: overAllocated ? AppColors.rust : AppColors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      const Text('PRESUPUESTO TOTAL',
                          style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.2,
                              color: AppColors.inkSoft)),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.rule.withAlpha(80),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(monthLabel,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.inkSoft)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        currencyFmt.format(totalBudget),
                        style: appAmountTextStyle.copyWith(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.edit_outlined,
                      size: 14, color: AppColors.inkSoft),
                ],
              ),
              Text(
                'Gastado: ${currencyFmt.format(totalSpent)}',
                style: TextStyle(
                    fontSize: 12,
                    color: overSpent ? AppColors.rust : AppColors.inkSoft),
              ),
              const SizedBox(height: 14),
              LedgerCuadreBar(ratio: spentRatio, color: barColor),
              const SizedBox(height: 10),
              Text(
                'Asignado a categorías: ${currencyFmt.format(assignedToCategories)}',
                style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
              ),
              Text(
                overAllocated
                    ? 'Sobre-asignado en ${currencyFmt.format(-reserve)}: las categorías suman más que el total.'
                    : 'Reserva sin asignar: ${currencyFmt.format(reserve)}',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        overAllocated ? FontWeight.w600 : FontWeight.w400,
                    color: overAllocated ? AppColors.rust : AppColors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
    required this.category,
    required this.spent,
    required this.budget,
    required this.onEdit,
  });
  final Category category;
  final int spent;
  final int budget;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);
    final ratio = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final overBudget = spent > budget;
    final remaining = budget - spent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.paperDeep,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: overBudget ? AppColors.rust : AppColors.rule),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 18,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Icon(iconForCategory(category), size: 18, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(category.name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(currencyFmt.format(budget),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink)),
                      const Text('presupuesto',
                          style: TextStyle(
                              fontSize: 10, color: AppColors.inkSoft)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.edit_outlined,
                      size: 16, color: AppColors.inkSoft),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 5,
                  color: overBudget ? AppColors.rust : color,
                  backgroundColor: AppColors.rule,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Gastado: ${currencyFmt.format(spent)}',
                      style: TextStyle(
                          fontSize: 11,
                          color:
                              overBudget ? AppColors.rust : AppColors.inkSoft)),
                  Text(
                    overBudget
                        ? 'Excedido: ${currencyFmt.format(-remaining)}'
                        : 'Disponible: ${currencyFmt.format(remaining)}',
                    style: TextStyle(
                        fontSize: 11,
                        color: overBudget ? AppColors.rust : AppColors.inkSoft),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
