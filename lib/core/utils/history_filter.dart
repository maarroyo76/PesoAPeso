/// UX06: búsqueda y filtros del historial completo.
library;

import '../../data/local/app_database.dart';

/// Filtro de método de pago que elige los gastos sin método.
const kUnspecifiedPaymentFilter = -1;

/// Minúsculas y sin tildes, para que "cafe" encuentre "Café".
String normalizeForSearch(String text) {
  var s = text.toLowerCase();
  const accented = 'áéíóúüñ';
  const plain = 'aeiouun';
  for (var i = 0; i < accented.length; i++) {
    s = s.replaceAll(accented[i], plain[i]);
  }
  return s.trim();
}

/// Gastos que coinciden con [query] (en la nota o el nombre de la
/// categoría), con [categoryId] y con [paymentMethodId] (o
/// [kUnspecifiedPaymentFilter]); null en un filtro = todos. Del más reciente
/// al más antiguo.
List<Transaction> filterHistory(
  Iterable<Transaction> transactions, {
  String query = '',
  String? categoryId,
  int? paymentMethodId,
  Map<String, String> categoryNames = const {},
}) {
  final q = normalizeForSearch(query);
  return transactions.where((t) {
    if (categoryId != null && t.categoryId != categoryId) return false;
    if (paymentMethodId == kUnspecifiedPaymentFilter) {
      if (t.paymentMethodId != null) return false;
    } else if (paymentMethodId != null &&
        t.paymentMethodId != paymentMethodId) {
      return false;
    }
    if (q.isEmpty) return true;
    return normalizeForSearch(t.note).contains(q) ||
        normalizeForSearch(categoryNames[t.categoryId] ?? '').contains(q);
  }).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
}

/// Agrupa por día manteniendo el orden de [transactions].
List<(DateTime, List<Transaction>)> groupByDay(List<Transaction> transactions) {
  final groups = <(DateTime, List<Transaction>)>[];
  for (final t in transactions) {
    final day = DateTime(t.date.year, t.date.month, t.date.day);
    if (groups.isEmpty || groups.last.$1 != day) groups.add((day, []));
    groups.last.$2.add(t);
  }
  return groups;
}
