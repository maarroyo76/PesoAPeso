// Migración v7 -> v8 (RF03 ampliado): se agrega categories.icon_key con el
// ícono histórico de las categorías default; las propias quedan en 'category'.

import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_a_peso/data/local/app_database.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  setUpAll(() {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
  });

  test('backfill de iconKey en categorías default y default en las propias',
      () async {
    final dir = await Directory.systemTemp.createTemp('migration_v8');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/v7.db');

    // Esquema v7 completo (sin claves foráneas, como quedaron hasta v8): la
    // migración a v9 reconstruye estas tablas y necesita que existan.
    final raw = sqlite3.sqlite3.open(file.path);
    raw.execute('''
      CREATE TABLE categories (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        color_value INTEGER NOT NULL
      );
      CREATE TABLE category_budgets (
        category_id TEXT NOT NULL,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        amount INTEGER NOT NULL,
        PRIMARY KEY (category_id, year, month)
      );
      CREATE TABLE transactions (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        category_id TEXT NOT NULL,
        amount INTEGER NOT NULL,
        date INTEGER NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        is_recurring INTEGER NOT NULL DEFAULT 0
      );
      CREATE TABLE recurring_templates (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        category_id TEXT NOT NULL,
        amount INTEGER NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        day_of_month INTEGER NOT NULL,
        active INTEGER NOT NULL DEFAULT 1,
        last_generated_year_month INTEGER NOT NULL
      );
      CREATE TABLE app_settings (
        key TEXT NOT NULL PRIMARY KEY,
        value TEXT NOT NULL
      );
      CREATE TABLE savings_goals (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target_amount INTEGER NOT NULL
      );
      CREATE TABLE savings_contributions (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        goal_id INTEGER NOT NULL,
        amount INTEGER NOT NULL,
        date INTEGER NOT NULL,
        note TEXT NOT NULL DEFAULT ''
      );
      CREATE TABLE savings_quick_adds (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        goal_id INTEGER NOT NULL,
        label TEXT NOT NULL,
        mode TEXT NOT NULL,
        value INTEGER NOT NULL
      );
      CREATE TABLE monthly_budgets (
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        amount INTEGER NOT NULL,
        PRIMARY KEY (year, month)
      );
      CREATE TABLE quick_expense_templates (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        label TEXT NOT NULL,
        amount INTEGER NOT NULL,
        category_id TEXT NOT NULL
      );
      INSERT INTO categories VALUES
        ('alimentacion', 'Alimentación', ${0xFF2F6F4E}),
        ('mascotas', 'Mascotas', ${0xFF123456});
      PRAGMA user_version = 7;
    ''');
    raw.dispose();

    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);
    final cats = {
      for (final c in await db.select(db.categories).get()) c.id: c.iconKey
    };

    expect(cats['alimentacion'], 'restaurant');
    expect(cats['mascotas'], 'category');
  });
}
