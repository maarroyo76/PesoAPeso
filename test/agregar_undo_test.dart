// UX01: registrar un gasto (manual o con acceso rápido) guarda de inmediato,
// sin diálogo, y ofrece "Deshacer". UX03: preselecciona la última categoría.

import 'dart:ffi' show DynamicLibrary;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqlite3/open.dart';
import 'package:peso_a_peso/core/providers/app_providers.dart';
import 'package:peso_a_peso/data/local/app_database.dart';
import 'package:peso_a_peso/features/agregar_gasto/agregar_screen.dart';

void main() {
  setUpAll(() async {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    await initializeDateFormatting('es_CL', null);
  });

  const categories = [
    Category(
        id: 'alimentacion',
        name: 'Alimentación',
        colorValue: 0xFF2F6F4E,
        iconKey: 'restaurant'),
    Category(
        id: 'transporte',
        name: 'Transporte',
        colorValue: 0xFFB8842E,
        iconKey: 'directions_car'),
  ];
  const quick = QuickExpenseTemplate(
      id: 1, label: 'Café', amount: 2500, categoryId: 'alimentacion');

  // Las consultas a Drift corren con tiempo real, no con el reloj falso del
  // test: se les da un momento real antes de cada pump.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 15; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 10));
    }
    await tester.pump(const Duration(milliseconds: 500));
  }

  // Pantalla alta: el botón "Registrar gasto" queda bajo el pliegue en 800x600.
  void tallView(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<AppDatabase> pumpAgregar(WidgetTester tester,
      {ValueNotifier<bool>? active}) async {
    tallView(tester);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        categoriesProvider.overrideWith((ref) => Stream.value(categories)),
        quickExpenseTemplatesProvider
            .overrideWith((ref) => Stream.value([quick])),
      ],
      child: MaterialApp(
        home: Scaffold(
          // Simula entrar y salir de la pestaña Agregar.
          body: ValueListenableBuilder<bool>(
            valueListenable: active ?? ValueNotifier(false),
            builder: (_, isActive, __) => AgregarScreen(active: isActive),
          ),
        ),
      ),
    ));
    await settle(tester);
    return db;
  }

  Future<List<Transaction>> txs(WidgetTester tester, AppDatabase db) async =>
      (await tester.runAsync(() => db.select(db.transactions).get()))!;

  testWidgets('gasto manual: se guarda sin diálogo y se puede deshacer',
      (tester) async {
    final db = await pumpAgregar(tester);

    await tester.enterText(find.byType(TextField).first, '4500');
    await tester.tap(find.text('Registrar gasto'));
    await settle(tester);

    expect(find.text('Confirmar gasto'), findsNothing);
    expect(await txs(tester, db), hasLength(1));
    expect(find.text('Deshacer'), findsOneWidget);

    await tester.tap(find.text('Deshacer'));
    await settle(tester);
    expect(await txs(tester, db), isEmpty);
  });

  testWidgets('deshacer un gasto recurrente también borra su plantilla',
      (tester) async {
    final db = await pumpAgregar(tester);

    await tester.enterText(find.byType(TextField).first, '300000');
    await tester.tap(find.text('Gasto recurrente'));
    await tester.tap(find.text('Registrar gasto'));
    await settle(tester);

    final saved = await txs(tester, db);
    expect(saved.single.recurringTemplateId, isNotNull,
        reason: 'el primer gasto queda enlazado a su plantilla (I4)');

    await tester.tap(find.text('Deshacer'));
    await settle(tester);
    final templates =
        await tester.runAsync(() => db.select(db.recurringTemplates).get());
    expect(await txs(tester, db), isEmpty);
    expect(templates, isEmpty);
  });

  testWidgets('acceso rápido: un toque registra y ofrece deshacer',
      (tester) async {
    final db = await pumpAgregar(tester);

    await tester.tap(find.text('Café'));
    await settle(tester);

    expect(find.text('Confirmar gasto'), findsNothing);
    expect((await txs(tester, db)).single.amount, 2500);

    await tester.tap(find.text('Deshacer'));
    await settle(tester);
    expect(await txs(tester, db), isEmpty);
  });

  testWidgets('preselecciona la categoría del último gasto registrado',
      (tester) async {
    tallView(tester);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.runAsync(() => db.into(db.transactions).insert(
        TransactionsCompanion.insert(
            categoryId: 'transporte', amount: 790, date: DateTime.now())));

    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        categoriesProvider.overrideWith((ref) => Stream.value(categories)),
        quickExpenseTemplatesProvider
            .overrideWith((ref) => Stream.value([quick])),
      ],
      child: const MaterialApp(home: Scaffold(body: AgregarScreen())),
    ));
    await settle(tester);

    await tester.enterText(find.byType(TextField).first, '1000');
    await tester.tap(find.text('Registrar gasto'));
    await settle(tester);

    final last = (await txs(tester, db)).last;
    expect(last.categoryId, 'transporte');
    // Deja vencer el aviso y la animación de "¡Registrado!".
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('al entrar a la pestaña el monto toma el foco (UX03)',
      (tester) async {
    final active = ValueNotifier(false);
    await pumpAgregar(tester, active: active);
    bool amountFocused() => tester
        .widget<EditableText>(find.byType(EditableText).first)
        .focusNode
        .hasFocus;
    expect(amountFocused(), isFalse,
        reason: 'construida en segundo plano no debe abrir el teclado');

    active.value = true;
    await tester.pumpAndSettle();
    expect(amountFocused(), isTrue);

    active.value = false;
    await tester.pumpAndSettle();
    expect(amountFocused(), isFalse, reason: 'al salir se cierra el teclado');
  });
}
