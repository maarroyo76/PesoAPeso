// RF64: costo de vida fijo (pagos fijos, cuotas y gastos habituales) y RF63:
// estadísticas de la lista de espera. Hoy es el 10 de noviembre de 2026.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:peso_a_peso/core/providers/app_providers.dart';
import 'package:peso_a_peso/core/utils/fixed_costs.dart';
import 'package:peso_a_peso/core/utils/habitual.dart';
import 'package:peso_a_peso/core/utils/wishlist.dart';
import 'package:peso_a_peso/data/local/app_database.dart';
import 'package:peso_a_peso/features/estadisticas/fixed_cost_section.dart';
import 'package:peso_a_peso/features/estadisticas/wishlist_stats_section.dart';

final _today = DateTime(2026, 11, 10, 9);

RecurringTemplate _fixed(int id, int amount,
        {required int lastGenerated, bool active = true}) =>
    RecurringTemplate(
      id: id,
      categoryId: 'vivienda',
      amount: amount,
      note: '',
      dayOfMonth: 20,
      active: active,
      lastGeneratedYearMonth: lastGenerated,
      mode: kRecurringModeAuto,
    );

RecurringTemplate _habitual(int id, int amount,
        {DateTime? start, bool active = true, int weekdays = 0x1F}) =>
    RecurringTemplate(
      id: id,
      categoryId: 'transporte',
      amount: amount,
      note: 'Metro',
      dayOfMonth: 0,
      active: active,
      lastGeneratedYearMonth: 0,
      mode: kRecurringModeConfirm,
      weekdays: weekdays,
      reminderTime: '08:00',
      startDate: start ?? DateTime(2026, 1, 1),
    );

Transaction _tx(int id, DateTime date, int amount,
        {bool recurring = false, int? planId, int? goalId}) =>
    Transaction(
      id: id,
      categoryId: 'otros',
      amount: amount,
      date: date,
      note: '',
      isRecurring: recurring,
      recurringTemplateId: recurring ? 1 : null,
      installmentPlanId: planId,
      installmentNumber: planId == null ? null : 1,
      fundedByGoalId: goalId,
    );

final _templates = [
  _fixed(1, 200000, lastGenerated: 202611),
  _fixed(2, 10000, lastGenerated: 202610), // aún no se carga en noviembre
  _fixed(3, 99000, lastGenerated: 202605, active: false),
  _habitual(4, 1640),
  _habitual(5, 5000, active: false),
];

final _transactions = [
  // Octubre: arriendo, una cuota, dos días de metro y un gasto variable.
  _tx(1, DateTime(2026, 10, 5), 200000, recurring: true),
  _tx(2, DateTime(2026, 10, 2), 50000, planId: 1),
  _tx(3, DateTime(2026, 10, 6, 8), 1640),
  _tx(4, DateTime(2026, 10, 7, 8), 1640),
  _tx(5, DateTime(2026, 10, 15), 30000),
  // Un gasto pagado con una meta no es del mes (RF52).
  _tx(6, DateTime(2026, 10, 20), 70000, goalId: 1),
  // Noviembre: arriendo y cuota.
  _tx(7, DateTime(2026, 11, 5), 200000, recurring: true),
  _tx(8, DateTime(2026, 11, 2), 50000, planId: 1),
  // Cuotas futuras.
  _tx(9, DateTime(2026, 12, 2), 50000, planId: 1),
  _tx(10, DateTime(2027, 1, 2), 50000, planId: 1),
];

const _habitualIds = {3, 4};

FixedCost _cost(DateTime month) => fixedCostForMonth(
      month: month,
      today: _today,
      transactions: _transactions,
      templates: _templates,
      habitualTransactionIds: _habitualIds,
    );

WishlistItem _wish(int id, int amount, String status,
        {required DateTime created, DateTime? decided}) =>
    WishlistItem(
      id: id,
      name: 'Deseo $id',
      amount: amount,
      installmentCount: 1,
      monthlyRate: 0,
      createdAt: created,
      dueAt: created.add(const Duration(days: 7)),
      status: status,
      decidedAt: decided,
    );

