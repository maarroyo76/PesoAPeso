/// RF58 / RNF24: proyección del disponible de los meses siguientes, con y sin
/// una compra simulada. Todo es puro: recibe los datos ya leídos de la base y
/// no escribe nada (RF57).
///
/// Base de cálculo común: el disponible proyectado de un mes futuro es el
/// presupuesto total vigente ese mes, menos los recurrentes activos, menos las
/// cuotas ya comprometidas, menos el gasto variable esperado. El gasto
/// variable esperado es la mediana del gasto de los últimos 3 meses cerrados
/// que no viene de recurrentes ni de cuotas.
library;

import '../../data/local/app_database.dart';
import 'budget_resolver.dart';
import 'daily_allowance.dart';
import 'habitual.dart';
import 'installments.dart';

/// Meses cerrados que entran en la mediana del gasto variable.
const kProjectionHistoryMonths = 3;

/// Meses que la simulación muestra uno por uno; el resto va resumido (RF58).
const kProjectionVisibleMonths = 12;

/// De dónde sale la referencia contra la que se descuenta cada mes.
enum ProjectionBasis {
  /// El presupuesto total vigente en cada mes (lo normal).
  totalBudget,

  /// El usuario no definió presupuesto total ("Aún no sé"): se usa la mediana
  /// del gasto total de los últimos meses cerrados, y la pantalla lo indica.
  spendingMedian,

  /// Ni presupuesto total ni meses cerrados con gastos: no hay referencia y
  /// la pantalla debe pedir un presupuesto total.
  none,
}

/// Primer día del mes de [date], sin hora.
DateTime monthOf(DateTime date) => DateTime(date.year, date.month);

/// Mes [offset] meses después de [month] (negativo = antes). Cruza años.
DateTime addMonths(DateTime month, int offset) =>
    DateTime(month.year, month.month + offset);

bool _sameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

/// Gasto que viene de un pago fijo mensual (RF12). Los gastos habituales
/// (RF47) no llevan la marca y cuentan como gasto variable.
bool isRecurringExpense(Transaction t) =>
    t.isRecurring || t.recurringTemplateId != null;

/// Cuota de un plan (RF34), incluido el pago del prepago (RF35).
bool isInstallmentExpense(Transaction t) => t.installmentPlanId != null;

/// Gasto variable: descuenta del presupuesto y no es recurrente ni cuota.
bool isVariableExpense(Transaction t) =>
    countsAgainstBudget(t) &&
    !isRecurringExpense(t) &&
    !isInstallmentExpense(t);

/// Mediana entera de [values]; 0 si está vacía. Con un número par de valores,
/// el promedio de los dos centrales truncado al peso.
int median(Iterable<int> values) {
  final sorted = values.toList()..sort();
  if (sorted.isEmpty) return 0;
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[mid];
  return (sorted[mid - 1] + sorted[mid]) ~/ 2;
}

/// Hasta [kProjectionHistoryMonths] meses cerrados anteriores a
/// [currentMonth], del más antiguo al más reciente. Solo cuentan los meses
/// desde el primer gasto registrado: los meses previos a usar la app no son
/// meses sin gasto, y meterlos como 0 bajaría la mediana.
List<DateTime> closedHistoryMonths(
    Iterable<Transaction> transactions, DateTime currentMonth) {
  DateTime? first;
  for (final t in transactions) {
    final m = monthOf(t.date);
    if (!m.isBefore(currentMonth)) continue;
    if (first == null || m.isBefore(first)) first = m;
  }
  if (first == null) return const [];
  return [
    for (var back = kProjectionHistoryMonths; back >= 1; back--)
      if (!addMonths(currentMonth, -back).isBefore(first))
        addMonths(currentMonth, -back),
  ];
}

int _sumInMonth(Iterable<Transaction> transactions, DateTime month,
        bool Function(Transaction) where) =>
    transactions
        .where((t) => _sameMonth(t.date, month) && where(t))
        .fold(0, (sum, t) => sum + t.amount);

/// RF34 / RF59: cargos de una compra por mes, a partir de los montos de cada
/// cuota ([amounts], en orden). La cuota k cae en el mes de
/// [installmentDate]; con una sola cuota es un pago al contado en el mes de
/// la compra.
Map<DateTime, int> purchaseCharges(DateTime purchaseDate, List<int> amounts) {
  final byMonth = <DateTime, int>{};
  for (var k = 1; k <= amounts.length; k++) {
    final month = monthOf(installmentDate(purchaseDate, k));
    byMonth[month] = (byMonth[month] ?? 0) + amounts[k - 1];
  }
  return byMonth;
}

