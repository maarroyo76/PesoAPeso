// RF56: sugerir un acceso rápido cuando un gasto se repite.

import 'package:flutter_test/flutter_test.dart';
import 'package:peso_a_peso/core/utils/quick_suggestions.dart';
import 'package:peso_a_peso/data/local/app_database.dart';

Transaction _tx(int id, DateTime date,
        {int amount = 3500, String note = 'Colación'}) =>
    Transaction(
        id: id,
        categoryId: 'comida',
        amount: amount,
        date: date,
        note: note,
        isRecurring: false);

void main() {
  final last = _tx(3, DateTime(2026, 10, 28, 13));
  final recent = [
    _tx(1, DateTime(2026, 10, 2, 13), note: 'colacion'),
    _tx(2, DateTime(2026, 10, 15, 13)),
    last,
  ];

  bool suggest({
    Iterable<Transaction>? txs,
    Transaction? tx,
    List<QuickExpenseTemplate> templates = const [],
    Set<String> seen = const {},
  }) =>
      shouldSuggestQuickAccess(
          last: tx ?? last,
          recent: txs ?? recent,
          templates: templates,
          seen: seen);

  test('3 veces el mismo monto y nota en 30 días, sin importar tildes', () {
    expect(suggest(), isTrue);
  });

  test('no con 2 veces, ni fuera de los 30 días, ni con otro monto', () {
    expect(suggest(txs: recent.skip(1)), isFalse);
    expect(suggest(txs: [_tx(1, DateTime(2026, 9, 27)), ...recent.skip(1)]),
        isFalse);
    expect(
        suggest(txs: [
          _tx(1, DateTime(2026, 10, 2), amount: 4000),
          ...recent.skip(1)
        ]),
        isFalse);
  });

  test('una sola vez por combinación, aunque se rechace', () {
    final seen = {quickSuggestionKey(3500, 'Colación')};
    expect(suggest(seen: seen), isFalse);
    expect(decodeSeenSuggestions(encodeSeenSuggestions(seen)), seen);
    expect(decodeSeenSuggestions('no es json'), isEmpty);
  });

  test('no si ya existe el acceso o el gasto no tiene nota', () {
    expect(
        suggest(templates: const [
          QuickExpenseTemplate(
              id: 1, label: 'Colación', amount: 3500, categoryId: 'comida')
        ]),
        isFalse);
    final noNote = [for (final t in recent) t.copyWith(note: '')];
    expect(suggest(txs: noNote, tx: noNote.last), isFalse);
  });
}
