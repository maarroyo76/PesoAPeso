import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/category_icons.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/ledger_paper.dart';
import '../../core/widgets/month_selector.dart';
import '../../core/widgets/section_label.dart';
import '../../data/local/app_database.dart';
import 'transaction_detail_sheet.dart';

class ResumenScreen extends ConsumerStatefulWidget {
  const ResumenScreen({super.key});

  @override
  ConsumerState<ResumenScreen> createState() => _ResumenScreenState();
}

class _ResumenScreenState extends ConsumerState<ResumenScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _prev() =>
      setState(() => _month = DateTime(_month.year, _month.month - 1));

  void _next() {
    final next = DateTime(_month.year, _month.month + 1);
    final now = DateTime.now();
    if (!next.isAfter(DateTime(now.year, now.month))) {
      setState(() => _month = next);
    }
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final txAsync = ref.watch(monthTransactionsProvider(_month));
    final budgets = ref.watch(monthBudgetsProvider(_month));
    final totalBudget = ref.watch(monthTotalBudgetProvider(_month));
    final prevMonth = DateTime(_month.year, _month.month - 1);
    final prevTxAsync = ref.watch(monthTransactionsProvider(prevMonth));
    final prevSpent =
        prevTxAsync.valueOrNull?.fold<int>(0, (a, t) => a + t.amount);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (categories) => txAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (transactions) => _buildContent(
            categories, transactions, budgets, totalBudget, prevSpent),
      ),
    );
  }

  Widget _buildContent(
      List<Category> categories,
      List<Transaction> transactions,
      Map<String, int> budgets,
      int totalBudget,
      int? prevSpent) {
    final categoriesById = {for (final c in categories) c.id: c};
    final spentByCategory = <String, int>{};
    for (final t in transactions) {
      spentByCategory[t.categoryId] =
          (spentByCategory[t.categoryId] ?? 0) + t.amount;
    }

    final totalSpent = spentByCategory.values.fold<int>(0, (a, b) => a + b);
    // RF04/RF05: `totalBudget` es el presupuesto TOTAL que el usuario fija
    // directamente (MonthlyBudgets) — ya NO es la suma de presupuestos por
    // categoría, esos son cosas distintas (ver PresupuestosScreen).
    final overallRatio =
        totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;

    final recentTx = [...transactions]
      ..sort((a, b) => b.date.compareTo(a.date));
    final recent = recentTx.take(5).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        MonthSelector(
          label: capitalizeMonth(_month, monthFmt),
          onPrev: _prev,
          onNext: _isCurrentMonth ? null : _next,
        ),
        const SizedBox(height: 20),
        _TotalCard(
          spent: totalSpent,
          budget: totalBudget,
          ratio: overallRatio,
          prevSpent: prevSpent,
        ),
        const SizedBox(height: 24),
        const SectionLabel('Por categoría'),
        const SizedBox(height: 12),
        ...categories.map((c) => _CategoryRow(
              category: c,
              spent: spentByCategory[c.id] ?? 0,
              budget: budgets[c.id] ?? 0,
              onTap: () => _showDetail(c, transactions),
            )),
        const SizedBox(height: 24),
        const SectionLabel('Últimos registros'),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Sin gastos registrados este mes.',
              style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
            ),
          )
        else
          ...recent.map((t) => _RecentTxRow(
                tx: t,
                category: categoriesById[t.categoryId]!,
                onTap: () =>
                    _showDetail(categoriesById[t.categoryId]!, transactions),
              )),
      ],
    );
  }

  void _showDetail(Category category, List<Transaction> allTransactions) {
    final catTx = allTransactions
        .where((t) => t.categoryId == category.id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => TransactionDetailSheet(
        category: category,
        transactions: catTx,
      ),
    );
  }
}

String _formatRecentDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final timeStr = DateFormat('HH:mm').format(date);
  if (day == today) return 'Hoy, $timeStr';
  if (day == today.subtract(const Duration(days: 1))) return 'Ayer, $timeStr';
  return '${DateFormat('d MMM', 'es_CL').format(date)}, $timeStr';
}

class _RecentTxRow extends StatelessWidget {
  const _RecentTxRow({
    required this.tx,
    required this.category,
    required this.onTap,
  });
  final Transaction tx;
  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 32,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(iconForCategory(category), size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.note.isNotEmpty ? tx.note : category.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        _formatRecentDate(tx.date),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.inkSoft),
                      ),
                      if (tx.isRecurring) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.repeat,
                            size: 11, color: AppColors.inkSoft),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              currencyFmt.format(tx.amount),
              style: appAmountTextStyle.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.spent,
    required this.budget,
    required this.ratio,
    required this.prevSpent,
  });
  final int spent;
  final int budget;
  final double ratio;
  final int? prevSpent;

  @override
  Widget build(BuildContext context) {
    final overBudget = spent > budget && budget > 0;
    final barColor = overBudget ? AppColors.rust : AppColors.green;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperDeep,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rule),
      ),
      child: RuledPaperBackground(
        borderRadius: 11,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('GASTO DEL MES',
                    style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        color: AppColors.inkSoft)),
                if (prevSpent != null && prevSpent! > 0)
                  _DeltaChip(spent: spent, prevSpent: prevSpent!),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                currencyFmt.format(spent),
                style: appAmountTextStyle.copyWith(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                  color: overBudget ? AppColors.rust : AppColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text('de ${currencyFmt.format(budget)} presupuestado',
                style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
            const SizedBox(height: 16),
            LedgerCuadreBar(ratio: ratio, color: barColor),
            if (budget > 0) ...[
              const SizedBox(height: 10),
              Text(
                overBudget
                    ? 'Excediste el presupuesto en ${currencyFmt.format(spent - budget)}'
                    : 'Saldo disponible del mes: ${currencyFmt.format(budget - spent)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: overBudget ? FontWeight.w400 : FontWeight.w600,
                  color: overBudget ? AppColors.rust : AppColors.green,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Variación del gasto total vs. el mes anterior — inspirado en los
/// indicadores de delta (▲/▼ + %) de las stat cards revisadas en 21st.dev
/// y Awwwards. Solo se muestra si el mes anterior tuvo gasto registrado,
/// para no calcular un porcentaje sin línea base.
class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.spent, required this.prevSpent});
  final int spent;
  final int prevSpent;

  @override
  Widget build(BuildContext context) {
    final diff = spent - prevSpent;
    final pct = (diff.abs() / prevSpent * 100).round();
    final isDown = diff <= 0;
    final color = isDown ? AppColors.green : AppColors.rust;

    if (diff == 0) {
      return const Text('Igual que el mes anterior',
          style: TextStyle(fontSize: 10, color: AppColors.inkSoft));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(isDown ? Icons.arrow_downward : Icons.arrow_upward,
            size: 11, color: color),
        const SizedBox(width: 2),
        Text('$pct% vs. mes anterior',
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.spent,
    required this.budget,
    required this.onTap,
  });
  final Category category;
  final int spent;
  final int budget;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);
    final ratio = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final overBudget = spent > budget;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              height: 42,
              margin: const EdgeInsets.only(right: 10, top: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(iconForCategory(category), size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(category.name,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(
                        currencyFmt.format(spent),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: overBudget ? AppColors.rust : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 5,
                      color: overBudget ? AppColors.rust : color,
                      backgroundColor: AppColors.rule,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text('Presupuesto: ${currencyFmt.format(budget)}',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.inkSoft)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}
