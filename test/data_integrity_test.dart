// Verifica las correcciones de integridad de datos: pragma de claves foráneas,
// borrados y catch-up de recurrentes todo-o-nada, validación de respaldos sin
// tocar la base, y que los gastos generados por el catch-up no muestren una
// hora inventada.

import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_a_peso/core/utils/formatting.dart';
import 'package:peso_a_peso/data/local/app_database.dart';
import 'package:peso_a_peso/data/repositories/backup_repository.dart';
import 'package:sqlite3/open.dart';

void main() {
  setUpAll(() {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
  });

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.insertCategory(
        id: 'cat_test', name: 'Test', colorValue: 0xFF3B6B78, iconKey: 'home');
  });

  tearDown(() => db.close());

  test('el pragma de claves foráneas queda activo al abrir', () async {
    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(row.data.values.single, 1);
  });

  test('deleteCategory es todo o nada', () async {
    final now = DateTime.now();
    await db.setBudgetForMonth('cat_test', now, 50000);
    // Fuerza un fallo en el segundo delete (el de la categoría) para
    // comprobar que el primero (sus presupuestos) se revierte.
    await db.customStatement('''
      CREATE TRIGGER block_category_delete BEFORE DELETE ON categories
      BEGIN SELECT RAISE(ABORT, 'bloqueado'); END
    ''');

    await expectLater(db.deleteCategory('cat_test'), throwsA(anything));

    final budgets = await (db.select(db.categoryBudgets)
          ..where((b) => b.categoryId.equals('cat_test')))
        .get();
    expect(budgets, hasLength(1));
  });

  test('el catch-up de recurrentes no deja el gasto sin marcar el mes',
      () async {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    await db.insertRecurringTemplate(
      categoryId: 'cat_test',
      amount: 250000,
      note: 'Arriendo',
      dayOfMonth: 1,
      initialYearMonth: lastMonth.year * 100 + lastMonth.month,
    );
    // Simula que la app muere entre el insert del gasto y el update de
    // `lastGeneratedYearMonth`.
    await db.customStatement('''
      CREATE TRIGGER block_template_update BEFORE UPDATE ON recurring_templates
      BEGIN SELECT RAISE(ABORT, 'bloqueado'); END
    ''');

    await expectLater(db.runRecurringCatchUp(), throwsA(anything));

    expect(await db.select(db.transactions).get(), isEmpty);
  });

  test('deleteSavingsGoal borra la meta con sus aportes y accesos', () async {
    final goalId =
        await db.insertSavingsGoal(name: 'Viaje', targetAmount: 100000);
    await db.addContribution(
        goalId: goalId, amount: 5000, date: DateTime.now());

    await db.deleteSavingsGoal(goalId);

    expect(await db.select(db.savingsGoals).get(), isEmpty);
    expect(await db.select(db.savingsContributions).get(), isEmpty);
  });

  test('parseBackup rechaza un archivo inválido con mensaje para el usuario',
      () {
    final bytes = Uint8List.fromList(utf8.encode('no es json'));
    expect(() => BackupRepository.parseBackup(bytes),
        throwsA(isA<FormatException>()));
  });

  group('hasMeaningfulTime', () {
    test('oculta la hora de un recurrente generado a medianoche', () {
      expect(
          hasMeaningfulTime(DateTime(2026, 10, 1), isRecurring: true), isFalse);
    });

    test('muestra la hora de un recurrente registrado a mano', () {
      expect(
          hasMeaningfulTime(DateTime(2026, 10, 1, 14, 30), isRecurring: true),
          isTrue);
    });

    test('muestra la hora de un gasto normal aunque sea medianoche', () {
      expect(
          hasMeaningfulTime(DateTime(2026, 10, 1), isRecurring: false), isTrue);
    });
  });
}
