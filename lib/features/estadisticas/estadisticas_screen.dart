import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/category_icons.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/month_selector.dart';
import '../../core/widgets/section_label.dart';
import '../../data/local/app_database.dart';

class EstadisticasScreen extends ConsumerStatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  ConsumerState<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends ConsumerState<EstadisticasScreen> {
  int _touchedIndex = -1;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _prev() {
    setState(() {
      _month = DateTime(_month.year, _month.month - 1);
      _touchedIndex = -1;
    });
  }

  void _next() {
    final next = DateTime(_month.year, _month.month + 1);
    final now = DateTime.now();
    if (!next.isAfter(DateTime(now.year, now.month))) {
      setState(() {
        _month = next;
        _touchedIndex = -1;
      });
    }
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  /// Los 6 meses que terminan en el mes que se está viendo — así el
  /// gráfico de tendencia también se mueve al navegar hacia atrás.
  List<DateTime> get _months =>
      List.generate(6, (i) => DateTime(_month.year, _month.month - (5 - i)));

  @override
  Widget build(BuildContext context) {
    final months = _months;
    final currentMonth = months.last;
    final prevMonth = DateTime(currentMonth.year, currentMonth.month - 1);
    final categoriesAsync = ref.watch(categoriesProvider);
    final txCurrentAsync = ref.watch(monthTransactionsProvider(currentMonth));
    final txPrevAsync = ref.watch(monthTransactionsProvider(prevMonth));
    final totalBudget = ref.watch(monthTotalBudgetProvider(currentMonth));

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (categories) => txCurrentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (txCurrent) => _buildContent(
          categories,
          txCurrent,
          txPrevAsync.valueOrNull ?? const [],
          months,
          totalBudget,
        ),
      ),
    );
  }

  Widget _buildContent(
    List<Category> categories,
    List<Transaction> txCurrent,
    List<Transaction> txPrev,
    List<DateTime> months,
    int totalBudget,
  ) {
    final categoriesById = {for (final c in categories) c.id: c};

    final spentByCategory = <String, int>{};
    for (final t in txCurrent) {
      spentByCategory[t.categoryId] =
          (spentByCategory[t.categoryId] ?? 0) + t.amount;
    }
    final prevSpentByCategory = <String, int>{};
    for (final t in txPrev) {
      prevSpentByCategory[t.categoryId] =
          (prevSpentByCategory[t.categoryId] ?? 0) + t.amount;
    }

    final totalCurrentMonth =
        spentByCategory.values.fold<int>(0, (a, b) => a + b);
    // RF04/RF09: `totalBudget` es el presupuesto TOTAL fijado por el
    // usuario (MonthlyBudgets), no la suma de presupuestos por categoría.

    // Ordenadas de mayor a menor gasto: la categoría que más pesa queda
    // primero tanto en la torta (sección más grande arrancando arriba) como
    // en la leyenda, en vez de un orden arbitrario de creación.
    final activeCats = categories
        .where((c) => (spentByCategory[c.id] ?? 0) > 0)
        .toList()
      ..sort((a, b) =>
          (spentByCategory[b.id] ?? 0).compareTo(spentByCategory[a.id] ?? 0));

    final recurringSpent = txCurrent
        .where((t) => t.isRecurring)
        .fold<int>(0, (a, t) => a + t.amount);
    final variableSpent = totalCurrentMonth - recurringSpent;

    final now = DateTime.now();
    final isCurrentCalendarMonth =
        now.year == months.last.year && now.month == months.last.month;
    final daysElapsed =
        isCurrentCalendarMonth ? now.day : _daysInMonth(months.last);
    final daysInMonth = _daysInMonth(months.last);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        MonthSelector(
          label: capitalizeMonth(_month, monthFmt),
          onPrev: _prev,
          onNext: _isCurrentMonth ? null : _next,
        ),
        const SizedBox(height: 20),
        SectionLabel(isCurrentCalendarMonth ? 'Mes actual' : 'Resumen del mes'),
        const SizedBox(height: 16),
        _InsightGrid(
          totalSpent: totalCurrentMonth,
          daysElapsed: daysElapsed,
          daysInMonth: daysInMonth,
          recurringSpent: recurringSpent,
          variableSpent: variableSpent,
          isCurrentMonth: isCurrentCalendarMonth,
        ),
        const SizedBox(height: 24),
        if (activeCats.isEmpty)
          _EmptyCard()
        else ...[
          _PieSection(
            categories: activeCats,
            spentByCategory: spentByCategory,
            totalSpent: totalCurrentMonth,
            totalBudget: totalBudget,
            touchedIndex: _touchedIndex,
            onTouch: (i) => setState(() => _touchedIndex = i),
          ),
          const SizedBox(height: 20),
          _Legend(
            categories: activeCats,
            spentByCategory: spentByCategory,
            totalSpent: totalCurrentMonth,
            touchedIndex: _touchedIndex,
          ),
        ],
        const SizedBox(height: 32),
        const SectionLabel('Variación vs. mes anterior'),
        const SizedBox(height: 12),
        _CategoryDeltaSection(
          categories: categories,
          spentByCategory: spentByCategory,
          prevSpentByCategory: prevSpentByCategory,
        ),
        const SizedBox(height: 32),
        const SectionLabel('Gasto por día de la semana'),
        const SizedBox(height: 16),
        _WeekdaySection(transactions: txCurrent),
        const SizedBox(height: 32),
        const SectionLabel('Mayores gastos del mes'),
        const SizedBox(height: 12),
        _TopTransactionsSection(
          transactions: txCurrent,
          categoriesById: categoriesById,
        ),
        const SizedBox(height: 32),
        const SectionLabel('Últimos 6 meses'),
        const SizedBox(height: 16),
        _MonthBarsSection(months: months),
      ],
    );
  }

  int _daysInMonth(DateTime month) =>
      DateTime(month.year, month.month + 1, 0).day;
}

