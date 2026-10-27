import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/category_icons.dart';
import '../../core/utils/daily_allowance.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/ledger_paper.dart';
import '../../core/widgets/month_selector.dart';
import '../../core/widgets/month_swipe.dart';
import '../../core/widgets/section_label.dart';
import '../../core/widgets/load_error.dart';
import '../../data/local/app_database.dart';
import '../metodos_pago/payment_method_labels.dart';
import 'transaction_detail_sheet.dart';

class ResumenScreen extends ConsumerStatefulWidget {
  const ResumenScreen({super.key});

  @override
  ConsumerState<ResumenScreen> createState() => _ResumenScreenState();
}

class _ResumenScreenState extends ConsumerState<ResumenScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  static const _hintSeenKey = 'swipe_month_hint_seen';
  static const _hintDuration = Duration(seconds: 8);

  /// null = todavía no se sabe (se lee de ajustes), true = mostrar la pista.
  bool? _showHint;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    _loadHint();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  /// La pista de "desliza para cambiar de mes" se muestra una sola vez: se
  /// oculta al primer cambio de mes (con swipe o con las flechas) o a los 8
  /// segundos, y queda registrada para no volver a salir.
  Future<void> _loadHint() async {
    final seen = await ref.read(settingsRepositoryProvider).get(_hintSeenKey);
    if (!mounted || seen == 'true') return;
    setState(() => _showHint = true);
    _hintTimer = Timer(_hintDuration, _dismissHint);
  }

  void _dismissHint() {
    _hintTimer?.cancel();
    if (_showHint != true) return;
    if (mounted) setState(() => _showHint = false);
    ref.read(settingsRepositoryProvider).set(_hintSeenKey, 'true');
  }

  void _prev() {
    _dismissHint();
    setState(() => _month = DateTime(_month.year, _month.month - 1));
  }

  void _next() {
    final next = DateTime(_month.year, _month.month + 1);
    final now = DateTime.now();
    if (!next.isAfter(DateTime(now.year, now.month))) {
      _dismissHint();
      setState(() => _month = next);
    }
  }

  void _goToCurrentMonth() {
    final now = DateTime.now();
    _dismissHint();
    setState(() => _month = DateTime(now.year, now.month));
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    // Si la app cruza el cambio de mes con esta pantalla en el mes en curso,
    // salta al nuevo mes en vez de quedarse en el anterior.
    ref.listen<DateTime>(currentMonthProvider, (prev, next) {
      if (prev != null && _month == prev) setState(() => _month = next);
    });

    final categoriesAsync = ref.watch(categoriesProvider);
    final txAsync = ref.watch(monthTransactionsProvider(_month));
    final budgets = ref.watch(monthBudgetsProvider(_month));
    final totalBudget = ref.watch(monthTotalBudgetProvider(_month));
    final prevMonth = DateTime(_month.year, _month.month - 1);
    final prevTxAsync = ref.watch(monthTransactionsProvider(prevMonth));
    final prevSpent =
        prevTxAsync.valueOrNull?.fold<int>(0, (a, t) => a + t.amount);
    final saved = ref.watch(monthContributedProvider(_month)).valueOrNull ?? 0;

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => LoadError(e),
      data: (categories) => txAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => LoadError(e),
        data: (transactions) => _buildContent(
            categories, transactions, budgets, totalBudget, prevSpent, saved),
      ),
    );
  }

  Widget _buildContent(
      List<Category> categories,
      List<Transaction> transactions,
      Map<String, int> budgets,
      int totalBudget,
      int? prevSpent,
      int saved) {
    final categoriesById = {for (final c in categories) c.id: c};
    final methodsById =
        paymentMethodsById(ref.watch(paymentMethodsProvider).valueOrNull);
    final spentByCategory = <String, int>{};
    for (final t in transactions) {
      spentByCategory[t.categoryId] =
          (spentByCategory[t.categoryId] ?? 0) + t.amount;
    }

    final totalSpent = spentByCategory.values.fold<int>(0, (a, b) => a + b);
    final recentTx = transactions
        .where((t) => categoriesById.containsKey(t.categoryId))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final recent = recentTx.take(5).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        MonthSelector(
          label: capitalizeMonth(_month, monthFmt),
          onPrev: _prev,
          onNext: _isCurrentMonth ? null : _next,
          onToday: _isCurrentMonth ? null : _goToCurrentMonth,
        ),
        const SizedBox(height: 20),
        MonthSwipe(
          month: _month,
          onPrev: _prev,
          onNext: _isCurrentMonth ? null : _next,
          child: _TotalCard(
            spent: totalSpent,
            saved: saved,
            budget: totalBudget,
            prevSpent: prevSpent,
            today: _isCurrentMonth ? DateTime.now() : null,
          ),
        ),
        SwipeHint(visible: _showHint == true),
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
        if (transactions.isEmpty && _isCurrentMonth)
          _EmptyMonthCard(
            onAdd: () =>
                ref.read(selectedTabProvider.notifier).state = kAgregarTabIndex,
          )
        else if (transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Sin gastos registrados este mes.',
              style: TextStyle(color: context.colors.inkSoft, fontSize: 13),
            ),
          )
        else
          // `recent` ya excluye gastos con categoría inexistente (p. ej. de un
          // respaldo inconsistente) para no romper toda la pantalla.
          ...recent.map((t) => _RecentTxRow(
                tx: t,
                paymentLabel: transactionPaymentLabel(t, methodsById),
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
      backgroundColor: context.colors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => TransactionDetailSheet(
        category: category,
        month: _month,
        transactions: catTx,
      ),
    );
  }
}

