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
