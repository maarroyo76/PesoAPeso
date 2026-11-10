/// RF37: revisión "¿Valió la pena?". RF44: lo marcado "no tanto".
/// RF66: solo de gastos no esenciales, cada semana o cada 15 días. RF67:
/// el gasto no esencial que no valió la pena.
library;

import '../../data/local/app_database.dart';
import 'essential.dart';
import 'projection.dart';

/// Clave en AppSettings con la fecha (yyyy-MM-dd) de la última revisión
/// hecha u omitida.
const kWeeklyReviewSettingKey = 'weekly_review_last';

/// Días entre una revisión y la siguiente, por defecto.
const kWeeklyReviewDays = 7;

/// RF66: clave en AppSettings con la frecuencia elegida, en días.
const kReviewFrequencySettingKey = 'review_frequency_days';

/// RF66: frecuencias que se pueden elegir: semanal o quincenal.
const kReviewFrequencies = [7, 14];

/// Frecuencia guardada en AppSettings; semanal si no hay o no es válida.
int reviewFrequencyDays(String? setting) {
  final days = int.tryParse(setting ?? '');
  return kReviewFrequencies.contains(days) ? days! : kWeeklyReviewDays;
}

/// Gastos que tiene sentido revisar: los que fueron una decisión. Se dejan
/// fuera los recurrentes y las cuotas posteriores a la primera, porque se
/// registran solos.
bool isReviewable(Transaction t) =>
    !t.isRecurring && (t.installmentPlanId == null || t.installmentNumber == 1);

/// RF66: gastos revisables de los últimos [days] días, incluido hoy, del
/// más reciente al más antiguo, solo de categorías no esenciales. La marca
/// que vale es la actual: un cambio afecta las revisiones desde ese momento.
List<Transaction> weeklyReviewCandidates(
    Iterable<Transaction> transactions, DateTime today,
    {required EssentialResolver essential, int days = kWeeklyReviewDays}) {
  final from = DateTime(today.year, today.month, today.day - (days - 1));
  final to = DateTime(today.year, today.month, today.day + 1);
  return transactions
      .where((t) =>
          isReviewable(t) &&
          !essential.isEssential(t.categoryId) &&
          !t.date.isBefore(from) &&
          t.date.isBefore(to))
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));
}

String reviewDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Corresponde proponer la revisión si pasaron [days] días desde la última
/// (hecha u omitida) y hay algún gasto del período sin revisar.
bool weeklyReviewDue({
  required String? lastReview,
  required DateTime today,
  required List<Transaction> candidates,
  int days = kWeeklyReviewDays,
}) {
  if (!candidates.any((t) => t.worthIt == null)) return false;
  final last = lastReview == null ? null : DateTime.tryParse(lastReview);
  if (last == null) return true;
  final day = DateTime(today.year, today.month, today.day);
  return day.difference(last).inDays >= days;
}

/// RF67: el gasto no esencial de un mes que no valió la pena. Solo cuenta
/// gastos revisables de categorías que eran no esenciales en la fecha del
/// gasto (RF65); los no revisados se informan aparte y no entran en el
/// porcentaje.
class WorthItSummary {
  const WorthItSummary({
    required this.month,
    required this.notWorthByCategory,
    required this.reviewedCount,
    required this.reviewedAmount,
    required this.unreviewedAmount,
    required this.unreviewedCount,
  });

  final DateTime month;

  /// Monto marcado "no tanto" por categoría.
  final Map<String, int> notWorthByCategory;
  final int reviewedCount;
  final int reviewedAmount;
  final int unreviewedAmount;
  final int unreviewedCount;

  int get notWorthTotal =>
      notWorthByCategory.values.fold<int>(0, (a, b) => a + b);

  /// Porcentaje del gasto no esencial revisado que no valió la pena; null
  /// sin gastos revisados.
  int? get notWorthPercent => reviewedAmount == 0
      ? null
      : (notWorthTotal * 100 / reviewedAmount).round();

  /// Porcentaje de los gastos no esenciales que se revisaron; null si no hay.
  int? get reviewedPercent {
    final total = reviewedCount + unreviewedCount;
    return total == 0 ? null : (reviewedCount * 100 / total).round();
  }
}

WorthItSummary worthItSummary(
    Iterable<Transaction> transactions, DateTime month,
    {required EssentialResolver essential}) {
  final m = monthOf(month);
  final notWorth = <String, int>{};
  var reviewed = 0, reviewedAmount = 0, unreviewedAmount = 0;
  var unreviewedCount = 0;
  for (final t in transactions) {
    if (t.date.year != m.year || t.date.month != m.month) continue;
    if (!isReviewable(t) || essential.isEssentialAt(t.categoryId, t.date)) {
      continue;
    }
    switch (t.worthIt) {
      case null:
        unreviewedAmount += t.amount;
        unreviewedCount++;
      case false:
        reviewed++;
        reviewedAmount += t.amount;
        notWorth[t.categoryId] = (notWorth[t.categoryId] ?? 0) + t.amount;
      case true:
        reviewed++;
        reviewedAmount += t.amount;
    }
  }
  return WorthItSummary(
    month: m,
    notWorthByCategory: notWorth,
    reviewedCount: reviewed,
    reviewedAmount: reviewedAmount,
    unreviewedAmount: unreviewedAmount,
    unreviewedCount: unreviewedCount,
  );
}