/// Cuadro de 4 cifras rápidas — inspirado en los grids de stat cards de
/// dashboards de finanzas personales (promedio diario, proyección de
/// cierre, y el quiebre recurrente/variable que solo esta app puede
/// mostrar porque ya distingue gastos recurrentes de manuales).
class _InsightGrid extends StatelessWidget {
  const _InsightGrid({
    required this.totalSpent,
    required this.daysElapsed,
    required this.daysInMonth,
    required this.recurringSpent,
    required this.variableSpent,
    required this.isCurrentMonth,
  });

  final int totalSpent;
  final int daysElapsed;
  final int daysInMonth;
  final int recurringSpent;
  final int variableSpent;
  final bool isCurrentMonth;

  @override
  Widget build(BuildContext context) {
    final avgDaily = daysElapsed > 0 ? (totalSpent / daysElapsed).round() : 0;
    // Para un mes ya cerrado, "proyección" no tiene sentido — daysElapsed ya
    // viene igualado a daysInMonth, así que esto da exactamente el total
    // gastado. Solo cambia la etiqueta para no llamar "proyección" a un
    // hecho consumado.
    final projected = avgDaily * daysInMonth;
    final total = recurringSpent + variableSpent;
    final recurringPct = total > 0 ? (recurringSpent / total * 100).round() : 0;
    final variablePct = total > 0 ? 100 - recurringPct : 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.3,
      children: [
        _StatTile(
            label: 'PROMEDIO DIARIO', value: currencyFmt.format(avgDaily)),
        _StatTile(
            label: isCurrentMonth ? 'PROYECCIÓN' : 'TOTAL DEL MES',
            value: currencyFmt.format(projected)),
        _StatTile(
            label: 'GASTO RECURRENTE',
            value: '$recurringPct%',
            sub: currencyFmt.format(recurringSpent)),
        _StatTile(
            label: 'GASTO VARIABLE',
            value: '$variablePct%',
            sub: currencyFmt.format(variableSpent)),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.sub});
  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.paperDeep,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 9, letterSpacing: 1.0, color: AppColors.inkSoft)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: appAmountTextStyle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(sub!,
                style: appAmountTextStyle.copyWith(
                    fontSize: 10, color: AppColors.inkSoft)),
          ],
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.paperDeep,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rule),
      ),
      child: const Center(
        child: Text('Sin gastos registrados este mes.',
            style: TextStyle(color: AppColors.inkSoft, fontSize: 13)),
      ),
    );
  }
}

