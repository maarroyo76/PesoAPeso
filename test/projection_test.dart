// RF58 / RNF24: proyección del disponible de los meses siguientes, con datos
// fijos. Hoy es el 10 de noviembre de 2026 salvo que el test diga otra cosa.

import 'package:flutter_test/flutter_test.dart';
import 'package:peso_a_peso/core/utils/habitual.dart';
import 'package:peso_a_peso/core/utils/installments.dart';
import 'package:peso_a_peso/core/utils/projection.dart';
import 'package:peso_a_peso/data/local/app_database.dart';

var _nextId = 1;

Transaction _tx(
  DateTime date,
  int amount, {
  String category = 'supermercado',
  bool recurring = false,
  int? templateId,
  int? planId,
  int? installmentNumber,
  int? goalId,
}) =>
    Transaction(
      id: _nextId++,
      categoryId: category,
      amount: amount,
      date: date,
      note: '',
      isRecurring: recurring,
      recurringTemplateId: templateId,
      installmentPlanId: planId,
      installmentNumber: installmentNumber,
      fundedByGoalId: goalId,
    );

RecurringTemplate _fixed(int id, int amount,
        {required int lastGenerated, int day = 5, bool active = true}) =>
    RecurringTemplate(
      id: id,
      categoryId: 'vivienda',
      amount: amount,
      note: '',
      dayOfMonth: day,
      active: active,
      lastGeneratedYearMonth: lastGenerated,
      mode: kRecurringModeAuto,
    );

RecurringTemplate _habitual(int id, int amount) => RecurringTemplate(
      id: id,
      categoryId: 'transporte',
      amount: amount,
      note: 'Metro',
      dayOfMonth: 0,
      active: true,
      lastGeneratedYearMonth: 0,
      mode: kRecurringModeConfirm,
      weekdays: 0x1F,
      reminderTime: '08:00',
      startDate: DateTime(2026, 1, 1),
    );

MonthlyBudget _budget(int year, int month, int amount) =>
    MonthlyBudget(year: year, month: month, amount: amount);

MonthlyAdjustment _adjustment(int year, int month, int amount,
        {String? category}) =>
    MonthlyAdjustment(
        id: _nextId++,
        year: year,
        month: month,
        categoryId: category,
        amount: amount,
        reason: '');

final _today = DateTime(2026, 11, 10, 15, 30);

/// Escenario base:
/// - Presupuesto total de $600.000 desde agosto.
/// - Arriendo de $200.000 (ya cargado en noviembre) y una suscripción de
///   $10.000 del día 20 (aún no se carga en noviembre). Un recurrente pausado
///   y un gasto habitual que no deben contar como recurrentes.
/// - Gasto variable de agosto, septiembre y octubre: $150.000, $300.000 (mes
///   atípico) y $180.000. Mediana: $180.000.
/// - Una compra en 4 cuotas de $50.000 de octubre a enero.
/// - Noviembre: arriendo, cuota 2, $60.000 de gasto variable y $20.000
///   aportados a una meta.
List<Transaction> _baseTransactions() => [
      for (final (month, variable) in [
        (8, 150000),
        (9, 300000),
        (10, 180000)
      ]) ...[
        _tx(DateTime(2026, month, 3), variable ~/ 3),
        _tx(DateTime(2026, month, 14), variable ~/ 3, category: 'ocio'),
        _tx(DateTime(2026, month, 25), variable - 2 * (variable ~/ 3)),
        _tx(DateTime(2026, month, 5), 200000,
            category: 'vivienda', recurring: true, templateId: 1),
      ],
      // Gasto pagado con una meta (RF52): no es gasto del presupuesto.
      _tx(DateTime(2026, 9, 20), 400000, goalId: 1),
      for (var k = 1; k <= 4; k++)
        _tx(DateTime(2026, 9 + k, 2), 50000,
            category: 'tecnologia', planId: 1, installmentNumber: k),
      _tx(DateTime(2026, 11, 5), 200000,
          category: 'vivienda', recurring: true, templateId: 1),
      _tx(DateTime(2026, 11, 3), 25000),
      _tx(DateTime(2026, 11, 8), 35000, category: 'ocio'),
    ];

