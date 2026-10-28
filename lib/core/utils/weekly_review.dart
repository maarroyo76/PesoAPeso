/// RF37: revisión semanal "¿Valió la pena?". RF44: lo marcado "no tanto".
library;

import '../../data/local/app_database.dart';

/// Clave en AppSettings con la fecha (yyyy-MM-dd) de la última revisión
/// hecha u omitida.
const kWeeklyReviewSettingKey = 'weekly_review_last';

/// Días entre una revisión y la siguiente.
const kWeeklyReviewDays = 7;

/// Gastos que tiene sentido revisar: los que fueron una decisión. Se dejan
/// fuera los recurrentes y las cuotas posteriores a la primera, porque se
/// registran solos.
bool isReviewable(Transaction t) =>
    !t.isRecurring && (t.installmentPlanId == null || t.installmentNumber == 1);

/// Gastos revisables de los últimos 7 días, incluido hoy, del más reciente.
List<Transaction> weeklyReviewCandidates(
    Iterable<Transaction> transactions, DateTime today) {
  final from = DateTime(today.year, today.month, today.day)
      .subtract(const Duration(days: kWeeklyReviewDays - 1));
  final to = DateTime(today.year, today.month, today.day + 1);
  return transactions
      .where((t) =>
          isReviewable(t) && !t.date.isBefore(from) && t.date.isBefore(to))
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));
}

String reviewDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Corresponde proponer la revisión si pasó una semana desde la última
/// (hecha u omitida) y hay algún gasto de la semana sin revisar.
bool weeklyReviewDue({
  required String? lastReview,
  required DateTime today,
  required List<Transaction> candidates,
}) {
  if (!candidates.any((t) => t.worthIt == null)) return false;
  final last = lastReview == null ? null : DateTime.tryParse(lastReview);
  if (last == null) return true;
  final day = DateTime(today.year, today.month, today.day);
  return day.difference(last).inDays >= kWeeklyReviewDays;
}

/// RF44: resumen del mes. Solo cuenta gastos revisados; los revisables sin
/// revisar se informan aparte.
class WorthItSummary {
  const WorthItSummary({
    required this.notWorthByCategory,
    required this.reviewedCount,
    required this.unreviewedAmount,
    required this.unreviewedCount,
  });

  /// Monto marcado "no tanto" por categoría.
  final Map<String, int> notWorthByCategory;
  final int reviewedCount;
  final int unreviewedAmount;
  final int unreviewedCount;

  int get notWorthTotal =>
      notWorthByCategory.values.fold<int>(0, (a, b) => a + b);
}

WorthItSummary worthItSummary(Iterable<Transaction> monthTransactions) {
  final notWorth = <String, int>{};
  var reviewed = 0, unreviewedAmount = 0, unreviewedCount = 0;
  for (final t in monthTransactions.where(isReviewable)) {
    switch (t.worthIt) {
      case null:
        unreviewedAmount += t.amount;
        unreviewedCount++;
      case false:
        reviewed++;
        notWorth[t.categoryId] = (notWorth[t.categoryId] ?? 0) + t.amount;
      case true:
        reviewed++;
    }
  }
  return WorthItSummary(
    notWorthByCategory: notWorth,
    reviewedCount: reviewed,
    unreviewedAmount: unreviewedAmount,
    unreviewedCount: unreviewedCount,
  );
}
