import '../../data/local/app_database.dart';

/// RF51: lo que queda libre del presupuesto del mes. Los aportes a metas
/// salen del presupuesto aunque no sean gasto de ninguna categoría.
/// Negativo = presupuesto excedido.
int availableThisMonth({
  required int budget,
  required int spent,
  required int saved,
}) =>
    budget - spent - saved;

/// RF38: cuánto se puede gastar hoy, repartiendo [available] en partes
/// iguales entre los días que quedan del mes, incluido hoy. 0 si el
/// presupuesto está excedido.
int dailyAllowance({required int available, required DateTime today}) {
  if (available <= 0) return 0;
  final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
  final daysLeft = daysInMonth - today.day + 1;
  return available ~/ daysLeft;
}

/// RF52: un gasto pagado con el ahorro de una meta no sale del presupuesto
/// del mes (ya salió cuando se aportó a la meta).
bool countsAgainstBudget(Transaction t) => t.fundedByGoalId == null;

/// Lo gastado del presupuesto del mes: sin los gastos pagados con ahorro.
int budgetSpent(Iterable<Transaction> transactions) => transactions
    .where(countsAgainstBudget)
    .fold<int>(0, (sum, t) => sum + t.amount);