/// Un mes de la proyección. Los montos van en pesos.
class MonthProjection {
  const MonthProjection({
    required this.month,
    required this.reference,
    required this.recurring,
    required this.committed,
    required this.variable,
    required this.spent,
    required this.purchase,
  });

  final DateTime month;

  /// Presupuesto total vigente (o la mediana del gasto, según la base).
  final int reference;

  /// Recurrentes que faltan por cargar. En el mes en curso, solo los que aún
  /// no se registraron.
  final int recurring;

  /// Cuotas ya registradas en el mes que todavía no están en [spent]: en los
  /// meses futuros, todas; en el mes en curso, 0 (ya cuentan como gastadas).
  final int committed;

  /// Gasto variable que falta: la mediana en meses futuros; en el mes en
  /// curso, lo que falta para llegar a ella.
  final int variable;

  /// Lo ya gastado y aportado a metas en el mes (solo el mes en curso).
  final int spent;

  /// Cargo de la compra simulada en este mes (0 si no cae aquí).
  final int purchase;

  /// Disponible proyectado sin la compra. Negativo = falta plata.
  int get availableWithout =>
      reference - spent - recurring - committed - variable;

  /// Disponible proyectado con la compra.
  int get availableWith => availableWithout - purchase;

  /// Monto que falta para no quedar bajo cero con la compra; 0 si alcanza.
  int get shortfall => availableWith < 0 ? -availableWith : 0;

  bool get belowZero => availableWith < 0;
}

/// Resultado de una proyección: la base usada y un registro por mes.
class Projection {
  const Projection({
    required this.basis,
    required this.expectedVariable,
    required this.historyMonths,
    required this.months,
  });

  final ProjectionBasis basis;

  /// Mediana del gasto variable mensual con que se proyecta.
  final int expectedVariable;

  /// Cuántos meses cerrados entraron en la mediana (0 a 3). Con menos de 3
  /// la proyección es menos confiable y la pantalla puede avisarlo.
  final int historyMonths;

  final List<MonthProjection> months;
}

/// RF58: proyecta [count] meses desde [from] (el mes en curso o uno
/// posterior), descontando [charges] (cargos por mes de una compra simulada,
/// ver [purchaseCharges]; vacío para proyectar sin compra).
///
/// - [today] fija el mes en curso y qué recurrentes faltan por cargar.
/// - [transactions]: todos los gastos (o, como mínimo, los de los 3 meses
///   cerrados anteriores, los del mes en curso y las cuotas futuras).
/// - [templates]: plantillas de RecurringTemplates; solo cuentan los pagos
///   fijos activos ('auto'). Los habituales ya están en el gasto variable.
/// - [savedThisMonth]: aportes a metas del mes en curso (RF51).
///
/// El mes en curso no se proyecta desde cero: parte de lo ya gastado y
/// aportado, suma los recurrentes que aún no se cargan y supone que el gasto
/// variable del mes llegará al menos a la mediana.
///
/// Los aportes a metas de meses futuros no se proyectan: no hay un dato del
/// que deducirlos.
Projection projectMonths({
  required DateTime today,
  required DateTime from,
  required int count,
  required List<Transaction> transactions,
  required List<RecurringTemplate> templates,
  required List<MonthlyBudget> monthlyBudgets,
  required List<MonthlyAdjustment> adjustments,
  int savedThisMonth = 0,
  Map<DateTime, int> charges = const {},
}) {
  final current = monthOf(today);
  final start = monthOf(from);
  if (start.isBefore(current)) {
    throw ArgumentError.value(from, 'from', 'no puede ser un mes pasado');
  }
  if (count < 0) throw ArgumentError.value(count, 'count');

  final history = closedHistoryMonths(transactions, current);
  final expectedVariable = median([
    for (final m in history) _sumInMonth(transactions, m, isVariableExpense),
  ]);

  final hasTotalBudget = monthlyBudgets.any((b) => b.amount > 0);
  final ProjectionBasis basis;
  final int fallbackReference;
  if (hasTotalBudget) {
    basis = ProjectionBasis.totalBudget;
    fallbackReference = 0;
  } else if (history.isNotEmpty) {
    basis = ProjectionBasis.spendingMedian;
    fallbackReference = median([
      for (final m in history)
        _sumInMonth(transactions, m, countsAgainstBudget),
    ]);
  } else {
    basis = ProjectionBasis.none;
    fallbackReference = 0;
  }

  final fixedTemplates = templates
      .where((t) => t.active && !isHabitual(t))
      .toList(growable: false);
  final allRecurring = fixedTemplates.fold(0, (sum, t) => sum + t.amount);
  final currentYm = current.year * 100 + current.month;

  final months = <MonthProjection>[];
  for (var i = 0; i < count; i++) {
    final month = addMonths(start, i);
    final reference = basis == ProjectionBasis.totalBudget
        ? withTotalAdjustments(
            resolveMonthlyBudgetForMonth(monthlyBudgets, month),
            adjustmentsForMonth(adjustments, month))
        : fallbackReference;
    final purchase = charges[month] ?? 0;

    if (_sameMonth(month, current)) {
      final spent = _sumInMonth(transactions, month, countsAgainstBudget);
      final variableSpent = _sumInMonth(transactions, month, isVariableExpense);
      final pendingRecurring = fixedTemplates
          .where((t) => t.lastGeneratedYearMonth < currentYm)
          .fold(0, (sum, t) => sum + t.amount);
      final variableLeft = expectedVariable - variableSpent;
      months.add(MonthProjection(
        month: month,
        reference: reference,
        recurring: pendingRecurring,
        committed: 0,
        variable: variableLeft > 0 ? variableLeft : 0,
        spent: spent + savedThisMonth,
        purchase: purchase,
      ));
    } else {
      months.add(MonthProjection(
        month: month,
        reference: reference,
        recurring: allRecurring,
        committed: _sumInMonth(transactions, month,
            (t) => isInstallmentExpense(t) && countsAgainstBudget(t)),
        variable: expectedVariable,
        spent: 0,
        purchase: purchase,
      ));
    }
  }

  return Projection(
    basis: basis,
    expectedVariable: expectedVariable,
    historyMonths: history.length,
    months: months,
  );
}

