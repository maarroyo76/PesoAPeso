// UX06: historial completo con búsqueda y filtros, agrupado por día.

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:peso_a_peso/core/utils/history_filter.dart';
import 'package:peso_a_peso/data/local/app_database.dart';
import 'package:peso_a_peso/features/historial/historial_screen.dart';

Transaction _tx(int id, DateTime date,
        {String note = '', String category = 'ocio', int? method}) =>
    Transaction(
      id: id,
      categoryId: category,
      amount: 1000 * id,
      date: date,
      note: note,
      isRecurring: false,
      paymentMethodId: method,
    );

void main() {
  setUpAll(() => initializeDateFormatting('es_CL', null));

  final txs = [
    _tx(1, DateTime(2026, 10, 26, 9), note: 'Café Juan Valdez', method: 1),
    _tx(2, DateTime(2026, 10, 27, 13), note: 'Colación', category: 'comida'),
    _tx(3, DateTime(2026, 10, 27, 20), note: 'Cine', method: 2),
    _tx(4, DateTime(2026, 10, 25, 9), category: 'comida', method: 1),
  ];
  const names = {'ocio': 'Ocio', 'comida': 'Comida fuera'};

  test('busca en la nota y en la categoría, sin tildes ni mayúsculas', () {
    expect(filterHistory(txs, query: 'cafe').map((t) => t.id), [1]);
    expect(
        filterHistory(txs, query: 'COMIDA', categoryNames: names)
            .map((t) => t.id),
        [2, 4]);
  });

  test('filtra por categoría y por método, incluido "Sin especificar"', () {
    expect(filterHistory(txs, categoryId: 'comida').map((t) => t.id), [2, 4]);
    expect(filterHistory(txs, paymentMethodId: 1).map((t) => t.id), [1, 4]);
    expect(
        filterHistory(txs, paymentMethodId: kUnspecifiedPaymentFilter)
            .map((t) => t.id),
        [2]);
  });

  test('agrupa por día, del más reciente', () {
    final groups = groupByDay(filterHistory(txs));
    expect(groups.map((g) => g.$1), [
      DateTime(2026, 10, 27),
      DateTime(2026, 10, 26),
      DateTime(2026, 10, 25),
    ]);
    expect(groups.first.$2.map((t) => t.id), [3, 2]);
  });

  test('encabezados de día', () {
    final today = DateTime(2026, 10, 28, 10);
    expect(historyDayLabel(DateTime(2026, 10, 28), today), 'Hoy');
    expect(historyDayLabel(DateTime(2026, 10, 27), today), 'Ayer');
    expect(
        historyDayLabel(DateTime(2026, 10, 26), today), 'Lunes 26 de octubre');
    expect(historyDayLabel(DateTime(2025, 12, 31), today),
        'Miércoles 31 de diciembre de 2025');
  });
}
