// Pruebas de rendimiento. RNF23: la simulación (RF57–RF59) se calcula en
// menos de 500 ms con 24 meses de historial. RNF08 y RNF12: las estadísticas
// y la consulta de un mes no se degradan con un historial extenso.
//
// Corren en el computador que ejecuta los tests (o en la CI), no en un
// teléfono de gama baja: son una cota de regresión, no la medición en
// dispositivo que piden RNF06 a RNF08.

import 'dart:ffi' show DynamicLibrary;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';
import 'package:peso_a_peso/core/utils/essential.dart';
import 'package:peso_a_peso/core/utils/fixed_costs.dart';
import 'package:peso_a_peso/core/utils/habitual.dart';
import 'package:peso_a_peso/core/utils/projection.dart';
import 'package:peso_a_peso/core/utils/purchase_simulation.dart';
import 'package:peso_a_peso/core/utils/weekly_review.dart';
import 'package:peso_a_peso/data/local/app_database.dart';

final _today = DateTime(2026, 11, 10, 12);

/// 24 meses de historial con un uso intenso: 8 gastos variables al día, un
/// arriendo al mes y una compra en 12 cuotas cada mes. Unos 6.100 gastos.
List<Transaction> _history() {
  final txs = <Transaction>[];
  var id = 1;
  var plan = 1;
  for (var m = 24; m >= 0; m--) {
    final month = DateTime(_today.year, _today.month - m);
    final days =
        m == 0 ? _today.day : DateTime(month.year, month.month + 1, 0).day;
    for (var d = 1; d <= days; d++) {
      for (var k = 0; k < 8; k++) {
        txs.add(Transaction(
          id: id++,
          categoryId: k.isEven ? 'supermercado' : 'ocio',
          amount: 1500 + 700 * k,
          date: DateTime(month.year, month.month, d, 8 + k),
          note: '',
          isRecurring: false,
          worthIt: k % 3 == 0 ? (k % 2 == 0) : null,
        ));
      }
    }
    txs.add(Transaction(
      id: id++,
      categoryId: 'vivienda',
      amount: 450000,
      date: DateTime(month.year, month.month, 5),
      note: 'Arriendo',
      isRecurring: true,
      recurringTemplateId: 1,
    ));
    for (var k = 1; k <= 12; k++) {
      txs.add(Transaction(
        id: id++,
        categoryId: 'hogar',
        amount: 20000,
        date: DateTime(month.year, month.month + k - 1, 15),
        note: '',
        isRecurring: false,
        installmentPlanId: plan,
        installmentNumber: k,
      ));
    }
    plan++;
  }
  return txs;
}

final _templates = [
  const RecurringTemplate(
      id: 1,
      categoryId: 'vivienda',
      amount: 450000,
      note: 'Arriendo',
      dayOfMonth: 5,
      active: true,
      lastGeneratedYearMonth: 202611,
      mode: kRecurringModeAuto),
  RecurringTemplate(
      id: 2,
      categoryId: 'transporte',
      amount: 1640,
      note: 'Metro',
      dayOfMonth: 0,
      active: true,
      lastGeneratedYearMonth: 0,
      mode: kRecurringModeConfirm,
      weekdays: 0x1F,
      reminderTime: '08:00',
      startDate: DateTime(2025, 1, 1)),
];

/// Mejor de 5 corridas, para no medir la compilación JIT de la primera.
Duration _best(void Function() run) {
  var best = const Duration(days: 1);
  for (var i = 0; i < 5; i++) {
    final watch = Stopwatch()..start();
    run();
    watch.stop();
    if (watch.elapsed < best) best = watch.elapsed;
  }
  return best;
}

void main() {
  final transactions = _history();
  const budgets = [MonthlyBudget(year: 2024, month: 1, amount: 1500000)];

  test('el historial de prueba tiene 24 meses y unos 6.000 gastos', () {
    expect(transactions.length, greaterThan(6000));
    expect(transactions.first.date.isBefore(DateTime(2024, 12)), isTrue);
  });

  test(
      'RNF23: simular una compra en 48 cuotas y sus 5 alternativas toma '
      'menos de 500 ms', () {
    final elapsed = _best(() {
      for (final n in alternativeCounts(48)) {
        simulatePurchase(
          today: _today,
          purchaseDate: _today,
          installmentAmounts:
              PurchaseOption(1200000, n, ratePercent: 1.9).amounts,
          transactions: transactions,
          templates: _templates,
          monthlyBudgets: budgets,
          adjustments: const [],
        );
      }
    });
    // ignore: avoid_print
    print('Simulación + alternativas: ${elapsed.inMilliseconds} ms');
    expect(elapsed, lessThan(const Duration(milliseconds: 500)));
  });

  test('RNF08: las estadísticas de 6 meses toman menos de 500 ms', () {
    final months = [for (var i = 5; i >= 0; i--) DateTime(2026, 11 - i)];
    final essential = EssentialResolver([
      for (final id in ['supermercado', 'ocio', 'vivienda', 'hogar'])
        Category(
            id: id,
            name: id,
            colorValue: 0,
            iconKey: 'x',
            archived: false,
            essential: id == 'supermercado' || id == 'vivienda'),
    ], const []);
    final elapsed = _best(() {
      fixedCostTrend(
        months: months,
        today: _today,
        transactions: transactions,
        templates: _templates,
        habitualTransactionIds: const {},
      );
      for (final m in months) {
        worthItSummary(transactions, m, essential: essential);
      }
    });
    // ignore: avoid_print
    print('Estadísticas de 6 meses: ${elapsed.inMilliseconds} ms');
    expect(elapsed, lessThan(const Duration(milliseconds: 500)));
  });

  test(
      'RNF12: consultar un mes en una base con 24 meses toma menos de '
      '200 ms', () async {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.batch((b) => b.insertAll(db.transactions, [
          for (final t in transactions)
            TransactionsCompanion.insert(
              categoryId: 'otros',
              amount: t.amount,
              date: t.date,
              isRecurring: Value(t.isRecurring),
            ),
        ]));

    var best = const Duration(days: 1);
    for (var i = 0; i < 5; i++) {
      final watch = Stopwatch()..start();
      final rows = await db.watchTransactionsForMonth(DateTime(2026, 10)).first;
      watch.stop();
      expect(rows, isNotEmpty);
      if (watch.elapsed < best) best = watch.elapsed;
    }
    // ignore: avoid_print
    print('Consulta de un mes: ${best.inMilliseconds} ms');
    expect(best, lessThan(const Duration(milliseconds: 200)));
  });
}
