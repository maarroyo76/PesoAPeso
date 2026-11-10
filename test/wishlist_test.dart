// RF61: lista de espera (crear, editar, eliminar, plazo). RF62: al vencer,
// tarjeta en Resumen con la simulación recalculada y las decisiones
// comprar, descartar o ahorrar en una meta.

import 'dart:ffi' show DynamicLibrary;
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:peso_a_peso/core/providers/app_providers.dart';
import 'package:peso_a_peso/core/utils/wishlist.dart';
import 'package:peso_a_peso/data/backup/backup_validation.dart';
import 'package:peso_a_peso/data/local/app_database.dart';
import 'package:peso_a_peso/data/repositories/installments_repository.dart';
import 'package:peso_a_peso/data/repositories/payment_methods_repository.dart';
import 'package:peso_a_peso/data/repositories/wishlist_repository.dart';
import 'package:peso_a_peso/features/agregar_gasto/expense_form.dart';
import 'package:peso_a_peso/features/lista_espera/wish_decision_card.dart';
import 'package:peso_a_peso/features/simulador/simulador_screen.dart';

WishlistItem _wish({
  int id = 1,
  String status = kWishWaiting,
  required DateTime createdAt,
  required DateTime dueAt,
}) =>
    WishlistItem(
      id: id,
      name: 'Audífonos',
      amount: 90000,
      installmentCount: 3,
      monthlyRate: 0,
      createdAt: createdAt,
      dueAt: dueAt,
      status: status,
    );