String _formatRecentDate(Transaction tx) {
  final date = tx.date;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final dayStr = day == today
      ? 'Hoy'
      : day == today.subtract(const Duration(days: 1))
          ? 'Ayer'
          : DateFormat('d MMM', 'es_CL').format(date);
  if (!hasMeaningfulTime(date, isRecurring: tx.isRecurring)) return dayStr;
  return '$dayStr, ${DateFormat('HH:mm').format(date)}';
}

class _RecentTxRow extends StatelessWidget {
  const _RecentTxRow({
    required this.tx,
    required this.paymentLabel,
    required this.category,
    required this.onTap,
  });
  final Transaction tx;
  final Category category;

  /// RF32: con qué se pagó; null si no tiene método.
  final String? paymentLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.category(category.colorValue);

    // Parte del espacio entre filas va dentro del InkWell y el alto mínimo
    // es 48 px: el área táctil mínima de Android.
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(vertical: 4),
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
                        Flexible(
                          child: Text(
                            paymentLabel == null
                                ? _formatRecentDate(tx)
                                : '${_formatRecentDate(tx)} · $paymentLabel',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11, color: context.colors.inkSoft),
                          ),
                        ),
                        if (tx.isRecurring) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.repeat,
                              size: 11, color: context.colors.inkSoft),
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
                  color: context.colors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// RF04/RF05: [budget] es el presupuesto TOTAL que el usuario fija