class _PieSection extends StatelessWidget {
  const _PieSection({
    required this.categories,
    required this.spentByCategory,
    required this.totalSpent,
    required this.totalBudget,
    required this.touchedIndex,
    required this.onTouch,
  });

  final List<Category> categories;
  final Map<String, int> spentByCategory;
  final int totalSpent;
  final int totalBudget;
  final int touchedIndex;
  final ValueChanged<int> onTouch;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  if (response == null ||
                      response.touchedSection == null ||
                      event is FlPointerExitEvent) {
                    onTouch(-1);
                  } else {
                    onTouch(response.touchedSection!.touchedSectionIndex);
                  }
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 68,
              sections: List.generate(categories.length, (i) {
                final cat = categories[i];
                final spent = spentByCategory[cat.id] ?? 0;
                final isTouched = i == touchedIndex;
                return PieChartSectionData(
                  value: spent.toDouble(),
                  color: Color(cat.colorValue),
                  radius: isTouched ? 52 : 42,
                  showTitle: false,
                );
              }),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('GASTADO',
                  style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.2,
                      color: AppColors.inkSoft)),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    currencyFmt.format(totalSpent),
                    style: appAmountTextStyle.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink),
                  ),
                ),
              ),
              Text(
                'de ${currencyFmt.format(totalBudget)}',
                style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.categories,
    required this.spentByCategory,
    required this.totalSpent,
    required this.touchedIndex,
  });

  final List<Category> categories;
  final Map<String, int> spentByCategory;
  final int totalSpent;
  final int touchedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(categories.length, (i) {
        final cat = categories[i];
        final spent = spentByCategory[cat.id] ?? 0;
        final pct = totalSpent > 0 ? (spent / totalSpent * 100).round() : 0;
        final isHighlighted = touchedIndex == -1 || touchedIndex == i;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: isHighlighted ? 1.0 : 0.35,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Color(cat.colorValue),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Icon(iconForCategory(cat), size: 15, color: AppColors.inkSoft),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(cat.name,
                      style:
                          const TextStyle(fontSize: 13, color: AppColors.ink)),
                ),
                Text('$pct%',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.inkSoft)),
                const SizedBox(width: 12),
                Text(
                  currencyFmt.format(spent),
                  style: appAmountTextStyle.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// Compara el gasto de cada categoría con el mes anterior — el mismo tipo
/// de vista que ofrecen las plantillas de presupuesto y apps revisadas
/// (Copilot, Monarch, Spendee) para mostrar si un rubro está subiendo o
/// bajando, no solo cuánto se gastó.
class _CategoryDeltaSection extends StatelessWidget {
  const _CategoryDeltaSection({
    required this.categories,
    required this.spentByCategory,
    required this.prevSpentByCategory,
  });

  final List<Category> categories;
  final Map<String, int> spentByCategory;
  final Map<String, int> prevSpentByCategory;

  @override
  Widget build(BuildContext context) {
    final relevant = categories
        .where((c) =>
            (spentByCategory[c.id] ?? 0) > 0 ||
            (prevSpentByCategory[c.id] ?? 0) > 0)
        .toList()
      ..sort((a, b) =>
          (spentByCategory[b.id] ?? 0).compareTo(spentByCategory[a.id] ?? 0));

    if (relevant.isEmpty) {
      return const Text(
        'Sin datos suficientes para comparar con el mes anterior.',
        style: TextStyle(color: AppColors.inkSoft, fontSize: 12),
      );
    }

    return Column(
      children: relevant.map((c) {
        final curr = spentByCategory[c.id] ?? 0;
        final prev = prevSpentByCategory[c.id] ?? 0;
        final color = Color(c.colorValue);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 28,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Icon(iconForCategory(c), size: 15, color: AppColors.inkSoft),
              const SizedBox(width: 8),
              Expanded(
                child: Text(c.name,
                    style: const TextStyle(fontSize: 13, color: AppColors.ink)),
              ),
              Text(
                currencyFmt.format(curr),
                style: appAmountTextStyle.copyWith(
                    fontSize: 12, color: AppColors.inkSoft),
              ),
              const SizedBox(width: 8),
              _DeltaLabel(curr: curr, prev: prev),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DeltaLabel extends StatelessWidget {
  const _DeltaLabel({required this.curr, required this.prev});
  final int curr;
  final int prev;

  @override
  Widget build(BuildContext context) {
    if (prev == 0) {
      return const Text('Nuevo',
          style: TextStyle(fontSize: 11, color: AppColors.inkSoft));
    }
    final diff = curr - prev;
    if (diff == 0) {
      return const Text('Igual',
          style: TextStyle(fontSize: 11, color: AppColors.inkSoft));
    }
    final pct = (diff.abs() / prev * 100).round();
    final isDown = diff < 0;
    final color = isDown ? AppColors.green : AppColors.rust;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(isDown ? Icons.arrow_downward : Icons.arrow_upward,
            size: 12, color: color),
        const SizedBox(width: 2),
        Text('$pct%',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

/// En qué días de la semana se concentra el gasto — patrón citado en varias
/// apps de gasto (fines de semana vs. días de semana suelen tener perfiles
/// muy distintos). Mismo estilo visual que `_MonthBarsSection` para no
/// introducir un tercer lenguaje de gráfico en la misma pantalla.
class _WeekdaySection extends StatelessWidget {
  const _WeekdaySection({required this.transactions});
  final List<Transaction> transactions;

  static const _labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final totals = List<int>.filled(7, 0);
    for (final t in transactions) {
      totals[t.date.weekday - 1] += t.amount;
    }
    final maxVal = totals.reduce((a, b) => a > b ? a : b);
    final maxIndex = maxVal > 0 ? totals.indexOf(maxVal) : -1;

    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.paperDeep,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rule),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxVal > 0 ? maxVal * 1.25 : 100,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.ink,
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                currencyFmt.format(rod.toY.round()),
                const TextStyle(
                    color: AppColors.paper,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= _labels.length) return const SizedBox();
                  return Text(_labels[i],
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.inkSoft));
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.rule, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (i) {
            final isMax = i == maxIndex;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: totals[i].toDouble(),
                  color: isMax ? AppColors.green : AppColors.rule,
                  width: 22,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// Los gastos individuales más grandes del mes — "biggest expense
/// identification", una de las vistas más citadas en las apps revisadas
/// para detectar de un vistazo qué movimiento puntual pesó más.
class _TopTransactionsSection extends StatelessWidget {
  const _TopTransactionsSection({
    required this.transactions,
    required this.categoriesById,
  });

  final List<Transaction> transactions;
  final Map<String, Category> categoriesById;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Text('Sin gastos registrados este mes.',
          style: TextStyle(color: AppColors.inkSoft, fontSize: 12));
    }
    final top = [...transactions]..sort((a, b) => b.amount.compareTo(a.amount));

    return Column(
      children: top.take(5).map((t) {
        final cat = categoriesById[t.categoryId];
        final color = cat != null ? Color(cat.colorValue) : AppColors.inkSoft;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
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
                child: cat != null
                    ? Icon(iconForCategory(cat), size: 16, color: color)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.note.isNotEmpty ? t.note : (cat?.name ?? '—'),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      DateFormat('d MMM', 'es_CL').format(t.date),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                currencyFmt.format(t.amount),
                style: appAmountTextStyle.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MonthBarsSection extends ConsumerWidget {
  const _MonthBarsSection({required this.months});
  final List<DateTime> months;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txPerMonth =
        months.map((m) => ref.watch(monthTransactionsProvider(m))).toList();

    // Construcción segura: índice fijo, no depende del orden de ejecución
    final totals = List.generate(
      months.length,
      (i) => txPerMonth[i].maybeWhen(
        data: (txs) => txs.fold<int>(0, (a, t) => a + t.amount),
        orElse: () => 0,
      ),
    );

    final maxVal = totals.isEmpty
        ? 1.0
        : totals.reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.paperDeep,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rule),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxVal > 0 ? maxVal * 1.25 : 100,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.ink,
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                currencyFmt.format(rod.toY.round()),
                const TextStyle(
                    color: AppColors.paper,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= months.length) return const SizedBox();
                  final label = monthShortFmt.format(months[i]);
                  final cap = label[0].toUpperCase() +
                      label.substring(1, label.length.clamp(1, 3));
                  return Text(cap,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.inkSoft));
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.rule, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(months.length, (i) {
            final isLast = i == months.length - 1;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: totals[i].toDouble(),
                  color: isLast ? AppColors.green : AppColors.rule,
                  width: 28,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
