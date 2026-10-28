// RF53: archivar categorías. RF54: fusionar una categoría en otra. Ambos
// corrigen I5: una categoría con historial no se podía eliminar ni ocultar.

import 'dart:convert';
import 'dart:ffi' show DynamicLibrary;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';
import 'package:peso_a_peso/core/providers/app_providers.dart';
import 'package:peso_a_peso/core/utils/budget_resolver.dart';
import 'package:peso_a_peso/data/local/app_database.dart';
import 'package:peso_a_peso/data/repositories/installments_repository.dart';
import 'package:peso_a_peso/data/repositories/payment_methods_repository.dart';
import 'package:peso_a_peso/features/categorias/categorias_screen.dart';
import 'package:peso_a_peso/features/categorias/category_filters.dart';

void main() {
  setUpAll(() {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
  });

  // Solo en los grupos de base de datos: cerrar la base en un testWidgets,
  // bajo el reloj falso, no termina nunca.
  late AppDatabase db;
  void useDatabase() {
    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());
  }

  Future<Map<String, int>> budgetsIn(DateTime month) async =>
      resolveBudgetsForMonth(await db.select(db.categoryBudgets).get(), month);

  group('RF53: archivar', () {
    useDatabase();

    test('deja de asignar presupuesto desde este mes; los pasados no cambian',
        () async {
      final oct = DateTime(2026, 10, 15);
      await db.setBudgetForMonth('ocio', DateTime(2026, 8), 60000);
      await db.archiveCategory('ocio', today: oct);

      final ocio = await (db.select(db.categories)
            ..where((c) => c.id.equals('ocio')))
          .getSingle();
      expect(ocio.archived, isTrue);
      expect((await budgetsIn(DateTime(2026, 9)))['ocio'], 60000);
      expect((await budgetsIn(DateTime(2026, 10)))['ocio'], 0);
      expect((await budgetsIn(DateTime(2026, 12)))['ocio'], 0);
    });

    test('deshacer la restaura con su presupuesto de antes', () async {
      final oct = DateTime(2026, 10, 15);
      await db.setBudgetForMonth('ocio', DateTime(2026, 8), 60000);
      final rowsBefore = await db.select(db.categoryBudgets).get();
      final undo = await db.archiveCategory('ocio', today: oct);
      await undo();

      expect(
          (await db.select(db.categories).get())
              .singleWhere((c) => c.id == 'ocio')
              .archived,
          isFalse);
      expect(await db.select(db.categoryBudgets).get(), rowsBefore);
    });

    test('no se ofrece al registrar, salvo en algo que ya la usa', () {
      const active = Category(
          id: 'a', name: 'A', colorValue: 1, iconKey: 'x', archived: false);
      const old = Category(
          id: 'b', name: 'B', colorValue: 1, iconKey: 'x', archived: true);
      expect(selectableCategories([active, old]), [active]);
      expect(selectableCategories([active, old], keep: 'b'), [active, old]);
    });

    test('un respaldo anterior a RF53 restaura las categorías activas',
        () async {
      final data = jsonDecode(jsonEncode(await db.exportAllData()))
          as Map<String, dynamic>;
      for (final c in data['categories'] as List) {
        (c as Map).remove('archived');
      }
      final db2 = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db2.close);
      await db2.restoreAllData(data);
      final restored = await db2.select(db2.categories).get();
      expect(restored, isNotEmpty);
      expect(restored.every((c) => !c.archived), isTrue);
    });
  });

  group('RF54: fusionar', () {
    useDatabase();

    test('mueve todo a la destino, elimina la original e informa cuántos',
        () async {
      final date = DateTime(2026, 10, 3);
      for (final amount in [1000, 2000]) {
        await db.into(db.transactions).insert(TransactionsCompanion.insert(
            categoryId: 'ropa', amount: amount, date: date));
      }
      await db.insertRecurringTemplate(
          categoryId: 'ropa',
          amount: 9990,
          note: 'Spotify',
          dayOfMonth: 5,
          initialYearMonth: 202610);
      await db.insertQuickExpenseTemplate(
          label: 'Polera', amount: 8000, categoryId: 'ropa');
      final card = await PaymentMethodsRepository(db).createPaymentMethod(
          alias: 'CMR', kind: kPaymentKindCredit, colorValue: 1);
      await InstallmentsRepository(db).createPlan(
          paymentMethodId: card,
          categoryId: 'ropa',
          note: 'Zapatillas',
          totalAmount: 60000,
          count: 3,
          purchaseDate: date);
      await db.insertAdjustment(
          month: date, categoryId: 'ropa', amount: 5000, reason: 'x');

      final moved = await db.mergeCategory('ropa', 'ocio');

      expect(moved, 5, reason: '2 gastos y 3 cuotas');
      expect((await db.select(db.categories).get()).map((c) => c.id),
          isNot(contains('ropa')));
      for (final categoryIds in [
        (await db.select(db.transactions).get()).map((t) => t.categoryId),
        (await db.select(db.recurringTemplates).get()).map((t) => t.categoryId),
        (await db.select(db.installmentPlans).get()).map((p) => p.categoryId),
        (await db.select(db.monthlyAdjustments).get()).map((a) => a.categoryId),
      ]) {
        expect(categoryIds.toSet(), {'ocio'});
      }
      expect(
          (await db.select(db.quickExpenseTemplates).get())
              .singleWhere((q) => q.label == 'Polera')
              .categoryId,
          'ocio');
    });

    test('los presupuestos se suman en cada mes', () async {
      await db.delete(db.categoryBudgets).go();
      await db.setBudgetForMonth('ocio', DateTime(2026, 6), 60000);
      await db.setBudgetForMonth('ropa', DateTime(2026, 8), 50000);
      await db.setBudgetForMonth('ocio', DateTime(2026, 10), 70000);

      await db.mergeCategory('ropa', 'ocio');

      expect((await budgetsIn(DateTime(2026, 6)))['ocio'], 60000);
      expect((await budgetsIn(DateTime(2026, 7)))['ocio'], 60000);
      expect((await budgetsIn(DateTime(2026, 8)))['ocio'], 110000);
      expect((await budgetsIn(DateTime(2026, 9)))['ocio'], 110000);
      expect((await budgetsIn(DateTime(2026, 11)))['ocio'], 120000);
      expect(
          (await budgetsIn(DateTime(2026, 11))).containsKey('ropa'), isFalse);
    });

    test('no se fusiona una categoría en sí misma', () async {
      expect(() => db.mergeCategory('ocio', 'ocio'), throwsArgumentError);
    });
  });

  group('pantalla Categorías', () {
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump(const Duration(milliseconds: 10));
      }
    }

    testWidgets('eliminar una con gastos ofrece archivarla', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() => tester.runAsync(db.close));
      await tester.runAsync(() => db.into(db.transactions).insert(
          TransactionsCompanion.insert(
              categoryId: 'salud', amount: 4000, date: DateTime(2026, 10))));

      await tester.pumpWidget(ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: CategoriasScreen()),
      ));
      await settle(tester);
      // Una instalación nueva ya trae archivadas las categorías que el
      // onboarding no preselecciona.
      expect(find.text('ARCHIVADAS'), findsOneWidget);

      await tester.tap(find.byTooltip('Opciones de Salud'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await settle(tester);
      await tester.pumpAndSettle();
      expect(find.text('No se puede eliminar'), findsOneWidget);

      await tester.tap(find.text('Archivar'));
      await tester.pumpAndSettle();
      await settle(tester);
      expect(find.text('ARCHIVADAS'), findsOneWidget);
      expect(find.text('"Salud" archivada'), findsOneWidget);
      final salud =
          (await tester.runAsync(() => db.select(db.categories).get()))!
              .singleWhere((c) => c.id == 'salud');
      expect(salud.archived, isTrue);
      // Desmonta la pantalla antes de terminar: al cancelar sus streams,
      // Drift deja un timer de 0 ms que hay que dejar correr.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
