// Verifica la migración v1 -> v2 (RF04): categories.monthly_budget se migra
// a una fila de category_budgets del mes actual y la columna vieja
// desaparece, sin perder transacciones existentes.

import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasto_a_mano/data/local/app_database.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  setUpAll(() {
    // En este entorno de desarrollo solo existe libsqlite3.so.0 (falta el
    // symlink libsqlite3.so de sqlite-devel); apuntamos directo a esa lib.
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
  });

  test('migra monthly_budget a category_budgets del mes actual', () async {
    final dir = await Directory.systemTemp.createTemp('budget_migration');
    final file = File('${dir.path}/v1.db');
    addTearDown(() => dir.delete(recursive: true));

    // 1. Simular una base real en esquema v1 (previo a CategoryBudgets).
    final raw = sqlite3.sqlite3.open(file.path);
    raw.execute('''
      CREATE TABLE categories (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        monthly_budget INTEGER NOT NULL,
        color_value INTEGER NOT NULL
      );
      CREATE TABLE transactions (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        category_id TEXT NOT NULL REFERENCES categories (id),
        amount INTEGER NOT NULL,
        date INTEGER NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        is_recurring INTEGER NOT NULL DEFAULT 0
      );
      INSERT INTO categories VALUES
        ('alimentacion', 'Alimentación', 150000, ${0xFF2F6F4E}),
        ('transporte', 'Transporte', 40000, ${0xFFB8842E});
      INSERT INTO transactions (category_id, amount, date, note)
        VALUES ('alimentacion', 5000, ${DateTime.now().millisecondsSinceEpoch ~/ 1000}, 'test');
      PRAGMA user_version = 1;
    ''');
    raw.dispose();

    // 2. Abrir esa base con el AppDatabase real (schemaVersion = 2): debe
    //    disparar onUpgrade(from: 1, to: 2).
    final db = AppDatabase.forTesting(NativeDatabase(file));
    final categories = await db.select(db.categories).get();
    final budgets = await db.select(db.categoryBudgets).get();
    final txs = await db.select(db.transactions).get();
    // La columna vieja ya no debe existir tras la migración.
    final columns =
        await db.customSelect("PRAGMA table_info('categories')").get();
    await db.close();

    final now = DateTime.now();
    expect(categories, hasLength(2));
    expect(txs, hasLength(1),
        reason: 'las transacciones existentes no deben perderse');
    expect(
      budgets.firstWhere((b) => b.categoryId == 'alimentacion'),
      isA<CategoryBudget>()
          .having((b) => b.amount, 'amount', 150000)
          .having((b) => b.year, 'year', now.year)
          .having((b) => b.month, 'month', now.month),
    );
    expect(
      budgets.firstWhere((b) => b.categoryId == 'transporte').amount,
      40000,
    );

    final columnNames = columns.map((r) => r.read<String>('name')).toList();
    expect(columnNames, isNot(contains('monthly_budget')));
  });
}
