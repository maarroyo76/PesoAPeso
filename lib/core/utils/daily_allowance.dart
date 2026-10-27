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
