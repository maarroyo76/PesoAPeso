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

  test('recurrente del día 31 se genera el último día de un mes de 30 días',
      () async {
    await db.insertRecurringTemplate(
      categoryId: 'vivienda_test',
      amount: 250000,
      note: 'Arriendo',
      dayOfMonth: 31,
      initialYearMonth: 202603,
    );

    // 29 de abril: todavía no llega el último día, no debe generar.
    expect(await db.runRecurringCatchUp(today: DateTime(2026, 4, 29)), isEmpty);

    // 30 de abril: último día del mes, debe generar con fecha 30.
    final generated =
        await db.runRecurringCatchUp(today: DateTime(2026, 4, 30));
    expect(generated, hasLength(1));
    expect(generated.single.date, DateTime(2026, 4, 30));
  });

  test('recurrente del día 30 se genera el 28 de febrero', () async {
    await db.insertRecurringTemplate(
      categoryId: 'vivienda_test',
      amount: 1000,
      note: 'Suscripción',
      dayOfMonth: 30,
      initialYearMonth: 202601,
    );

    final generated =
        await db.runRecurringCatchUp(today: DateTime(2026, 2, 28));
    expect(generated, hasLength(1));
    expect(generated.single.date, DateTime(2026, 2, 28));
  });

  test('reactivar un recurrente pausado no genera el gasto del mes en curso',
      () async {
    await db.insertRecurringTemplate(
      categoryId: 'vivienda_test',
      amount: 250000,
      note: 'Arriendo',
      dayOfMonth: 1,
      initialYearMonth: 202601,
    );
    await db.customStatement(
        'UPDATE recurring_templates SET active = 0 WHERE category_id = ?',
        ['vivienda_test']);
    final tpl = (await db.select(db.recurringTemplates).get()).single;

    await db.updateRecurringTemplate(
      tpl.id,
      categoryId: 'vivienda_test',
      amount: 250000,
      note: 'Arriendo',
      dayOfMonth: 1,
      active: true,
      today: DateTime(2026, 5, 20),
    );

    expect(await db.runRecurringCatchUp(today: DateTime(2026, 5, 21)), isEmpty,
        reason: 'mayo ya se dio por cubierto al reactivar');
    expect(
        await db.runRecurringCatchUp(today: DateTime(2026, 6, 1)), hasLength(1),
        reason: 'junio sí se genera con normalidad');
  });

  test('editar un recurrente activo no altera lastGeneratedYearMonth',
      () async {
    await db.insertRecurringTemplate(
      categoryId: 'vivienda_test',
      amount: 1000,
      note: 'x',
      dayOfMonth: 5,
      initialYearMonth: 202601,
    );
    final tpl = (await db.select(db.recurringTemplates).get()).single;
    await db.updateRecurringTemplate(tpl.id,
        categoryId: 'vivienda_test',
        amount: 2000,
        note: 'x',
        dayOfMonth: 5,
        active: true,
        today: DateTime(2026, 5, 20));
    final after = (await db.select(db.recurringTemplates).get()).single;
    expect(after.lastGeneratedYearMonth, 202601);
    expect(after.amount, 2000);
  });

  test('contar referencias a una categoría', () async {
    expect(await db.countTransactionsForCategory('vivienda_test'), 0);
    await db.insertRecurringTemplate(
      categoryId: 'vivienda_test',
      amount: 1,
      note: '',
      dayOfMonth: 1,
      initialYearMonth: 202601,
    );
    expect(await db.countRecurringTemplatesForCategory('vivienda_test'), 1);
    expect(await db.countQuickExpenseTemplatesForCategory('vivienda_test'), 0);
  });
}
