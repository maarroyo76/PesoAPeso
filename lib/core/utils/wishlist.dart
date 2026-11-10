/// RF61/RF62: plazos de la lista de espera.
library;

import '../../data/local/app_database.dart';

/// Plazos de espera que se pueden elegir (RF61).
enum WaitPeriod {
  hours48(Duration(hours: 48), '48 horas'),
  days7(Duration(days: 7), '7 días'),
  days30(Duration(days: 30), '30 días');

  const WaitPeriod(this.duration, this.label);
  final Duration duration;
  final String label;

  /// El plazo que corresponde a un deseo ya guardado (el más cercano, por
  /// si el reloj cambió de horario en medio).
  static WaitPeriod of(WishlistItem wish) {
    final length = wish.dueAt.difference(wish.createdAt);
    return values.reduce((a, b) =>
        (a.duration - length).abs() <= (b.duration - length).abs() ? a : b);
  }
}

/// Fin del plazo de espera que empieza en [from]. Se suma en días de
/// calendario (no en horas) para que el cambio de horario no corra la hora.
DateTime wishDueAt(DateTime from, WaitPeriod period) => switch (period) {
      WaitPeriod.hours48 =>
        DateTime(from.year, from.month, from.day + 2, from.hour, from.minute),
      WaitPeriod.days7 =>
        DateTime(from.year, from.month, from.day + 7, from.hour, from.minute),
      WaitPeriod.days30 =>
        DateTime(from.year, from.month, from.day + 30, from.hour, from.minute),
    };

bool isWaiting(WishlistItem wish) => wish.status == kWishWaiting;

/// RF62: el plazo ya venció y el usuario todavía no decide.
bool isWishDue(WishlistItem wish, DateTime now) =>
    isWaiting(wish) && !wish.dueAt.isAfter(now);

/// RF62: deseos vencidos sin decidir, los más antiguos primero.
List<WishlistItem> dueWishes(Iterable<WishlistItem> wishes, DateTime now) =>
    wishes.where((w) => isWishDue(w, now)).toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));

/// RF61: cuánto falta para que venza el plazo, en la unidad más útil:
/// días desde 48 horas, horas desde 1 hora y minutos al final.
String timeLeftLabel(DateTime dueAt, DateTime now) {
  final left = dueAt.difference(now);
  if (left <= Duration.zero) return 'Plazo cumplido';
  if (left.inHours >= 48) {
    final days = (left.inHours / 24).ceil();
    return 'Faltan $days días';
  }
  if (left.inHours >= 1) {
    final hours = (left.inMinutes / 60).ceil();
    return hours == 1 ? 'Falta 1 hora' : 'Faltan $hours horas';
  }
  final minutes = left.inMinutes < 1 ? 1 : left.inMinutes;
  return minutes == 1 ? 'Falta 1 minuto' : 'Faltan $minutes minutos';
}

/// RF63: resumen de la lista de espera para un mes. Cuenta los deseos
/// creados en ese mes (así comprados + descartados + esperando = total), y
/// aparte el monto descartado acumulado hasta el fin del mes.
class WishlistMonthStats {
  const WishlistMonthStats({
    required this.total,
    required this.bought,
    required this.discarded,
    required this.waiting,
    required this.savedAmount,
    required this.discardedAmountToDate,
  });

  /// Deseos creados en el mes.
  final int total;
  final int bought;

  /// Descartados, incluidos los que se ahorraron en una meta.
  final int discarded;

  /// Los que todavía no se deciden.
  final int waiting;

  /// Monto llevado a metas desde los deseos del mes.
  final int savedAmount;

  /// Lo que se dejó de gastar (descartado o ahorrado) desde que se usa la
  /// lista hasta el fin del mes.
  final int discardedAmountToDate;

  int get decided => bought + discarded;

  /// Porcentaje de los deseos decididos que se compraron; null si ninguno se
  /// decidió todavía.
  int? get boughtPercent =>
      decided == 0 ? null : (bought * 100 / decided).round();
}

bool _isDiscarded(WishlistItem w) =>
    w.status == kWishDiscarded || w.status == kWishSaved;

WishlistMonthStats wishlistMonthStats(
    Iterable<WishlistItem> wishes, DateTime month) {
  bool inMonth(DateTime d) => d.year == month.year && d.month == month.month;
  final end = DateTime(month.year, month.month + 1);
  final ofMonth = wishes.where((w) => inMonth(w.createdAt)).toList();
  return WishlistMonthStats(
    total: ofMonth.length,
    bought: ofMonth.where((w) => w.status == kWishBought).length,
    discarded: ofMonth.where(_isDiscarded).length,
    waiting: ofMonth.where(isWaiting).length,
    savedAmount: ofMonth
        .where((w) => w.status == kWishSaved)
        .fold(0, (s, w) => s + w.amount),
    discardedAmountToDate: wishes
        .where((w) =>
            _isDiscarded(w) &&
            w.decidedAt != null &&
            w.decidedAt!.isBefore(end))
        .fold(0, (s, w) => s + w.amount),
  );
}
