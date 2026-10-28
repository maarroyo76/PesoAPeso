// RF34: compras en cuotas con tarjeta de crédito. RF35: ver, editar y
// prepagar un plan. RF36: lo comprometido en cuotas en los meses siguientes.

import 'dart:convert';
import 'dart:ffi' show DynamicLibrary;

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqlite3/open.dart';
import 'package:peso_a_peso/core/providers/app_providers.dart';
import 'package:peso_a_peso/core/utils/installments.dart';
import 'package:peso_a_peso/data/local/app_database.dart';
import 'package:peso_a_peso/data/repositories/categories_repository.dart';
import 'package:peso_a_peso/data/repositories/installments_repository.dart';
import 'package:peso_a_peso/data/repositories/payment_methods_repository.dart';
import 'package:peso_a_peso/features/agregar_gasto/agregar_screen.dart';

void main() {
  setUpAll(() async {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    await initializeDateFormatting('es_CL', null);
  });

  group('cálculo de cuotas', () {
    test('partes iguales y el resto en la última; suman el total', () {
      expect(installmentAmounts(100000, 3), [33333, 33333, 33334]);
      expect(installmentAmounts(60000, 6), List.filled(6, 10000));
      for (final (total, n) in [(99999, 7), (1000, 48), (5, 2)]) {
        expect(installmentAmounts(total, n).reduce((a, b) => a + b), total);
      }
    });

    test('una cuota por mes, desde el de la compra, con el día recortado', () {
      final purchase = DateTime(2026, 11, 30, 14, 5);
      expect(installmentDate(purchase, 1), DateTime(2026, 11, 30, 14, 5));
      expect(installmentDate(purchase, 2), DateTime(2026, 12, 30, 14, 5));
      expect(installmentDate(purchase, 3), DateTime(2027, 1, 30, 14, 5),
          reason: 'cambio de año');
      expect(installmentDate(purchase, 4), DateTime(2027, 2, 28, 14, 5),
          reason: 'febrero no tiene 30');
    });

    test('nota "Cuota k de N"', () {
      expect(installmentNote('', 2, 6), 'Cuota 2 de 6');
      expect(installmentNote('Neumáticos', 6, 6), 'Neumáticos · Cuota 6 de 6');
    });

    test('RF36: lo comprometido por mes empieza el mes siguiente', () {
      final byMonth = committedByMonth([
        (DateTime(2026, 10, 3), 1000), // mes actual: no cuenta
        (DateTime(2026, 11, 3), 2000),
        (DateTime(2026, 11, 20), 500),
        (DateTime(2027, 1, 3), 700),
      ], DateTime(2026, 10));
      expect(byMonth, {DateTime(2026, 11): 2500, DateTime(2027, 1): 700});
    });
  });

  group('planes en la base', () {
    late AppDatabase db;
    late InstallmentsRepository repo;
    late int cardId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = InstallmentsRepository(db);
      cardId = await PaymentMethodsRepository(db).createPaymentMethod(
          alias: 'CMR', kind: kPaymentKindCredit, colorValue: 1);
    });
    tearDown(() => db.close());

    Future<int> buy({int total = 60000, int count = 6}) => repo.createPlan(
          paymentMethodId: cardId,
          categoryId: 'transporte',
          note: 'Neumáticos',
          totalAmount: total,
          count: count,
          purchaseDate: DateTime(2026, 9, 15, 12),
        );

    Future<List<Transaction>> rows(int planId) => (db.select(db.transactions)
          ..where((t) => t.installmentPlanId.equals(planId))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();

    test('RF34: genera N gastos mensuales enlazados al plan', () async {
      final planId = await buy(total: 100000, count: 3);
      final cuotas = await rows(planId);
      expect(cuotas.map((t) => t.amount), [33333, 33333, 33334]);
      expect(cuotas.map((t) => t.date.month), [9, 10, 11]);
      expect(cuotas.map((t) => t.note), [
        'Neumáticos · Cuota 1 de 3',
        'Neumáticos · Cuota 2 de 3',
        'Neumáticos · Cuota 3 de 3',
      ]);
      expect(cuotas.every((t) => t.paymentMethodId == cardId), isTrue);
      expect(cuotas.map((t) => t.installmentNumber), [1, 2, 3]);
    });

    test('RF36: lo comprometido coincide con la suma de cuotas de cada mes',
        () async {
      await buy(total: 60000, count: 6); // 10.000 de sep a feb
      await buy(total: 9000, count: 3); // 3.000 de sep a nov
      final all = await db.select(db.transactions).get();
      final byMonth = committedByMonth(
          all.map((t) => (t.date, t.amount)), DateTime(2026, 9));
      expect(byMonth, {
        DateTime(2026, 10): 13000,
        DateTime(2026, 11): 13000,
        DateTime(2026, 12): 10000,
        DateTime(2027, 1): 10000,
        DateTime(2027, 2): 10000,
      });
    });

    test('RF35: prepagar reemplaza las futuras por un pago de hoy', () async {
      final planId = await buy();
      // Hoy es 20 de noviembre: pagadas sep, oct y nov; quedan dic a feb.
      await db.prepayInstallmentPlan(planId, today: DateTime(2026, 11, 20, 9));

      final after = await rows(planId);
      expect(
          after
              .where((t) => t.installmentNumber != null)
              .map((t) => t.date.month),
          [9, 10, 11],
          reason: 'las pasadas quedan intactas');
      final prepay = after.singleWhere((t) => t.installmentNumber == null);
      expect(prepay.amount, 30000);
      expect(prepay.date, DateTime(2026, 11, 20, 9));
      expect(prepay.note, 'Neumáticos · Prepago cuotas 4 a 6 de 6');
      expect(after.fold<int>(0, (a, t) => a + t.amount), 60000,
          reason: 'el total de la compra no cambia');
      final plan = await db.select(db.installmentPlans).getSingle();
      expect(plan.prepaid, isTrue);
    });

    test('RF35: editar cambia categoría y nota de todas las cuotas', () async {
      final planId = await buy(count: 3);
      await repo.updatePlanInfo(planId, categoryId: 'ocio', note: 'Bicicleta');
      final cuotas = await rows(planId);
      expect(cuotas.every((t) => t.categoryId == 'ocio'), isTrue);
      expect(cuotas.last.note, 'Bicicleta · Cuota 3 de 3');
    });

    test('eliminar borra el plan con todas sus cuotas', () async {
      final planId = await buy();
      await repo.deletePlan(planId);
      expect(await db.select(db.transactions).get(), isEmpty);
      expect(await db.select(db.installmentPlans).get(), isEmpty);
    });

    test('la tarjeta y la categoría de un plan no se pueden eliminar',
        () async {
      await buy();
      expect(await PaymentMethodsRepository(db).canDeletePaymentMethod(cardId),
          isFalse);
      expect(await CategoriesRepository(db).canDeleteCategory('transporte'),
          isFalse);
    });

    test('el respaldo conserva los planes y el enlace de cada cuota', () async {
      final planId = await buy(count: 3);
      final data = jsonDecode(jsonEncode(await db.exportAllData()))
          as Map<String, dynamic>;
      final db2 = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db2.close);
      await db2.restoreAllData(data);
      final plan = await db2.select(db2.installmentPlans).getSingle();
      expect((plan.id, plan.installmentCount), (planId, 3));
      final linked = await (db2.select(db2.transactions)
            ..where((t) => t.installmentPlanId.equals(planId)))
          .get();
      expect(linked, hasLength(3));
    });
  });

  group('registrar en cuotas desde Agregar', () {
    // Las consultas a Drift corren con tiempo real, no con el reloj falso.
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 15; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump(const Duration(milliseconds: 10));
      }
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('con crédito y 6 cuotas crea el plan; deshacer lo elimina',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final card = (await tester.runAsync(() async {
        final id = await PaymentMethodsRepository(db).createPaymentMethod(
            alias: 'CMR', kind: kPaymentKindCredit, colorValue: 1);
        return (await db.select(db.paymentMethods).get())
            .singleWhere((m) => m.id == id);
      }))!;

      await tester.pumpWidget(ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          categoriesProvider.overrideWith((ref) => Stream.value(const [
                Category(
                    id: 'transporte',
                    name: 'Transporte',
                    colorValue: 0xFFB8842E,
                    iconKey: 'directions_car',
                    archived: false),
              ])),
          quickExpenseTemplatesProvider
              .overrideWith((ref) => Stream.value(<QuickExpenseTemplate>[])),
          paymentMethodsProvider.overrideWith((ref) => Stream.value([card])),
        ],
        child: const MaterialApp(
            home: Scaffold(body: AgregarScreen(active: false))),
      ));
      await settle(tester);

      expect(find.text('Cuotas'), findsNothing,
          reason: 'sin método de crédito elegido no se ofrecen cuotas');
      await tester.tap(find.text('CMR'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, '10000');
      await tester.enterText(find.widgetWithText(TextField, 'Cuotas'), '6');
      await tester.pump();
      await tester.tap(find.text('Valor cuota'));
      await tester.pump();
      expect(find.textContaining('6 cuotas de \$10.000'), findsOneWidget);
      expect(find.text('Gasto recurrente'), findsNothing,
          reason: 'una compra en cuotas no puede ser además recurrente');

      await tester.tap(find.text('Registrar gasto'));
      await settle(tester);
      final txs =
          (await tester.runAsync(() => db.select(db.transactions).get()))!;
      expect(txs, hasLength(6));
      expect(txs.fold<int>(0, (a, t) => a + t.amount), 60000);

      await tester.tap(find.text('Deshacer'));
      await settle(tester);
      expect(await tester.runAsync(() => db.select(db.transactions).get()),
          isEmpty);
      expect(await tester.runAsync(() => db.select(db.installmentPlans).get()),
          isEmpty);
    });
  });
}