void main() {
  setUpAll(() async {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    await initializeDateFormatting('es_CL', null);
  });

  group('plazos', () {
    final created = DateTime(2026, 11, 10, 21, 15);

    test('48 horas, 7 días y 30 días, a la misma hora', () {
      expect(wishDueAt(created, WaitPeriod.hours48),
          DateTime(2026, 11, 12, 21, 15));
      expect(
          wishDueAt(created, WaitPeriod.days7), DateTime(2026, 11, 17, 21, 15));
      expect(
          wishDueAt(created, WaitPeriod.days30), DateTime(2026, 12, 10, 21, 15),
          reason: 'cruza de mes');
    });

    test('el plazo de un deseo guardado se reconoce', () {
      for (final p in WaitPeriod.values) {
        final w = _wish(createdAt: created, dueAt: wishDueAt(created, p));
        expect(WaitPeriod.of(w), p);
      }
    });

    test('cuánto falta', () {
      final due = DateTime(2026, 11, 17, 21, 15);
      expect(
          timeLeftLabel(due, DateTime(2026, 11, 10, 21, 15)), 'Faltan 7 días');
      expect(timeLeftLabel(due, DateTime(2026, 11, 15, 22)), 'Faltan 48 horas');
      expect(
          timeLeftLabel(due, DateTime(2026, 11, 17, 20, 15)), 'Falta 1 hora');
      expect(timeLeftLabel(due, DateTime(2026, 11, 17, 21, 5)),
          'Faltan 10 minutos');
      expect(timeLeftLabel(due, due), 'Plazo cumplido');
    });

    test('vencidos: solo los que esperan, los más antiguos primero', () {
      final now = DateTime(2026, 11, 20);
      final wishes = [
        _wish(
            id: 1,
            createdAt: DateTime(2026, 11, 10),
            dueAt: DateTime(2026, 11, 17)),
        _wish(
            id: 2,
            createdAt: DateTime(2026, 11, 10),
            dueAt: DateTime(2026, 11, 12)),
        _wish(
            id: 3,
            createdAt: DateTime(2026, 11, 19),
            dueAt: DateTime(2026, 11, 21)),
        _wish(
            id: 4,
            status: kWishDiscarded,
            createdAt: DateTime(2026, 11, 1),
            dueAt: DateTime(2026, 11, 3)),
      ];
      expect(dueWishes(wishes, now).map((w) => w.id), [2, 1]);
    });
  });

  group('base de datos', () {
    late AppDatabase db;
    late WishlistRepository repo;
    final created = DateTime(2026, 11, 10, 12);

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = WishlistRepository(db);
    });
    tearDown(() => db.close());

    Future<int> createWish({int? cardId, String? categoryId}) => repo.create(
          name: 'Audífonos',
          amount: 90000,
          installmentCount: 3,
          monthlyRate: 1.5,
          paymentMethodId: cardId,
          categoryId: categoryId,
          createdAt: created,
          dueAt: wishDueAt(created, WaitPeriod.days7),
        );

    Future<WishlistItem> get(int id) =>
        (db.select(db.wishlistItems)..where((w) => w.id.equals(id)))
            .getSingle();

    test('RF61: crear, editar y eliminar (con deshacer)', () async {
      final id = await createWish();
      var w = await get(id);
      expect(w.status, kWishWaiting);
      expect(w.monthlyRate, 1.5);

      await repo.update(id,
          name: 'Audífonos inalámbricos',
          amount: 85000,
          installmentCount: 1,
          dueAt: wishDueAt(created, WaitPeriod.days30));
      w = await get(id);
      expect(w.name, 'Audífonos inalámbricos');
      expect(w.amount, 85000);
      expect(w.installmentCount, 1);
      expect(w.dueAt, DateTime(2026, 12, 10, 12));
      expect(w.createdAt, created);

      final restore = await repo.deleteUndoable(id);
      expect(await db.select(db.wishlistItems).get(), isEmpty);
      await restore();
      expect((await get(id)).name, 'Audífonos inalámbricos');
    });

    test('RF62: descartar y volver a la espera', () async {
      final id = await createWish();
      final at = DateTime(2026, 11, 18);
      await repo.discard(id, at: at);
      var w = await get(id);
      expect(w.status, kWishDiscarded);
      expect(w.decidedAt, at);
      await repo.reset(id);
      w = await get(id);
      expect(w.status, kWishWaiting);
      expect(w.decidedAt, isNull);
    });

    test('RF62: ahorrarlo aporta el monto a la meta; deshacer lo quita',
        () async {
      final goalId = await db.into(db.savingsGoals).insert(
          SavingsGoalsCompanion.insert(name: 'Viaje', targetAmount: 500000));
      final id = await createWish();
      final undo =
          await repo.saveToGoal(id, goalId: goalId, at: DateTime(2026, 11, 18));
      final w = await get(id);
      expect(w.status, kWishSaved);
      final contribution = await db.select(db.savingsContributions).getSingle();
      expect(contribution.id, w.contributionId);
      expect(contribution.amount, 90000);
      expect(contribution.goalId, goalId);
      expect(contribution.note, 'Lista de espera: Audífonos');

      await undo();
      expect(await db.select(db.savingsContributions).get(), isEmpty);
      expect((await get(id)).status, kWishWaiting);
    });

    test('borrar la tarjeta, el plan o la meta no deja enlaces rotos',
        () async {
      final cardId = await PaymentMethodsRepository(db).createPaymentMethod(
          alias: 'CMR', kind: kPaymentKindCredit, colorValue: 1);
      final waitingId = await createWish(cardId: cardId);
      final boughtId = await createWish(cardId: cardId);
      final plans = InstallmentsRepository(db);
      final planId = await plans.createPlan(
          paymentMethodId: cardId,
          categoryId: 'transporte',
          note: '',
          totalAmount: 90000,
          count: 3,
          purchaseDate: created);
      await repo.markBought(boughtId, installmentPlanId: planId);

      await plans.deletePlan(planId);
      expect((await get(boughtId)).installmentPlanId, isNull);
      await db.deletePaymentMethod(cardId);
      expect((await get(waitingId)).paymentMethodId, isNull);
    });

    test('fusionar la categoría mueve también los deseos', () async {
      final id = await createWish(categoryId: 'transporte');
      final other = (await db.select(db.categories).get())
          .firstWhere((c) => c.id != 'transporte');
      await db.mergeCategory('transporte', other.id);
      expect((await get(id)).categoryId, other.id);
    });

    test('el respaldo v4 conserva la lista de espera', () async {
      final goalId = await db.into(db.savingsGoals).insert(
          SavingsGoalsCompanion.insert(name: 'Viaje', targetAmount: 500000));
      final saved = await createWish(categoryId: 'transporte');
      await repo.saveToGoal(saved, goalId: goalId);
      await createWish();
      final data = await db.exportAllData();
      expect(data['version'], 4);
      validateBackupData(data);

      await db.restoreAllData(data);
      final rows = await db.select(db.wishlistItems).get();
      expect(rows, hasLength(2));
      expect(rows.firstWhere((w) => w.id == saved).contributionId, isNotNull);
    });

    test('un respaldo v3 (sin lista de espera) se sigue aceptando', () async {
      await createWish();
      final data = await db.exportAllData()
        ..['version'] = 3
        ..remove('wishlistItems');
      validateBackupData(data);
      await db.restoreAllData(data);
      expect(await db.select(db.wishlistItems).get(), isEmpty);
    });

    test(
        'un respaldo con un deseo que apunta a una meta inexistente se rechaza',
        () async {
      await createWish();
      final data = await db.exportAllData();
      (data['wishlistItems'] as List).cast<Map<String, dynamic>>().single
        ..['status'] = kWishSaved
        ..['contributionId'] = 999;
      expect(() => validateBackupData(data), throwsFormatException);
    });
  });

  test('migración v11 → v12 crea la tabla y conserva los datos', () async {
    final dir = await Directory.systemTemp.createTemp('migration_v12');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/v11.db');

    // Una base actual sin lo agregado en v12 y v13 queda igual a una v11.
    final current = AppDatabase.forTesting(NativeDatabase(file));
    await current.into(current.transactions).insert(
        TransactionsCompanion.insert(
            categoryId: 'transporte', amount: 1640, date: DateTime(2026, 11)));
    await current.close();
    final raw = sqlite3.sqlite3.open(file.path);
    raw.execute('''
      DROP TABLE wishlist_items;
      DROP TABLE category_essential_changes;
      ALTER TABLE categories DROP COLUMN essential;
      PRAGMA user_version = 11;
    ''');
    raw.dispose();

    final migrated = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(migrated.close);
    expect((await migrated.select(migrated.transactions).get()).single.amount,
        1640);
    await migrated.into(migrated.wishlistItems).insert(
        WishlistItemsCompanion.insert(
            name: 'Bicicleta',
            amount: 250000,
            createdAt: DateTime(2026, 11, 10),
            dueAt: DateTime(2026, 12, 10)));
    expect((await migrated.select(migrated.wishlistItems).getSingle()).status,
        kWishWaiting);
  });

  group('pantallas', () {
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 15; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump(const Duration(milliseconds: 10));
      }
      await tester.pump(const Duration(milliseconds: 500));
    }

    Future<void> unmount(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    }

    const category = Category(
        id: 'tecnologia',
        name: 'Tecnología',
        colorValue: 0xFF3F6E9A,
        iconKey: 'devices',
        archived: false,
        essential: false);

    Future<(AppDatabase, PaymentMethod)> setUpDb(WidgetTester tester) async {
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
      return (db, card);
    }

    Widget app(AppDatabase db, PaymentMethod card, Widget home) =>
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            categoriesProvider
                .overrideWith((ref) => Stream.value(const [category])),
            paymentMethodsProvider.overrideWith((ref) => Stream.value([card])),
          ],
          child: MaterialApp(home: home),
        );

    Future<List<WishlistItem>> wishes(
            WidgetTester tester, AppDatabase db) async =>
        (await tester.runAsync(() => db.select(db.wishlistItems).get()))!;

    testWidgets('RF60/RF61: "Esperar" guarda la simulación en la lista',
        (tester) async {
      final (db, card) = await setUpDb(tester);
      await tester.pumpWidget(app(
        db,
        card,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SimuladorScreen())),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await settle(tester);

      await tester.enterText(
          find.byKey(const ValueKey('simulador-precio')), '300.000');
      await tester.enterText(find.widgetWithText(TextField, 'Cuotas'), '6');
      await tester.enterText(
          find.widgetWithText(TextField, 'Interés mensual'), '1,5');
      await tester.tap(find.text('CMR'));
      await tester.tap(find.byType(ExpenseCategoryChip));
      await tester.enterText(
          find.widgetWithText(TextField, 'Qué es (opcional)'), 'Bicicleta');
      await tester.pump();
      await tester.tap(find.text('Esperar'));
      await settle(tester);
      expect(find.text('Dejarlo en espera'), findsOneWidget);
      await tester.tap(find.text('48 horas'));
      await tester.pump();
      await tester.tap(find.text('Guardar en la lista de espera'));
      await settle(tester);

      final w = (await wishes(tester, db)).single;
      expect(w.name, 'Bicicleta');
      expect(w.amount, 300000);
      expect(w.installmentCount, 6);
      expect(w.monthlyRate, 1.5);
      expect(w.paymentMethodId, card.id);
      expect(w.categoryId, 'tecnologia');
      expect(WaitPeriod.of(w), WaitPeriod.hours48);
      expect(await tester.runAsync(() => db.select(db.transactions).get()),
          isEmpty,
          reason: 'esperar no registra ningún gasto');
      expect(find.textContaining('En espera hasta el'), findsOneWidget);

      await tester.tap(find.text('Deshacer'));
      await settle(tester);
      expect(await wishes(tester, db), isEmpty);
      await unmount(tester);
    });

    Future<int> insertWish(WidgetTester tester, AppDatabase db,
            {required DateTime dueAt, int? cardId}) async =>
        (await tester.runAsync(() => WishlistRepository(db).create(
              name: 'Audífonos',
              amount: 90000,
              installmentCount: cardId == null ? 1 : 3,
              paymentMethodId: cardId,
              categoryId: 'tecnologia',
              createdAt: dueAt.subtract(const Duration(days: 7)),
              dueAt: dueAt,
            )))!;

    Widget cards(AppDatabase db, PaymentMethod card) => app(db, card,
        const Scaffold(body: SingleChildScrollView(child: DueWishesCards())));

    testWidgets('RF62: la tarjeta sale solo al vencer; descartar la quita',
        (tester) async {
      final (db, card) = await setUpDb(tester);
      final now = DateTime.now();
      await insertWish(tester, db, dueAt: now.add(const Duration(hours: 3)));
      final dueId = await insertWish(tester, db,
          dueAt: now.subtract(const Duration(minutes: 1)));
      await tester.pumpWidget(cards(db, card));
      await settle(tester);

      expect(find.text('¿Todavía quieres "Audífonos"?'), findsOneWidget,
          reason: 'solo el deseo vencido');
      expect(
          find.textContaining('Con tus datos de hoy: Alcanza'), findsOneWidget);
      expect(find.text('Ahorrarlo en una meta'), findsNothing,
          reason: 'sin metas no se ofrece');

      await tester.tap(find.text('Descartar'));
      await settle(tester);
      expect(find.text('¿Todavía quieres "Audífonos"?'), findsNothing);
      final discarded =
          (await wishes(tester, db)).singleWhere((w) => w.id == dueId);
      expect(discarded.status, kWishDiscarded);

      await tester.tap(find.text('Deshacer'));
      await settle(tester);
      expect(find.text('¿Todavía quieres "Audífonos"?'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('RF62: ahorrarlo con una sola meta aporta el monto',
        (tester) async {
      final (db, card) = await setUpDb(tester);
      await tester.runAsync(() => db.into(db.savingsGoals).insert(
          SavingsGoalsCompanion.insert(name: 'Viaje', targetAmount: 500000)));
      final id = await insertWish(tester, db,
          dueAt: DateTime.now().subtract(const Duration(hours: 1)));
      await tester.pumpWidget(cards(db, card));
      await settle(tester);

      await tester.tap(find.text('Ahorrarlo en una meta'));
      await settle(tester);
      final w = (await wishes(tester, db)).singleWhere((w) => w.id == id);
      expect(w.status, kWishSaved);
      final c = (await tester
          .runAsync(() => db.select(db.savingsContributions).getSingle()))!;
      expect(c.amount, 90000);
      expect(find.textContaining('aportados a "Viaje"'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('RF62: comprar abre el simulador lleno y marca el deseo',
        (tester) async {
      final (db, card) = await setUpDb(tester);
      final id = await insertWish(tester, db,
          dueAt: DateTime.now().subtract(const Duration(hours: 1)),
          cardId: card.id);
      await tester.pumpWidget(cards(db, card));
      await settle(tester);

      await tester.tap(find.text('Comprar'));
      await settle(tester);
      expect(find.text('Comprar "Audífonos"'), findsOneWidget);
      expect(find.text('3 cuotas de \$30.000'), findsWidgets,
          reason: 'el formulario viene con los datos del deseo');
      expect(find.text('Esperar'), findsNothing);

      await tester.tap(find.text('Comprar así'));
      await settle(tester);
      final plan = (await tester
          .runAsync(() => db.select(db.installmentPlans).getSingle()))!;
      expect(plan.totalAmount, 90000);
      expect(plan.categoryId, 'tecnologia');
      final w = (await wishes(tester, db)).singleWhere((w) => w.id == id);
      expect(w.status, kWishBought);
      expect(w.installmentPlanId, plan.id);
      expect(find.text('¿Todavía quieres "Audífonos"?'), findsNothing);

      // Deshacer borra el plan y devuelve el deseo a la espera.
      await tester.tap(find.text('Deshacer'));
      await settle(tester);
      expect(await tester.runAsync(() => db.select(db.installmentPlans).get()),
          isEmpty);
      expect((await wishes(tester, db)).single.status, kWishWaiting);
      await unmount(tester);
    });
  });
}
