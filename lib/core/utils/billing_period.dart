/// RF33: período de facturación de una tarjeta de crédito.
library;

/// Período de facturación: las compras entre [start] y [closing] (ambos
/// incluidos) se cobran en el estado de cuenta que cierra en [closing] y se
/// paga en [due] (null si la tarjeta no tiene día de pago).
class BillingPeriod {
  const BillingPeriod({required this.start, required this.closing, this.due});
  final DateTime start;
  final DateTime closing;
  final DateTime? due;

  /// Si [date] cae en el período (por día, sin importar la hora).
  bool contains(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(start) && !day.isAfter(closing);
  }

  @override
  bool operator ==(Object other) =>
      other is BillingPeriod &&
      other.start == start &&
      other.closing == closing &&
      other.due == due;

  @override
  int get hashCode => Object.hash(start, closing, due);

  @override
  String toString() => 'BillingPeriod($start – $closing, pago $due)';
}

/// [day] del mes [month] de [year], recortado al largo del mes (un cierre
/// el 31 cae el 30 de abril y el 28 o 29 de febrero).
DateTime _clampedDay(int year, int month, int day) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day > lastDay ? lastDay : day);
}

/// RF33: período al que pertenece una compra del día [date] en una tarjeta
/// que factura el [billingDay] de cada mes. Una compra del mismo día del
/// cierre entra en ese cierre. El pago es el primer [dueDay] posterior al
/// cierre: con cierre el 20 y pago el 5, se paga el 5 del mes siguiente.
BillingPeriod billingPeriodFor(DateTime date,
    {required int billingDay, int? dueDay}) {
  final day = DateTime(date.year, date.month, date.day);
  var closing = _clampedDay(day.year, day.month, billingDay);
  if (day.isAfter(closing)) {
    closing = _clampedDay(day.year, day.month + 1, billingDay);
  }
  final previousClosing =
      _clampedDay(closing.year, closing.month - 1, billingDay);
  DateTime? due;
  if (dueDay != null) {
    due = _clampedDay(closing.year, closing.month, dueDay);
    if (!due.isAfter(closing)) {
      due = _clampedDay(closing.year, closing.month + 1, dueDay);
    }
  }
  return BillingPeriod(
    start: previousClosing.add(const Duration(days: 1)),
    closing: closing,
    due: due,
  );
}