/// RF58: proyección de los meses que abarca una compra, desde el mes en curso
/// o el de la compra (el que sea posterior) hasta el de su último cargo.
Projection simulatePurchase({
  required DateTime today,
  required DateTime purchaseDate,
  required List<int> installmentAmounts,
  required List<Transaction> transactions,
  required List<RecurringTemplate> templates,
  required List<MonthlyBudget> monthlyBudgets,
  required List<MonthlyAdjustment> adjustments,
  int savedThisMonth = 0,
}) {
  final charges = purchaseCharges(purchaseDate, installmentAmounts);
  final current = monthOf(today);
  final first = monthOf(purchaseDate);
  final start = first.isBefore(current) ? current : first;
  final last = charges.keys.fold(start, (a, b) => b.isAfter(a) ? b : a);
  final count = (last.year - start.year) * 12 + last.month - start.month + 1;
  return projectMonths(
    today: today,
    from: start,
    count: count,
    transactions: transactions,
    templates: templates,
    monthlyBudgets: monthlyBudgets,
    adjustments: adjustments,
    savedThisMonth: savedThisMonth,
    charges: charges,
  );
}

/// RF58: resumen de los meses que no se muestran uno por uno (desde el 13).
class ProjectionTail {
  const ProjectionTail({
    required this.months,
    required this.purchase,
    required this.monthsBelowZero,
    required this.totalShortfall,
    required this.lowestAvailable,
  });

  /// Cuántos meses resume.
  final int months;

  /// Suma de los cargos de la compra en esos meses.
  final int purchase;

  final int monthsBelowZero;
  final int totalShortfall;

  /// El menor disponible con la compra entre esos meses.
  final int lowestAvailable;
}

/// Los meses después de los primeros [visible], resumidos; null si no hay.
ProjectionTail? summarizeTail(List<MonthProjection> months,
    {int visible = kProjectionVisibleMonths}) {
  if (months.length <= visible) return null;
  final rest = months.sublist(visible);
  return ProjectionTail(
    months: rest.length,
    purchase: rest.fold(0, (sum, m) => sum + m.purchase),
    monthsBelowZero: rest.where((m) => m.belowZero).length,
    totalShortfall: rest.fold(0, (sum, m) => sum + m.shortfall),
    lowestAvailable:
        rest.map((m) => m.availableWith).reduce((a, b) => a < b ? a : b),
  );
}
