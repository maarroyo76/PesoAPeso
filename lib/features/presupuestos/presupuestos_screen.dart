import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/category_icons.dart';
import '../../core/utils/amount_input.dart';
import '../../core/utils/daily_allowance.dart';
import '../../core/utils/formatting.dart';
import '../../core/utils/installments.dart';
import '../../core/widgets/ledger_paper.dart';
import '../../core/widgets/section_label.dart';
import '../../core/widgets/load_error.dart';
import '../../data/local/app_database.dart';
import '../cuotas/cuotas_screen.dart';

class PresupuestosScreen extends ConsumerWidget {
  const PresupuestosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(currentMonthProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final txAsync = ref.watch(monthTransactionsProvider(month));
    final budgets = ref.watch(monthBudgetsProvider(month));
    final totalBudget = ref.watch(monthTotalBudgetProvider(month));
    final baseBudgets = ref.watch(monthBaseBudgetsProvider(month));
    final baseTotal = ref.watch(monthBaseTotalBudgetProvider(month));
    final adjustments = ref.watch(monthAdjustmentsProvider(month));

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => LoadError(e),
      data: (categories) => txAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => LoadError(e),
        data: (transactions) => _buildContent(
          context,
          ref,
          categories,
          transactions,
          budgets: budgets,
          totalBudget: totalBudget,
          baseBudgets: baseBudgets,
          baseTotal: baseTotal,
          adjustments: adjustments,
          month: month,
        ),
      ),
    );
  }

  /// [budgets] y [totalBudget] incluyen los ajustes de un solo mes (RF50) y
  /// son los que se muestran; los diálogos de edición parten de los valores
  /// base, para que guardar no convierta un ajuste en permanente (I1).
  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories,
    List<Transaction> transactions, {
    required Map<String, int> budgets,
    required int totalBudget,
    required Map<String, int> baseBudgets,
    required int baseTotal,
    required List<MonthlyAdjustment> adjustments,
    required DateTime month,
  }) {
    final spentByCategory = <String, int>{};
    // RF52: lo pagado con ahorro no consume el presupuesto.
    for (final t in transactions.where(countsAgainstBudget)) {
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
            onEdit: () => _showEditTotalDialog(context, ref, baseTotal, month)),
        if (adjustments.isNotEmpty) ...[
          const SizedBox(height: 16),
          const SectionLabel('Ajustes de este mes'),
          const SizedBox(height: 4),
          for (final a in adjustments)
            _AdjustmentRow(
              adjustment: a,
              categoryName: _categoryName(categories, a.categoryId),
              onDelete: () => _confirmDeleteAdjustment(context, ref, a),
            ),
        ],
        const _CommittedInstallments(),
        const SizedBox(height: 24),
        const SectionLabel('Presupuesto por categoría'),
        const SizedBox(height: 12),
        // RF53: una archivada solo aparece en un mes donde tuvo gasto o
        // presupuesto, para que ese mes siga cuadrando.
        ...categories
            .where((c) =>
                !c.archived ||
                (spentByCategory[c.id] ?? 0) > 0 ||
                (budgets[c.id] ?? 0) > 0)
            .map(
              (c) => _BudgetRow(
                category: c,
                spent: spentByCategory[c.id] ?? 0,
                budget: budgets[c.id] ?? 0,
                adjustment: (budgets[c.id] ?? 0) - (baseBudgets[c.id] ?? 0),
                onEdit: () => _showEditDialog(
                    context, ref, c, baseBudgets[c.id] ?? 0, month),
              ),
            ),
      ],
    );
  }

  static String _categoryName(List<Category> categories, String? id) {
    if (id == null) return 'Presupuesto total';
    for (final c in categories) {
      if (c.id == id) return c.name;
    }
    return 'Presupuesto total';
  }

  Future<void> _confirmDeleteAdjustment(
      BuildContext context, WidgetRef ref, MonthlyAdjustment adjustment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.paper,
        title: Text('Quitar ajuste',
            style: TextStyle(fontSize: 16, color: context.colors.ink)),
        content: Text(
          'El presupuesto de este mes bajará en '
          '${currencyFmt.format(adjustment.amount)}.',
          style: TextStyle(color: context.colors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TextStyle(color: context.colors.inkSoft)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.colors.rust),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(categoriesRepositoryProvider)
          .deleteAdjustment(adjustment.id);
    }
  }

  Future<void> _showEditTotalDialog(BuildContext context, WidgetRef ref,
      int currentTotal, DateTime month) async {
    final controller =
        TextEditingController(text: formatAmountInput(currentTotal));

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.paper,
        title: Text(
          'Presupuesto total del mes',
          style: TextStyle(fontSize: 16, color: context.colors.ink),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: amountInputFormatters,
          decoration: const InputDecoration(
            prefixText: '\$ ',
            border: UnderlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: TextStyle(color: context.colors.inkSoft)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.colors.ink),
            onPressed: () {
              final val = parseAmountText(controller.text);
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
    final controller =
        TextEditingController(text: formatAmountInput(currentBudget));

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.paper,
        title: Text(
          'Presupuesto – ${category.name}',
          style: TextStyle(fontSize: 16, color: context.colors.ink),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: amountInputFormatters,
          decoration: const InputDecoration(
            prefixText: '\$ ',
            border: UnderlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: TextStyle(color: context.colors.inkSoft)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.colors.ink),
            onPressed: () {
              final val = parseAmountText(controller.text);
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
    final barColor = overSpent ? context.colors.rust : context.colors.green;

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.paperDeep,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: overAllocated ? context.colors.rust : context.colors.rule),
        ),
        child: RuledPaperBackground(
          borderRadius: 11,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wrap: con letra grande el mes pasa a la línea siguiente.
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        overAllocated
                            ? Icons.warning_amber_outlined
                            : Icons.account_balance_wallet_outlined,
                        color: overAllocated
                            ? context.colors.rust
                            : context.colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text('PRESUPUESTO TOTAL',
                            style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1.2,
                                color: context.colors.inkSoft)),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.colors.rule.withAlpha(80),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(monthLabel,
                        style: TextStyle(
                            fontSize: 11, color: context.colors.inkSoft)),
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
                          color: context.colors.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.edit_outlined,
                      size: 14, color: context.colors.inkSoft),
                ],
              ),
              Text(
                'Gastado: ${currencyFmt.format(totalSpent)}',
                style: TextStyle(
                    fontSize: 12,
                    color: overSpent
                        ? context.colors.rust
                        : context.colors.inkSoft),
              ),
              const SizedBox(height: 14),
              LedgerCuadreBar(
                ratio: spentRatio,
                color: barColor,
                semanticsLabel: 'Presupuesto total',
                semanticsValue: budgetUsageSemantics(totalSpent, totalBudget),
              ),
              const SizedBox(height: 10),
              Text(
                'Asignado a categorías: ${currencyFmt.format(assignedToCategories)}',
                style: TextStyle(fontSize: 11, color: context.colors.inkSoft),
              ),
              Text(
                overAllocated
                    ? 'Sobre-asignado en ${currencyFmt.format(-reserve)}: las categorías suman más que el total.'
                    : 'Reserva sin asignar: ${currencyFmt.format(reserve)}',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        overAllocated ? FontWeight.w600 : FontWeight.w400,
                    color: overAllocated
                        ? context.colors.rust
                        : context.colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdjustmentRow extends StatelessWidget {
  const _AdjustmentRow({
    required this.adjustment,
    required this.categoryName,
    required this.onDelete,
  });
  final MonthlyAdjustment adjustment;
  final String categoryName;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '+${currencyFmt.format(adjustment.amount)} · $categoryName',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              if (adjustment.reason.isNotEmpty)
                Text(adjustment.reason,
                    style:
                        TextStyle(fontSize: 11, color: context.colors.inkSoft)),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, size: 18, color: context.colors.inkSoft),
          tooltip: 'Quitar ajuste',
          onPressed: onDelete,
        ),
      ],
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
    required this.category,
    required this.spent,
    required this.budget,
    required this.adjustment,
    required this.onEdit,
  });
  final Category category;
  final int spent;

  /// Presupuesto vigente del mes, ya con [adjustment] incluido.
  final int budget;

  /// Parte de [budget] que viene de ajustes de este mes (RF50).
  final int adjustment;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.category(category.colorValue);
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
            color: context.colors.paperDeep,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: overBudget ? context.colors.rust : context.colors.rule),
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
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: context.colors.ink)),
                      Text(
                          adjustment > 0
                              ? 'incluye +${currencyFmt.format(adjustment)} '
                                  'este mes'
                              : 'presupuesto',
                          style: TextStyle(
                              fontSize: 11, color: context.colors.inkSoft)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.edit_outlined,
                      size: 16, color: context.colors.inkSoft),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: ratio,
                  // El valor de una barra de progreso debe ser numérico (lo calcula
                  // la barra); la descripción va en la etiqueta.
                  semanticsLabel: 'Presupuesto de ${category.name}: '
                      '${budgetUsageSemantics(spent, budget)}',
                  minHeight: 5,
                  color: overBudget ? context.colors.rust : color,
                  backgroundColor: context.colors.rule,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 8,
                runSpacing: 2,
                children: [
                  Text('Gastado: ${currencyFmt.format(spent)}',
                      style: TextStyle(
                          fontSize: 11,
                          color: overBudget
                              ? context.colors.rust
                              : context.colors.inkSoft)),
                  Text(
                    overBudget
                        ? 'Excedido: ${currencyFmt.format(-remaining)}'
                        : 'Disponible: ${currencyFmt.format(remaining)}',
                    style: TextStyle(
                        fontSize: 11,
                        color: overBudget
                            ? context.colors.rust
                            : context.colors.inkSoft),
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

/// RF36: cuánto del presupuesto de los meses siguientes ya está
/// comprometido en cuotas. Nada si no hay cuotas futuras.
class _CommittedInstallments extends ConsumerWidget {
  const _CommittedInstallments();

  /// Meses que se muestran; el resto se suma en una sola línea.
  static const _visibleMonths = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(currentMonthProvider);
    final txs = ref.watch(installmentTransactionsProvider).valueOrNull ?? [];
    final byMonth = committedByMonth(txs.map((t) => (t.date, t.amount)), month);
    if (byMonth.isEmpty) return const SizedBox.shrink();
    final entries = byMonth.entries.toList();
    final rest =
        entries.skip(_visibleMonths).fold<int>(0, (a, e) => a + e.value);

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Comprometido en cuotas',
              info: 'Cuotas de compras con tarjeta de crédito que caen en los '
                  'próximos meses. Ya cuentan como gasto de esos meses.'),
          const SizedBox(height: 8),
          for (final e in entries.take(_visibleMonths))
            _CommittedRow(
              label: capitalizeMonth(e.key, monthFmt),
              amount: e.value,
              budget: ref.watch(monthTotalBudgetProvider(e.key)),
            ),
          if (rest > 0)
            _CommittedRow(label: 'Meses siguientes', amount: rest, budget: 0),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: context.colors.ink,
                  padding: EdgeInsets.zero),
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CuotasScreen())),
              child: const Text('Ver compras en cuotas'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommittedRow extends StatelessWidget {
  const _CommittedRow(
      {required this.label, required this.amount, required this.budget});
  final String label;
  final int amount;

  /// Presupuesto total de ese mes; 0 = no se muestra el porcentaje.
  final int budget;

  @override
  Widget build(BuildContext context) {
    final pct = budget > 0 ? ' · ${(amount / budget * 100).round()}%' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 13, color: context.colors.ink)),
          ),
          Text(
            '${currencyFmt.format(amount)}$pct',
            style: appAmountTextStyle.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.colors.ink),
          ),
        ],
      ),
    );
  }
}
