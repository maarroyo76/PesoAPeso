/// RF56: sugerir un acceso rápido para un gasto que se repite.
library;

import 'dart:convert';

import '../../data/local/app_database.dart';
import 'history_filter.dart' show normalizeForSearch;

/// Clave en AppSettings con las combinaciones ya sugeridas (lista JSON).
const kQuickSuggestionsSeenKey = 'quick_suggestions_seen';

/// Veces que debe repetirse un gasto en [kQuickSuggestionWindowDays] días.
const kQuickSuggestionRepeats = 3;
const kQuickSuggestionWindowDays = 30;

/// Combinación monto + nota (sin tildes ni mayúsculas) de un gasto.
String quickSuggestionKey(int amount, String note) =>
    '$amount|${normalizeForSearch(note)}';

Set<String> decodeSeenSuggestions(String? json) {
  if (json == null) return {};
  try {
    return (jsonDecode(json) as List).cast<String>().toSet();
  } on Object {
    return {};
  }
}

String encodeSeenSuggestions(Set<String> seen) => jsonEncode(seen.toList());

/// El gasto [last] merece un acceso rápido si en los últimos 30 días hay al
/// menos 3 con el mismo monto y la misma nota (contándolo), la combinación
/// no se sugirió antes ([seen]) y no existe ya un acceso igual. Sin nota no
/// se sugiere: no habría con qué nombrar el acceso.
bool shouldSuggestQuickAccess({
  required Transaction last,
  required Iterable<Transaction> recent,
  required Iterable<QuickExpenseTemplate> templates,
  required Set<String> seen,
}) {
  if (last.note.trim().isEmpty) return false;
  final key = quickSuggestionKey(last.amount, last.note);
  if (seen.contains(key)) return false;
  if (templates.any((t) => quickSuggestionKey(t.amount, t.label) == key)) {
    return false;
  }
  final from =
      last.date.subtract(const Duration(days: kQuickSuggestionWindowDays));
  final repeats = recent
      .where((t) =>
          !t.date.isBefore(from) &&
          !t.date.isAfter(last.date) &&
          quickSuggestionKey(t.amount, t.note) == key)
      .length;
  return repeats >= kQuickSuggestionRepeats;
}

/// Combinación categoría + monto para sugerir un recurrente.
String recurringSuggestionKey(String categoryId, int amount) =>
    'recurrente|$categoryId|$amount';

/// Onboarding (en contexto): el gasto [last] parece un pago fijo si el mes
/// calendario anterior hubo uno con la misma categoría y el mismo monto,
/// ninguno de los dos es ya recurrente, no hay una plantilla igual y la
/// combinación no se sugirió antes.
bool shouldSuggestRecurring({
  required Transaction last,
  required Iterable<Transaction> recent,
  required Iterable<RecurringTemplate> templates,
  required Set<String> seen,
}) {
  if (last.isRecurring || last.installmentPlanId != null) return false;
  if (seen.contains(recurringSuggestionKey(last.categoryId, last.amount))) {
    return false;
  }
  if (templates
      .any((t) => t.categoryId == last.categoryId && t.amount == last.amount)) {
    return false;
  }
  final prevMonth = DateTime(last.date.year, last.date.month - 1);
  return recent.any((t) =>
      t.id != last.id &&
      !t.isRecurring &&
      t.categoryId == last.categoryId &&
      t.amount == last.amount &&
      t.date.year == prevMonth.year &&
      t.date.month == prevMonth.month);
}
