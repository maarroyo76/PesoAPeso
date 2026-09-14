// Verifica RF12: el catch-up de gastos recurrentes genera como máximo una
// ocurrencia (la del mes actual), respeta dayOfMonth y no duplica si ya se
// generó este mes — incluso si el usuario estuvo varios meses sin abrir la
// app (sin backfill de meses saltados).

import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_a_peso/data/local/app_database.dart';
import 'package:sqlite3/open.dart';

void main() {
  setUpAll(() {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
  });

  late Directory dir;
  late AppDatabase db;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('recurring_catchup');
    db = AppDatabase.forTesting(NativeDatabase(File('${dir.path}/test.db')));
    await db.insertCategory(
        id: 'vivienda_test',
        name: 'Vivienda Test',
        colorValue: 0xFF3B6B78,
        iconKey: 'home');
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  test('genera la ocurrencia del mes actual si ya pasó dayOfMonth y falta',
      () async {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    await db.insertRecurringTemplate(
      categoryId: 'vivienda_test',
      amount: 250000,
      note: 'Arriendo',
      dayOfMonth: 1,
      initialYearMonth: lastMonth.year * 100 + lastMonth.month,
    );

    final generated = await db.runRecurringCatchUp();

    expect(generated, hasLength(1));
    expect(generated.single.amount, 250000);
    expect(generated.single.categoryId, 'vivienda_test');
    expect(generated.single.isRecurring, isTrue);

    final tpl = (await db.select(db.recurringTemplates).get()).single;
    expect(tpl.lastGeneratedYearMonth, now.year * 100 + now.month);
  });

  test('no duplica si ya se generó este mes', () async {
    final now = DateTime.now();
    await db.insertRecurringTemplate(
      categoryId: 'vivienda_test',
      amount: 250000,
      note: 'Arriendo',
      dayOfMonth: 1,
      initialYearMonth: now.year * 100 + now.month,
    );

    final generated = await db.runRecurringCatchUp();

    expect(generated, isEmpty);
    final txs = await db.select(db.transactions).get();
    expect(txs, isEmpty);
  });

  test('no genera si todavía no llega dayOfMonth', () async {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    await db.insertRecurringTemplate(
      categoryId: 'vivienda_test',
      amount: 250000,
      note: 'Arriendo',
      dayOfMonth: 28,
      initialYearMonth: lastMonth.year * 100 + lastMonth.month,
    );

    final generated = await db.runRecurringCatchUp();

    // Depende del día de hoy: si hoy es >= 28 debería generar igual.
    if (now.day < 28) {
      expect(generated, isEmpty);
    } else {
      expect(generated, hasLength(1));
    }
  });

  test('varios meses saltados: genera solo UNA ocurrencia (sin backfill)',
      () async {
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3);
    await db.insertRecurringTemplate(
      categoryId: 'vivienda_test',
      amount: 250000,
      note: 'Arriendo',
      dayOfMonth: 1,
      initialYearMonth: threeMonthsAgo.year * 100 + threeMonthsAgo.month,
    );

    final generated = await db.runRecurringCatchUp();

    expect(generated, hasLength(1),
        reason: 'no debe crear una transacción por cada mes saltado');
  });

  test('plantilla inactiva no genera nada', () async {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    await db.insertRecurringTemplate(
      categoryId: 'vivienda_test',
      amount: 250000,
      note: 'Arriendo',
      dayOfMonth: 1,
      initialYearMonth: lastMonth.year * 100 + lastMonth.month,
    );
    await db.customStatement(
        'UPDATE recurring_templates SET active = 0 WHERE category_id = ?',
        ['vivienda_test']);

    final generated = await db.runRecurringCatchUp();
    expect(generated, isEmpty);
  });
}
