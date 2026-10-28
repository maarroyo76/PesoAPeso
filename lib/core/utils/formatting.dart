import 'package:intl/intl.dart';

// $6.790  (símbolo antes, punto como separador de miles, sin decimales — CLP)
final currencyFmt = NumberFormat(r'$#,##0', 'es_CL');

final monthFmt = DateFormat.yMMMM('es_CL');
final monthShortFmt = DateFormat.MMM('es_CL');

/// Capitaliza la primera letra (intl devuelve minúscula en es_CL).
String capitalizeMonth(DateTime dt, DateFormat fmt) {
  final s = fmt.format(dt);
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}

/// El catch-up de recurrentes (RF12) guarda la fecha sin hora (00:00:00),
/// mientras que un gasto manual siempre lleva la hora en que se registró.
/// Para esos gastos generados la hora no significa nada y no se muestra.
bool hasMeaningfulTime(DateTime date, {required bool isRecurring}) =>
    !(isRecurring && date.hour == 0 && date.minute == 0 && date.second == 0);

/// UX08: valor que lee el lector de pantalla en una barra de presupuesto.
/// Usa el porcentaje real (puede pasar de 100%), no el de la barra, que se
/// corta al llenarse.
String budgetUsageSemantics(int spent, int budget) {
  if (budget <= 0) return 'sin presupuesto asignado';
  final pct = (spent / budget * 100).round();
  return spent > budget ? '$pct% usado, excedido' : '$pct% usado';
}

/// UX08: valor que lee el lector de pantalla en la barra de una meta.
String goalProgressSemantics(int contributed, int target) => target > 0
    ? '${(contributed / target * 100).round()}% de la meta'
    : 'sin monto objetivo';