List<RecurringTemplate> _baseTemplates() => [
      _fixed(1, 200000, lastGenerated: 202611),
      _fixed(2, 10000, lastGenerated: 202610, day: 20),
      _fixed(3, 99000, lastGenerated: 202605, active: false),
      _habitual(4, 1640),
    ];

Projection _project({
  DateTime? today,
  DateTime? from,
  int count = 4,
  List<Transaction>? transactions,
  List<RecurringTemplate>? templates,
  List<MonthlyBudget>? budgets,
  List<MonthlyAdjustment> adjustments = const [],
  int saved = 20000,
  Map<DateTime, int> charges = const {},
}) =>
    projectMonths(
      today: today ?? _today,
      from: from ?? today ?? _today,
      count: count,
      transactions: transactions ?? _baseTransactions(),
      templates: templates ?? _baseTemplates(),
      monthlyBudgets: budgets ?? [_budget(2026, 8, 600000)],
      adjustments: adjustments,
      savedThisMonth: saved,
      charges: charges,
    );

void main() {
  group('median', () {
    test('impar, par y vacía', () {
      expect(median([300000, 150000, 180000]), 180000);
      expect(median([100, 301]), 200);
      expect(median([7]), 7);
      expect(median(const []), 0);
    });
  });

  group('closedHistoryMonths', () {
    test('los 3 meses anteriores al mes en curso', () {
      expect(closedHistoryMonths(_baseTransactions(), DateTime(2026, 11)), [
        DateTime(2026, 8),
        DateTime(2026, 9),
        DateTime(2026, 10),
      ]);
    });

    test('cruza el año', () {
      final txs = [_tx(DateTime(2026, 6, 1), 1000)];
      expect(closedHistoryMonths(txs, DateTime(2027, 1)), [
        DateTime(2026, 10),
        DateTime(2026, 11),
        DateTime(2026, 12),
      ]);
    });

    test('solo desde el primer gasto, y no cuenta el mes en curso', () {
      final txs = [
        _tx(DateTime(2026, 10, 20), 1000),
        _tx(DateTime(2026, 11, 2), 1000),
      ];
      expect(
          closedHistoryMonths(txs, DateTime(2026, 11)), [DateTime(2026, 10)]);
      expect(
          closedHistoryMonths(
              [_tx(DateTime(2026, 11, 2), 1000)], DateTime(2026, 11)),
          isEmpty);
      expect(closedHistoryMonths(const [], DateTime(2026, 11)), isEmpty);
    });
  });

  group('projectMonths con el escenario base', () {
    final p = _project();

    test('mediana del gasto variable sin recurrentes, cuotas ni ahorro', () {
      expect(p.basis, ProjectionBasis.totalBudget);
      expect(p.historyMonths, 3);
      expect(p.expectedVariable, 180000);
      expect(p.months.map((m) => m.month), [
        DateTime(2026, 11),
        DateTime(2026, 12),
        DateTime(2027, 1),
        DateTime(2027, 2),
      ]);
    });

    test('mes en curso: parte de lo gastado y aportado', () {
      final nov = p.months[0];
      expect(nov.reference, 600000);
      // Arriendo + cuota 2 + variable + aporte a la meta.
      expect(nov.spent, 200000 + 50000 + 60000 + 20000);
      // Solo la suscripción del 20 falta por cargar.
      expect(nov.recurring, 10000);
      expect(nov.committed, 0);
      // Faltan $120.000 para llegar a la mediana de $180.000.
      expect(nov.variable, 120000);
      expect(nov.availableWithout, 140000);
    });

    test('meses futuros: presupuesto − recurrentes − cuotas − variable', () {
      final dec = p.months[1];
      expect(dec.recurring, 210000);
      expect(dec.committed, 50000);
      expect(dec.variable, 180000);
      expect(dec.spent, 0);
      expect(dec.availableWithout, 600000 - 210000 - 50000 - 180000);
      // Enero 2027 aún tiene la cuota 4; febrero ya no tiene cuotas.
      expect(p.months[2].availableWithout, 160000);
      expect(p.months[3].committed, 0);
      expect(p.months[3].availableWithout, 210000);
    });

    test('sin compra, con y sin son iguales', () {
      for (final m in p.months) {
        expect(m.purchase, 0);
        expect(m.availableWith, m.availableWithout);
        expect(m.belowZero, isFalse);
      }
    });
  });

  group('compra simulada', () {
    test('marca los meses bajo cero con el monto que falta', () {
      // $480.000 en 3 cuotas de $160.000: noviembre, diciembre y enero.
      final p = simulatePurchase(
        today: _today,
        purchaseDate: _today,
        installmentAmounts: installmentAmounts(480000, 3),
        transactions: _baseTransactions(),
        templates: _baseTemplates(),
        monthlyBudgets: [_budget(2026, 8, 600000)],
        adjustments: const [],
        savedThisMonth: 20000,
      );
      expect(p.months, hasLength(3));
      final [nov, dec, jan] = p.months;
      expect(nov.purchase, 160000);
      expect(nov.availableWith, -20000);
      expect(nov.belowZero, isTrue);
      expect(nov.shortfall, 20000);
      // Diciembre queda justo en 0: no está bajo cero.
      expect(dec.availableWith, 0);
      expect(dec.belowZero, isFalse);
      expect(dec.shortfall, 0);
      expect(jan.availableWith, 0);
    });

    test('al contado cae entera en el mes de la compra', () {
      final p = simulatePurchase(
        today: _today,
        purchaseDate: _today,
        installmentAmounts: [100000],
        transactions: _baseTransactions(),
        templates: _baseTemplates(),
        monthlyBudgets: [_budget(2026, 8, 600000)],
        adjustments: const [],
        savedThisMonth: 20000,
      );
      expect(p.months, hasLength(1));
      expect(p.months.single.purchase, 100000);
      expect(p.months.single.availableWith, 40000);
    });

    test('cuotas que cruzan de año, con compra a fin de mes', () {
      final charges = purchaseCharges(
          DateTime(2026, 11, 30), installmentAmounts(100001, 4));
      expect(charges, {
        DateTime(2026, 11): 25000,
        DateTime(2026, 12): 25000,
        DateTime(2027, 1): 25000,
        // Febrero: la cuota cae el 28 y lleva el resto de la división.
        DateTime(2027, 2): 25001,
      });
      final p = simulatePurchase(
        today: _today,
        purchaseDate: DateTime(2026, 11, 30),
        installmentAmounts: installmentAmounts(100001, 4),
        transactions: _baseTransactions(),
        templates: _baseTemplates(),
        monthlyBudgets: [_budget(2026, 8, 600000)],
        adjustments: const [],
      );
      expect(p.months.map((m) => m.month).last, DateTime(2027, 2));
      expect(p.months.fold(0, (s, m) => s + m.purchase), 100001);
    });

    test('compra planeada para un mes futuro proyecta desde ese mes', () {
      final p = simulatePurchase(
        today: _today,
        purchaseDate: DateTime(2027, 1, 15),
        installmentAmounts: installmentAmounts(60000, 2),
        transactions: _baseTransactions(),
        templates: _baseTemplates(),
        monthlyBudgets: [_budget(2026, 8, 600000)],
        adjustments: const [],
      );
      expect(
          p.months.map((m) => m.month), [DateTime(2027, 1), DateTime(2027, 2)]);
      expect(p.months.first.spent, 0);
    });

    test('pasados 12 meses, el resto va resumido', () {
      // 24 cuotas de $20.000 desde noviembre.
      final p = simulatePurchase(
        today: _today,
        purchaseDate: _today,
        installmentAmounts: installmentAmounts(480000, 24),
        transactions: _baseTransactions(),
        templates: _baseTemplates(),
        monthlyBudgets: [_budget(2026, 8, 600000), _budget(2028, 1, 150000)],
        adjustments: const [],
      );
      expect(p.months, hasLength(24));
      expect(summarizeTail(p.months.take(12).toList()), isNull);
      final tail = summarizeTail(p.months)!;
      expect(tail.months, 12);
      expect(tail.purchase, 12 * 20000);
      // Desde enero de 2028 el presupuesto baja a $150.000:
      // 150.000 − 210.000 − 180.000 − 20.000 = −260.000, durante 10 meses.
      expect(tail.monthsBelowZero, 10);
      expect(tail.totalShortfall, 10 * 260000);
      expect(tail.lowestAvailable, -260000);
    });
  });

  group('presupuesto', () {
    test('usa el presupuesto vigente de cada mes y sus ajustes', () {
      final p = _project(
        budgets: [_budget(2026, 8, 600000), _budget(2027, 1, 700000)],
        adjustments: [
          _adjustment(2026, 12, 30000),
          _adjustment(2026, 12, 5000, category: 'ocio'),
          // Un ajuste de otro mes no se hereda.
          _adjustment(2026, 10, 99000),
        ],
      );
      expect(
          p.months.map((m) => m.reference), [600000, 635000, 700000, 700000]);
    });

    test('sin presupuesto total usa la mediana del gasto total', () {
      final p = _project(budgets: const []);
      expect(p.basis, ProjectionBasis.spendingMedian);
      // Gasto total por mes (sin lo pagado con la meta):
      // ago 150.000 + 200.000; sep 300.000 + 200.000; oct 180.000 + 200.000
      // + 50.000. Mediana: 430.000.
      expect(p.months.map((m) => m.reference).toSet(), {430000});
    });

    test('sin presupuesto ni historial no hay referencia', () {
      final p = _project(
          budgets: const [],
          transactions: [_tx(DateTime(2026, 11, 2), 15000)],
          templates: const []);
      expect(p.basis, ProjectionBasis.none);
      expect(p.historyMonths, 0);
      expect(p.expectedVariable, 0);
      expect(p.months.first.reference, 0);
    });
  });

  group('meses sin historial', () {
    test('con presupuesto y sin meses cerrados el variable es 0', () {
      final p = _project(
          transactions: [_tx(DateTime(2026, 11, 2), 15000)],
          templates: const [],
          saved: 0);
      expect(p.basis, ProjectionBasis.totalBudget);
      expect(p.historyMonths, 0);
      expect(p.months[0].availableWithout, 600000 - 15000);
      expect(p.months[1].availableWithout, 600000);
    });

    test('con un solo mes cerrado la mediana es ese mes', () {
      final p = _project(
        transactions: [
          _tx(DateTime(2026, 10, 20), 90000),
          _tx(DateTime(2026, 11, 2), 100000),
        ],
        templates: const [],
        saved: 0,
      );
      expect(p.historyMonths, 1);
      expect(p.expectedVariable, 90000);
      // Noviembre ya superó la mediana: no se espera más gasto variable.
      expect(p.months[0].variable, 0);
      expect(p.months[0].availableWithout, 500000);
    });
  });

  test('enero toma octubre, noviembre y diciembre del año anterior', () {
    final p = _project(
      today: DateTime(2027, 1, 5),
      count: 2,
      transactions: [
        _tx(DateTime(2026, 9, 1), 999999),
        _tx(DateTime(2026, 10, 1), 100000),
        _tx(DateTime(2026, 11, 1), 120000),
        _tx(DateTime(2026, 12, 1), 500000),
      ],
      templates: const [],
      saved: 0,
    );
    expect(p.expectedVariable, 120000);
    expect(
        p.months.map((m) => m.month), [DateTime(2027, 1), DateTime(2027, 2)]);
  });

  test('no proyecta meses pasados', () {
    expect(() => _project(from: DateTime(2026, 10, 1)), throwsArgumentError);
  });
}
