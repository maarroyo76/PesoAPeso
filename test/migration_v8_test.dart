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

    final raw = sqlite3.sqlite3.open(file.path);
    raw.execute('''
      CREATE TABLE categories (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        color_value INTEGER NOT NULL
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
