import '../../data/local/app_database.dart';

/// Resuelve, para cada categoría, el presupuesto vigente en [month]: la fila
/// propia de ese mes si existe: si no, la más reciente anterior a ese mes.
/// Categorías sin ninguna fila de presupuesto en o antes de [month] no
/// aparecen en el mapa resultante (se asume 0).
Map<String, int> resolveBudgetsForMonth(
    List<CategoryBudget> allBudgets, DateTime month) {
  final targetYm = month.year * 100 + month.month;
  final latest = <String, CategoryBudget>{};
  for (final b in allBudgets) {
    final ym = b.year * 100 + b.month;
    if (ym > targetYm) continue;
    final current = latest[b.categoryId];
    if (current == null || (current.year * 100 + current.month) < ym) {
      latest[b.categoryId] = b;
    }
  }
  return {for (final e in latest.entries) e.key: e.value.amount};
}

/// Igual que [resolveBudgetsForMonth] pero para el presupuesto TOTAL
/// (MonthlyBudgets), que no está atado a ninguna categoría. 0 si no hay
/// ninguna fila en o antes de [month] (el usuario nunca lo fijó).
int resolveMonthlyBudgetForMonth(
    List<MonthlyBudget> allMonthlyBudgets, DateTime month) {
  final targetYm = month.year * 100 + month.month;
  MonthlyBudget? latest;
  for (final b in allMonthlyBudgets) {
    final ym = b.year * 100 + b.month;
    if (ym > targetYm) continue;
    if (latest == null || (latest.year * 100 + latest.month) < ym) {
      latest = b;
    }
  }
  return latest?.amount ?? 0;
}

/// RF50: ajustes de un solo mes que corresponden a [month]. No se heredan.
List<MonthlyAdjustment> adjustmentsForMonth(
        List<MonthlyAdjustment> allAdjustments, DateTime month) =>
    allAdjustments
        .where((a) => a.year == month.year && a.month == month.month)
        .toList();

/// Presupuesto por categoría vigente en el mes: el base heredado
/// ([resolveBudgetsForMonth]) más los ajustes de ese mes con categoría.
Map<String, int> withCategoryAdjustments(
    Map<String, int> baseBudgets, List<MonthlyAdjustment> monthAdjustments) {
  final result = {...baseBudgets};
  for (final a in monthAdjustments) {
    final id = a.categoryId;
    if (id == null) continue;
    result[id] = (result[id] ?? 0) + a.amount;
  }
  return result;
}

/// Presupuesto total vigente en el mes: el base más TODOS los ajustes del
/// mes. Un ajuste a una categoría también sube el total, porque es plata
/// extra y no una reasignación (si no, la categoría quedaría sobreasignada).
int withTotalAdjustments(
        int baseTotal, List<MonthlyAdjustment> monthAdjustments) =>
    monthAdjustments.fold(baseTotal, (sum, a) => sum + a.amount);
