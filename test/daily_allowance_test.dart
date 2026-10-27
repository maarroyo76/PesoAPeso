// RF51: Resumen separa gastado, ahorrado y disponible, y los aportes a metas
// salen del presupuesto. RF38: cuánto se puede gastar hoy.

import 'dart:ffi';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqlite3/open.dart';
import 'package:peso_a_peso/core/providers/app_providers.dart';
import 'package:peso_a_peso/core/utils/daily_allowance.dart';
import 'package:peso_a_peso/core/utils/formatting.dart';
import 'package:peso_a_peso/data/local/app_database.dart';
import 'package:peso_a_peso/features/resumen/resumen_screen.dart';

void main() {
  setUpAll(() async {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    await initializeDateFormatting('es_CL', null);
  });

  test('disponible = presupuesto − gastos − aportes', () {
    expect(
        availableThisMonth(budget: 500000, spent: 400000, saved: 50000), 50000);
    expect(availableThisMonth(budget: 500000, spent: 480000, saved: 50000),
        -30000);
  });

  group('dailyAllowance', () {
    test('reparte lo disponible entre los días que quedan, incluido hoy', () {
      // 31 de octubre: queda solo hoy.
      expect(dailyAllowance(available: 31000, today: DateTime(2026, 10, 31)),
          31000);
      // 1 de octubre: quedan 31 días.
      expect(
          dailyAllowance(available: 31000, today: DateTime(2026, 10, 1)), 1000);
      // 27 de octubre: quedan 5 días (27 al 31).
      expect(dailyAllowance(available: 50000, today: DateTime(2026, 10, 27)),
          10000);
      // Febrero no bisiesto.
      expect(
          dailyAllowance(available: 28000, today: DateTime(2027, 2, 1)), 1000);
    });

    test('con el presupuesto agotado o excedido es 0', () {
      final today = DateTime(2026, 10, 15);
      expect(dailyAllowance(available: 0, today: today), 0);
      expect(dailyAllowance(available: -5000, today: today), 0);
    });
  });

  group('tarjeta del total en Resumen', () {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);

    Future<void> pump(WidgetTester tester,
        {required int spent, required int saved}) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      const category = Category(
          id: 'ocio',
          name: 'Ocio',
          colorValue: 0xFF6B3F5C,
          iconKey: 'theaters');
      await tester.pumpWidget(ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          paymentMethodsProvider
              .overrideWith((ref) => Stream.value(<PaymentMethod>[])),
          categoriesProvider.overrideWith((ref) => Stream.value([category])),
          monthTransactionsProvider.overrideWith((ref, m) => Stream.value([
                if (m == month)
                  Transaction(
                    id: 1,
                    categoryId: 'ocio',
                    amount: spent,
                    date: DateTime(month.year, month.month, 1, 12),
                    note: '',
                    isRecurring: false,
                  ),
              ])),
          categoryBudgetsProvider
              .overrideWith((ref) => Stream.value(<CategoryBudget>[])),
          monthlyBudgetsProvider.overrideWith((ref) => Stream.value([
                MonthlyBudget(
                    year: month.year, month: month.month, amount: 500000),
              ])),
          monthlyAdjustmentsProvider
              .overrideWith((ref) => Stream.value(<MonthlyAdjustment>[])),
          monthContributedProvider
              .overrideWith((ref, m) => Stream.value(m == month ? saved : 0)),
        ],
        child: const MaterialApp(home: Scaffold(body: ResumenScreen())),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('muestra gastado, ahorrado, disponible y el monto de hoy',
        (tester) async {
      await pump(tester, spent: 400000, saved: 50000);
      expect(find.text('Gastado'), findsOneWidget);
      expect(find.text('Ahorrado'), findsOneWidget);
      expect(find.text('Disponible'), findsOneWidget);
      // El ejemplo de I2: quedan $50.000 libres, no $100.000.
      expect(find.text(currencyFmt.format(50000)), findsWidgets);
      expect(find.text(currencyFmt.format(100000)), findsNothing);
      expect(find.text('PUEDES GASTAR HOY'), findsOneWidget);
      final perDay = dailyAllowance(available: 50000, today: DateTime.now());
      expect(find.text(currencyFmt.format(perDay)), findsWidgets);
    });

    testWidgets('excedido: hoy muestra \$0 y el desglose el monto excedido',
        (tester) async {
      await pump(tester, spent: 480000, saved: 50000);
      expect(find.text('Excedido'), findsOneWidget);
      expect(find.text(currencyFmt.format(30000)), findsOneWidget);
      expect(find.text(currencyFmt.format(0)), findsOneWidget);
      expect(
          find.text('Ya usaste todo el presupuesto del mes'), findsOneWidget);
    });
  });
}
