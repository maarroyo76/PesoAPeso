/// RF34: cuotas de una compra con tarjeta de crédito.
library;

const kMinInstallments = 2;
const kMaxInstallments = 48;

/// Monto de cada cuota: partes iguales y el resto de la división en la
/// última, para que la suma sea exactamente [total].
List<int> installmentAmounts(int total, int count) {
  final base = total ~/ count;
  return [
    for (var k = 1; k <= count; k++)
      k == count ? total - base * (count - 1) : base,
  ];
}

/// Fecha de la cuota [k] (desde 1): la primera en el mes de la compra y cada
/// una en el mes siguiente, el mismo día (recortado al largo del mes: una
/// compra del 31 tiene su cuota de febrero el 28 o 29).
DateTime installmentDate(DateTime purchase, int k) {
  final month = purchase.month + k - 1;
  final lastDay = DateTime(purchase.year, month + 1, 0).day;
  final day = purchase.day > lastDay ? lastDay : purchase.day;
  return DateTime(purchase.year, month, day, purchase.hour, purchase.minute);
}

/// Nota de la cuota [k] de [count]: "Cuota k de N", tras la nota de la
/// compra si tiene.
String installmentNote(String note, int k, int count) {
  final cuota = 'Cuota $k de $count';
  return note.isEmpty ? cuota : '$note · $cuota';
}

/// RF36: monto de cuotas por mes, desde el mes siguiente a [currentMonth].
/// Recibe (fecha, monto) de los gastos que son cuotas. Ordenado por mes.
Map<DateTime, int> committedByMonth(
    Iterable<(DateTime, int)> installments, DateTime currentMonth) {
  final from = DateTime(currentMonth.year, currentMonth.month + 1);
  final byMonth = <DateTime, int>{};
  for (final (date, amount) in installments) {
    if (date.isBefore(from)) continue;
    final month = DateTime(date.year, date.month);
    byMonth[month] = (byMonth[month] ?? 0) + amount;
  }
  return Map.fromEntries(
      byMonth.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
}
