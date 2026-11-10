/// RF65: si una categoría es esencial, y desde cuándo.
library;

import '../../data/local/app_database.dart';

/// Dice si una categoría era esencial en una fecha, según su valor actual y
/// el historial de cambios. Así cambiar la marca vale desde ese momento: los
/// gastos anteriores se siguen clasificando como estaban.
class EssentialResolver {
  EssentialResolver(
      Iterable<Category> categories, Iterable<CategoryEssentialChange> changes)
      : _current = {for (final c in categories) c.id: c.essential},
        _changes = _byCategory(changes);

  final Map<String, bool> _current;
  final Map<String, List<CategoryEssentialChange>> _changes;

  static Map<String, List<CategoryEssentialChange>> _byCategory(
      Iterable<CategoryEssentialChange> changes) {
    final map = <String, List<CategoryEssentialChange>>{};
    for (final c in changes) {
      (map[c.categoryId] ??= []).add(c);
    }
    for (final list in map.values) {
      list.sort((a, b) {
        final byDate = a.changedAt.compareTo(b.changedAt);
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });
    }
    return map;
  }

  /// Valor actual; false para una categoría desconocida.
  bool isEssential(String categoryId) => _current[categoryId] ?? false;

  /// Valor vigente en [at]: el del último cambio hasta esa fecha; antes del
  /// primer cambio, el contrario de ese primer valor; sin cambios, el actual.
  bool isEssentialAt(String categoryId, DateTime at) {
    final changes = _changes[categoryId];
    if (changes == null || changes.isEmpty) return isEssential(categoryId);
    CategoryEssentialChange? last;
    for (final c in changes) {
      if (c.changedAt.isAfter(at)) break;
      last = c;
    }
    return last?.essential ?? !changes.first.essential;
  }
}
