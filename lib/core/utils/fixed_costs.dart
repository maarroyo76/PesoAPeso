/// RF64: costo de vida fijo, lo que el mes ya trae comprometido antes de
/// cualquier decisión: pagos fijos (RF12), cuotas (RF34) y gastos habituales
/// (RF47). Puro: recibe los datos ya leídos.
library;

import '../../data/local/app_database.dart';
import 'daily_allowance.dart';
import 'habitual.dart';
import 'projection.dart';

/// Costo fijo de un mes, por componente. [total] es siempre su suma.
class FixedCost {
  const FixedCost({
    required this.month,
    required this.recurring,
    required this.installments,
    required this.habitual,
    required this.expected,
  });

  final DateTime month;

  /// Pagos fijos mensuales (arriendo, suscripciones).
  final int recurring;

  /// Cuotas de compras a plazo.
  final int installments;

  /// Gastos habituales (metro, colación).
  final int habitual;

  /// true si incluye montos esperados y no solo registrados (el mes en curso).
  final bool expected;

  int get total => recurring + installments + habitual;

  /// Porcentaje del presupuesto total, redondeado; null sin presupuesto.
  int? percentOf(int totalBudget) =>
      totalBudget > 0 ? (total * 100 / totalBudget).round() : null;
}

/// Días de [month] en que toca el gasto habitual [template], desde su
/// `startDate`. 0 si está pausado o no es habitual.
int scheduledDaysInMonth(RecurringTemplate template, DateTime month) {
  if (!isHabitual(template) || !template.active) return 0;
  final mask = template.weekdays ?? 0;
  final start =
      template.startDate == null ? null : dateOnly(template.startDate!);
  final days = DateTime(month.year, month.month + 1, 0).day;
  var count = 0;
  for (var d = 1; d <= days; d++) {
    final day = DateTime(month.year, month.month, d);
    if (start != null && day.isBefore(start)) continue;
    if (includesWeekday(mask, day.weekday)) count++;
  }
  return count;
}

/// Gasto habitual esperado en [month]: cada habitual activo por los días que
/// le tocan.
int expectedHabitual(List<RecurringTemplate> templates, DateTime month) =>
    templates.fold(
        0, (sum, t) => sum + t.amount * scheduledDaysInMonth(t, month));

bool _inMonth(Transaction t, DateTime month) =>
    t.date.year == month.year && t.date.month == month.month;

int _sum(Iterable<Transaction> txs) => txs.fold(0, (s, t) => s + t.amount);

/// RF64: costo fijo de [month] visto desde [today].
///
/// - Mes pasado: lo registrado. Pagos fijos y cuotas por sus marcas; los
///   habituales por [habitualTransactionIds], los gastos que salieron de
///   confirmar un habitual (no llevan otra marca).
/// - Mes en curso: los pagos fijos ya cargados más los que faltan, las
///   cuotas del mes y los habituales esperados del mes completo.
/// - Mes futuro: pagos fijos activos, cuotas ya comprometidas y habituales
///   esperados.
///
/// Los gastos pagados con una meta (RF52) no cuentan: no salen del mes.
FixedCost fixedCostForMonth({
  required DateTime month,
  required DateTime today,
  required List<Transaction> transactions,
  required List<RecurringTemplate> templates,
  required Set<int> habitualTransactionIds,
}) {
  final m = monthOf(month);
  final current = monthOf(today);
  final inMonth = transactions
      .where((t) => _inMonth(t, m) && countsAgainstBudget(t))
      .toList(growable: false);
  final installments = _sum(inMonth.where(isInstallmentExpense));
  final fixed = templates.where((t) => t.active && !isHabitual(t));

  if (m.isBefore(current)) {
    return FixedCost(
      month: m,
      recurring: _sum(inMonth.where(isRecurringExpense)),
      installments: installments,
      habitual:
          _sum(inMonth.where((t) => habitualTransactionIds.contains(t.id))),
      expected: false,
    );
  }

  final ym = m.year * 100 + m.month;
  final recurring = m == current
      ? _sum(inMonth.where(isRecurringExpense)) +
          fixed
              .where((t) => t.lastGeneratedYearMonth < ym)
              .fold<int>(0, (s, t) => s + t.amount)
      : fixed.fold<int>(0, (s, t) => s + t.amount);
  return FixedCost(
    month: m,
    recurring: recurring,
    installments: installments,
    habitual: expectedHabitual(templates, m),
    expected: true,
  );
}

/// RF64: costo fijo de cada uno de [months].
List<FixedCost> fixedCostTrend({
  required List<DateTime> months,
  required DateTime today,
  required List<Transaction> transactions,
  required List<RecurringTemplate> templates,
  required Set<int> habitualTransactionIds,
}) =>
    [
      for (final m in months)
        fixedCostForMonth(
          month: m,
          today: today,
          transactions: transactions,
          templates: templates,
          habitualTransactionIds: habitualTransactionIds,
        ),
    ];

/// RF64: cuotas ya comprometidas en cada uno de los [count] meses que siguen
/// a [after]. Incluye los meses sin cuotas (con 0).
List<({DateTime month, int amount})> committedInstallments(
    List<Transaction> transactions, DateTime after,
    {int count = 6}) {
  final start = monthOf(after);
  return [
    for (var i = 1; i <= count; i++)
      (
        month: addMonths(start, i),
        amount: _sum(transactions.where((t) =>
            _inMonth(t, addMonths(start, i)) &&
            isInstallmentExpense(t) &&
            countsAgainstBudget(t))),
      ),
  ];
}
