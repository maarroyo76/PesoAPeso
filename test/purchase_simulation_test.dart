// RF57: simular una compra sin escribir nada. RF59: alternativas, costo
// total e interés. RF60: "Comprar así" crea lo mismo que el registro a mano.

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
import 'package:peso_a_peso/core/utils/purchase_simulation.dart';
import 'package:peso_a_peso/data/local/app_database.dart';
import 'package:peso_a_peso/data/repositories/installments_repository.dart';
import 'package:peso_a_peso/data/repositories/payment_methods_repository.dart';
import 'package:peso_a_peso/features/agregar_gasto/expense_form.dart';
import 'package:peso_a_peso/features/simulador/simulador_screen.dart';

void main() {
  setUpAll(() async {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    await initializeDateFormatting('es_CL', null);
  });

  group('tasa', () {
    test('acepta coma, punto y %; vacío es sin interés', () {
      expect(parseMonthlyRatePercent(''), 0);
      expect(parseMonthlyRatePercent('1,89'), 1.89);
      expect(parseMonthlyRatePercent('1.89'), 1.89);
      expect(parseMonthlyRatePercent(' 2 %'), 2);
    });

    test('rechaza lo que no es una tasa mensual razonable', () {
      expect(parseMonthlyRatePercent('abc'), isNull);
      expect(parseMonthlyRatePercent('1,2,3'), isNull);
      expect(parseMonthlyRatePercent('-1'), isNull);
      expect(parseMonthlyRatePercent('25'), isNull, reason: 'parece anual');
    });
  });

  group('cuota fija', () {
    test('sigue P·i / (1 − (1 + i)^−n), redondeada al peso', () {
      // 1.000.000 al 2% en 12: 94.559,60 → 94.560.
      expect(fixedInstallment(1000000, 2, 12), 94560);
      // 500.000 al 1,89% en 6: 88.931,83 → 88.932.
      expect(fixedInstallment(500000, 1.89, 6), 88932);
      expect(fixedInstallment(90000, 0, 3), 30000);
    });

    test('con tasa todas las cuotas valen lo mismo y hay interés', () {
      final o = PurchaseOption(1000000, 12, ratePercent: 2);
      expect(o.amounts, List.filled(12, 94560));
      expect(o.total, 94560 * 12);
      expect(o.interest, 94560 * 12 - 1000000);
    });

    test('al contado nunca lleva interés', () {
      final o = PurchaseOption(250000, 1, ratePercent: 3);
      expect(o.isCash, isTrue);
      expect(o.amounts, [250000]);
      expect(o.interest, 0);
    });

    test('sin tasa, las cuotas son las del registro a mano', () {
      final o = PurchaseOption(100000, 3);
      expect(o.amounts, installmentAmounts(100000, 3));
      expect(o.interest, 0);
    });

    test('fuera de 1 a 48 cuotas es un error', () {
      expect(() => PurchaseOption(1000, 0), throwsArgumentError);
      expect(() => PurchaseOption(1000, 49), throwsArgumentError);
    });
  });

  group('alternativas', () {
    test('al contado, 3, 6, 12 y la elegida, sin repetir', () {
      expect(alternativeCounts(1), [1, 3, 6, 12]);
      expect(alternativeCounts(6), [1, 3, 6, 12]);
      expect(alternativeCounts(24), [1, 3, 6, 12, 24]);
      expect(alternativeCounts(2), [1, 2, 3, 6, 12]);
    });

    test('con tasa 0 el costo total es el mismo en todas', () {
      final totals = {
        for (final n in alternativeCounts(24)) PurchaseOption(499999, n).total,
      };
      expect(totals, {499999});
    });

    test('con tasa, más cuotas cuestan más', () {
      final interests = [
        for (final n in alternativeCounts(24))
          PurchaseOption(600000, n, ratePercent: 1.5).interest,
      ];
      expect(interests.first, 0);
      for (var i = 1; i < interests.length; i++) {
        expect(interests[i], greaterThan(interests[i - 1]));
      }
    });
  });

  group('pantalla', () {
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 15; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump(const Duration(milliseconds: 10));
      }
      await tester.pump(const Duration(milliseconds: 500));
    }

    /// Desmonta la pantalla y deja correr el aviso y los timers de 0 ms que
    /// Drift deja al cancelar sus streams.
    Future<void> unmount(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    }

    const category = Category(
        id: 'tecnologia',
        name: 'Tecnología',
        colorValue: 0xFF3F6E9A,
        iconKey: 'devices',
        archived: false);

    /// Abre el simulador sobre una pantalla de inicio, como desde la hoja
    /// de registro. Devuelve la base y la tarjeta.
    Future<(AppDatabase, PaymentMethod)> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final card = (await tester.runAsync(() async {
        await db.into(db.categories).insertOnConflictUpdate(category);
        final id = await PaymentMethodsRepository(db).createPaymentMethod(
            alias: 'CMR', kind: kPaymentKindCredit, colorValue: 1);
        await db.into(db.monthlyBudgets).insert(MonthlyBudgetsCompanion.insert(
            year: 2026, month: 1, amount: 800000));
        return (await db.select(db.paymentMethods).get())
            .singleWhere((m) => m.id == id);
      }))!;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          categoriesProvider
              .overrideWith((ref) => Stream.value(const [category])),
          paymentMethodsProvider.overrideWith((ref) => Stream.value([card])),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SimuladorScreen())),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await settle(tester);
      return (db, card);
    }

    Future<void> fill(WidgetTester tester,
        {required String price, String count = '', String rate = ''}) async {
      await tester.enterText(
          find.byKey(const ValueKey('simulador-precio')), price);
      await tester.enterText(find.widgetWithText(TextField, 'Cuotas'), count);
      await tester.enterText(
          find.widgetWithText(TextField, 'Interés mensual'), rate);
      await tester.tap(find.text('CMR'));
      await tester.tap(find.byType(ExpenseCategoryChip));
      await tester.enterText(
          find.widgetWithText(TextField, 'Qué es (opcional)'), 'Notebook');
      await tester.pump();
    }

    Future<List<Transaction>> transactions(
            WidgetTester tester, AppDatabase db) async =>
        (await tester.runAsync(() => (db.select(db.transactions)
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get()))!;

    testWidgets('RF57: simular no escribe nada en la base', (tester) async {
      final (db, _) = await open(tester);
      await fill(tester, price: '600.000', count: '6', rate: '1,5');
      await settle(tester);

      expect(find.text('6 cuotas de \$105.315'), findsWidgets);
      expect(find.text('Sin la compra'), findsOneWidget);
      expect(find.widgetWithText(InkWell, 'Al contado'), findsOneWidget);
      expect(find.textContaining('12 cuotas de'), findsOneWidget);

      // Elegir otra alternativa tampoco guarda nada.
      await tester.tap(find.widgetWithText(InkWell, 'Al contado'));
      await settle(tester);
      expect(await transactions(tester, db), isEmpty);
      expect(await tester.runAsync(() => db.select(db.installmentPlans).get()),
          isEmpty);
      await unmount(tester);
    });

    testWidgets('RF60: sin interés crea el mismo plan que a mano',
        (tester) async {
      final (db, card) = await open(tester);
      await fill(tester, price: '100.000', count: '3');
      await tester.tap(find.text('Comprar así'));
      await settle(tester);

      expect(find.text('Compra registrada en 3 cuotas'), findsOneWidget);
      final plan = (await tester
          .runAsync(() => db.select(db.installmentPlans).getSingle()))!;
      expect(plan.totalAmount, 100000);
      expect(plan.installmentCount, 3);
      expect(plan.paymentMethodId, card.id);
      expect(plan.categoryId, 'tecnologia');
      expect(plan.note, 'Notebook');
      final simulated = await transactions(tester, db);

      // El mismo plan registrado a mano (RF34), con la misma fecha.
      final manualId = (await tester.runAsync(() => InstallmentsRepository(db)
          .createPlan(
              paymentMethodId: card.id,
              categoryId: 'tecnologia',
              note: 'Notebook',
              totalAmount: 100000,
              count: 3,
              purchaseDate: plan.purchaseDate)))!;
      final manual = (await transactions(tester, db))
          .where((t) => t.installmentPlanId == manualId)
          .toList();
      expect(_comparable(simulated), _comparable(manual));
      await unmount(tester);
    });

    testWidgets('RF60: con interés, igual que ingresar el valor cuota',
        (tester) async {
      final (db, card) = await open(tester);
      await fill(tester, price: '1.000.000', count: '12', rate: '2');
      await tester.tap(find.text('Comprar así'));
      await settle(tester);

      final plan = (await tester
          .runAsync(() => db.select(db.installmentPlans).getSingle()))!;
      // A mano: 12 cuotas con "Valor cuota" de $94.560.
      const manual = InstallmentChoice(count: 12, amountIsPerInstallment: true);
      expect(plan.totalAmount, manual.totalFor(94560));
      final simulated = await transactions(tester, db);
      expect(simulated.map((t) => t.amount), List.filled(12, 94560));
      expect(simulated.every((t) => t.paymentMethodId == card.id), isTrue);
      await unmount(tester);
    });

    testWidgets('RF60: al contado registra un solo gasto; deshacer lo borra',
        (tester) async {
      final (db, card) = await open(tester);
      await fill(tester, price: '250.000', rate: '3');
      await tester.tap(find.text('Comprar así'));
      await settle(tester);

      final txs = await transactions(tester, db);
      expect(txs, hasLength(1));
      expect(txs.single.amount, 250000, reason: 'al contado no hay interés');
      expect(txs.single.paymentMethodId, card.id);
      expect(txs.single.installmentPlanId, isNull);
      expect(txs.single.note, 'Notebook');

      await tester.tap(find.text('Deshacer'));
      await settle(tester);
      expect(await transactions(tester, db), isEmpty);
      await unmount(tester);
    });

    testWidgets('sin categoría no deja comprar y explica por qué',
        (tester) async {
      await open(tester);
      await tester.enterText(
          find.byKey(const ValueKey('simulador-precio')), '50.000');
      await settle(tester);
      expect(find.text('Elige una categoría para registrar la compra.'),
          findsOneWidget);
      final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Comprar así'));
      expect(button.onPressed, isNull);
      await unmount(tester);
    });
  });
}

/// Lo que debe coincidir entre dos planes iguales: todo menos los ids.
List<(String, int, DateTime, String, int?, int?)> _comparable(
        List<Transaction> txs) =>
    [
      for (final t in txs)
        (
          t.categoryId,
          t.amount,
          t.date,
          t.note,
          t.paymentMethodId,
          t.installmentNumber,
        ),
    ];