final _wishes = [
  _wish(1, 50000, kWishDiscarded,
      created: DateTime(2026, 10, 3), decided: DateTime(2026, 10, 10)),
  // Creado en octubre, decidido en diciembre: no suma a noviembre.
  _wish(2, 80000, kWishDiscarded,
      created: DateTime(2026, 10, 25), decided: DateTime(2026, 12, 1)),
  _wish(3, 120000, kWishBought,
      created: DateTime(2026, 11, 1), decided: DateTime(2026, 11, 8)),
  _wish(4, 30000, kWishDiscarded,
      created: DateTime(2026, 11, 2), decided: DateTime(2026, 11, 9)),
  _wish(5, 20000, kWishSaved,
      created: DateTime(2026, 11, 2), decided: DateTime(2026, 11, 9)),
  _wish(6, 60000, kWishWaiting, created: DateTime(2026, 11, 9)),
];

void main() {
  setUpAll(() => initializeDateFormatting('es_CL', null));

  group('gastos habituales esperados', () {
    test('días de la semana del mes, desde su inicio', () {
      // Noviembre de 2026 tiene 21 días hábiles; diciembre, 23.
      expect(scheduledDaysInMonth(_habitual(1, 1), DateTime(2026, 11)), 21);
      expect(scheduledDaysInMonth(_habitual(1, 1), DateTime(2026, 12)), 23);
      // Desde el lunes 16: 16–20, 23–27 y 30.
      expect(
          scheduledDaysInMonth(
              _habitual(1, 1, start: DateTime(2026, 11, 16, 8)),
              DateTime(2026, 11)),
          11);
      // Solo sábados y domingos.
      expect(
          scheduledDaysInMonth(
              _habitual(1, 1, weekdays: 0x60), DateTime(2026, 11)),
          9);
    });

    test('pausados y pagos fijos no cuentan', () {
      expect(
          scheduledDaysInMonth(
              _habitual(1, 1, active: false), DateTime(2026, 11)),
          0);
      expect(
          scheduledDaysInMonth(
              _fixed(1, 1, lastGenerated: 0), DateTime(2026, 11)),
          0);
    });
  });

  group('costo fijo por mes', () {
    test('mes pasado: lo registrado', () {
      final oct = _cost(DateTime(2026, 10));
      expect(oct.expected, isFalse);
      expect(oct.recurring, 200000);
      expect(oct.installments, 50000);
      expect(oct.habitual, 3280);
      expect(oct.total, 253280);
    });

    test('mes en curso: cargado más lo que falta y habituales esperados', () {
      final nov = _cost(_today);
      expect(nov.expected, isTrue);
      expect(nov.recurring, 200000 + 10000);
      expect(nov.installments, 50000);
      expect(nov.habitual, 1640 * 21);
      expect(nov.total, nov.recurring + nov.installments + nov.habitual);
    });

    test('mes futuro: recurrentes activos, cuotas y habituales', () {
      final dec = _cost(DateTime(2026, 12));
      expect(dec.recurring, 210000);
      expect(dec.installments, 50000);
      expect(dec.habitual, 1640 * 23);
    });

    test('porcentaje del presupuesto total; sin presupuesto, null', () {
      final nov = _cost(_today);
      expect(nov.percentOf(600000), (nov.total * 100 / 600000).round());
      expect(nov.percentOf(0), isNull);
    });

    test('evolución de 6 meses y cuotas de los 6 siguientes', () {
      final months = [
        for (var i = 5; i >= 0; i--) DateTime(2026, 11 - i),
      ];
      final trend = fixedCostTrend(
        months: months,
        today: _today,
        transactions: _transactions,
        templates: _templates,
        habitualTransactionIds: _habitualIds,
      );
      expect(trend.map((c) => c.month), months);
      expect(trend.take(4).every((c) => c.total == 0), isTrue,
          reason: 'junio a septiembre no tienen datos');
      expect(trend[4].total, 253280);

      final upcoming = committedInstallments(_transactions, _today);
      expect(upcoming.map((u) => u.month), [
        DateTime(2026, 12),
        DateTime(2027, 1),
        DateTime(2027, 2),
        DateTime(2027, 3),
        DateTime(2027, 4),
        DateTime(2027, 5),
      ]);
      expect(upcoming.map((u) => u.amount), [50000, 50000, 0, 0, 0, 0]);
    });
  });

  group('RF63: estadísticas de la lista de espera', () {
    test('comprados + descartados + esperando = deseos del mes', () {
      final s = wishlistMonthStats(_wishes, DateTime(2026, 11));
      expect(s.total, 4);
      expect(s.bought, 1);
      expect(s.discarded, 2, reason: 'incluye el que se ahorró');
      expect(s.waiting, 1);
      expect(s.bought + s.discarded + s.waiting, s.total);
      expect(s.boughtPercent, 33);
      expect(s.savedAmount, 20000);
    });

    test('lo descartado se acumula por fecha de decisión', () {
      expect(
          wishlistMonthStats(_wishes, DateTime(2026, 10)).discardedAmountToDate,
          50000);
      expect(
          wishlistMonthStats(_wishes, DateTime(2026, 11)).discardedAmountToDate,
          50000 + 30000 + 20000);
      expect(
          wishlistMonthStats(_wishes, DateTime(2026, 12)).discardedAmountToDate,
          50000 + 30000 + 20000 + 80000);
    });

    test('sin decisiones no hay porcentaje', () {
      final s = wishlistMonthStats(
          [_wish(1, 1000, kWishWaiting, created: DateTime(2026, 11, 1))],
          DateTime(2026, 11));
      expect(s.boughtPercent, isNull);
      expect(s.total, 1);
    });
  });

  group('secciones de Estadísticas', () {
    final months = [for (var i = 5; i >= 0; i--) DateTime(2026, 11 - i)];

    Widget app(List<Override> overrides, Widget child) => ProviderScope(
          overrides: overrides,
          child: MaterialApp(
              home: Scaffold(body: SingleChildScrollView(child: child))),
        );

    List<Override> data({int budget = 0}) => [
          allTransactionsProvider
              .overrideWith((ref) => Stream.value(_transactions)),
          recurringTemplatesProvider
              .overrideWith((ref) => Stream.value(_templates)),
          habitualTransactionIdsProvider
              .overrideWith((ref) => Stream.value(_habitualIds)),
          monthlyBudgetsProvider.overrideWith((ref) => Stream.value([
                if (budget > 0)
                  MonthlyBudget(year: 2026, month: 1, amount: budget),
              ])),
          monthlyAdjustmentsProvider
              .overrideWith((ref) => Stream.value(<MonthlyAdjustment>[])),
          wishlistProvider.overrideWith((ref) => Stream.value(_wishes)),
        ];

    testWidgets('RF64: un mes pasado, con su porcentaje del presupuesto',
        (tester) async {
      final oct = [for (var i = 5; i >= 0; i--) DateTime(2026, 10 - i)];
      await tester
          .pumpWidget(app(data(budget: 800000), FixedCostSection(months: oct)));
      await tester.pumpAndSettle();
      expect(find.text('Costo de vida fijo'.toUpperCase()), findsOneWidget);
      // 253.280 / 800.000 = 32 %.
      expect(
          find.bySemanticsLabel(RegExp(r'Costo fijo de Octubre de 2026: '
              r'\$253\.280, 32% de tu presupuesto total')),
          findsOneWidget);
      expect(find.text('Cuotas ya comprometidas'), findsOneWidget);
    });

    testWidgets('RF64: sin presupuesto total muestra solo el monto',
        (tester) async {
      await tester.pumpWidget(app(data(), FixedCostSection(months: months)));
      await tester.pumpAndSettle();
      expect(find.textContaining('de tu presupuesto total'), findsNothing);
      expect(find.textContaining(' al mes'), findsOneWidget);
    });

    testWidgets('RF63: resumen del mes de la lista de espera', (tester) async {
      await tester.pumpWidget(
          app(data(), WishlistStatsSection(month: DateTime(2026, 11))));
      await tester.pumpAndSettle();
      expect(
          find.text('\$100.000 que decidiste no gastar, en total',
              findRichText: true),
          findsOneWidget);
      expect(
          find.text('4 deseos este mes: 1 comprado, 2 descartados y 1 '
              'esperando.'),
          findsOneWidget);
      expect(find.text('Compraste el 33% de los que ya decidiste.'),
          findsOneWidget);
      expect(find.text('\$20.000 pasaron a tus metas.'), findsOneWidget);
    });

    testWidgets('RF63: no aparece antes de usar la lista', (tester) async {
      await tester.pumpWidget(
          app(data(), WishlistStatsSection(month: DateTime(2026, 9))));
      await tester.pumpAndSettle();
      expect(find.text('Lista de espera'.toUpperCase()), findsNothing);
    });
  });
}