/// directamente (MonthlyBudgets), no la suma de presupuestos por categoría.
/// RF51: los aportes a metas ([saved]) también salen de ese presupuesto.
class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.spent,
    required this.saved,
    required this.budget,
    required this.prevSpent,
    required this.today,
  });
  final int spent;
  final int saved;
  final int budget;
  final int? prevSpent;

  /// Solo en el mes en curso: muestra cuánto se puede gastar hoy (RF38).
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final available =
        availableThisMonth(budget: budget, spent: spent, saved: saved);
    final overBudget = budget > 0 && available < 0;
    final ratio = budget > 0 ? ((spent + saved) / budget).clamp(0.0, 1.0) : 0.0;
    final barColor = overBudget ? context.colors.rust : context.colors.green;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.paperDeep,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.rule),
      ),
      child: RuledPaperBackground(
        borderRadius: 11,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wrap: con letra grande la variación pasa a la línea siguiente.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text('GASTO DEL MES',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        color: context.colors.inkSoft)),
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
                  color: overBudget ? context.colors.rust : context.colors.ink,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text('de ${currencyFmt.format(budget)} presupuestado',
                style: TextStyle(fontSize: 13, color: context.colors.inkSoft)),
            const SizedBox(height: 16),
            LedgerCuadreBar(
              ratio: ratio,
              color: barColor,
              semanticsLabel: 'Presupuesto del mes',
              semanticsValue: budgetUsageSemantics(spent + saved, budget),
            ),
            if (budget > 0) ...[
              const SizedBox(height: 12),
              // Wrap: con letra grande las cifras bajan a otra línea.
              Wrap(
                spacing: 20,
                runSpacing: 8,
                children: [
                  _Figure(label: 'Gastado', amount: spent),
                  _Figure(label: 'Ahorrado', amount: saved),
                  _Figure(
                    label: overBudget ? 'Excedido' : 'Disponible',
                    amount: available.abs(),
                    color:
                        overBudget ? context.colors.rust : context.colors.green,
                  ),
                ],
              ),
              if (today != null) ...[
                const SizedBox(height: 12),
                _TodayAllowance(available: available, today: today!),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Una cifra del desglose del mes (RF51): gastado, ahorrado o disponible.
class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.amount, this.color});
  final String label;
  final int amount;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: context.colors.inkSoft)),
        Text(
          currencyFmt.format(amount),
          style: appAmountTextStyle.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color ?? context.colors.ink,
          ),
        ),
      ],
    );
  }
}

/// RF38: cuánto se puede gastar hoy para no pasarse del presupuesto. Con el
/// presupuesto excedido muestra $0 (el monto excedido ya está en el desglose).
class _TodayAllowance extends StatelessWidget {
  const _TodayAllowance({required this.available, required this.today});
  final int available;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final perDay = dailyAllowance(available: available, today: today);
    final daysLeft = DateTime(today.year, today.month + 1, 0).day - today.day;
    final hint = available <= 0
        ? 'Ya usaste todo el presupuesto del mes'
        : daysLeft == 0
            ? 'Es el último día del mes'
            : 'Por día, hasta fin de mes';
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.colors.rule)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 8,
        runSpacing: 4,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('PUEDES GASTAR HOY',
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      color: context.colors.inkSoft)),
              Text(hint,
                  style:
                      TextStyle(fontSize: 11, color: context.colors.inkSoft)),
            ],
          ),
          Text(
            currencyFmt.format(perDay),
            style: appAmountTextStyle.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: perDay > 0 ? context.colors.green : context.colors.rust,
            ),
          ),
        ],
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
    final color = isDown ? context.colors.green : context.colors.rust;

    if (diff == 0) {
      return Text('Igual que el mes anterior',
          style: TextStyle(fontSize: 11, color: context.colors.inkSoft));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(isDown ? Icons.arrow_downward : Icons.arrow_upward,
            size: 11, color: color),
        const SizedBox(width: 2),
        Text('$pct% vs. mes anterior',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
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
    final color = context.colors.category(category.colorValue);
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
                      Expanded(
                        child: Text(category.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currencyFmt.format(spent),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: overBudget
                              ? context.colors.rust
                              : context.colors.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
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
                  const SizedBox(height: 3),
                  Text('Presupuesto: ${currencyFmt.format(budget)}',
                      style: TextStyle(
                          fontSize: 11, color: context.colors.inkSoft)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 16, color: context.colors.inkSoft),
          ],
        ),
      ),
    );
  }
}

/// UX10: el mes en curso sin gastos invita a registrar el primero, en lugar
/// de solo avisar que no hay nada.
class _EmptyMonthCard extends StatelessWidget {
  const _EmptyMonthCard({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.rule),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aún no registras gastos este mes',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.colors.ink)),
          const SizedBox(height: 4),
          Text(
            'Anota cada gasto al momento: toma unos segundos y así sabrás '
            'cuánto te queda del presupuesto.',
            style: TextStyle(fontSize: 13, color: context.colors.inkSoft),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: context.colors.ink),
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Registrar un gasto'),
          ),
        ],
      ),
    );
  }
}
