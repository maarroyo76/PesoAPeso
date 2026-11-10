// RF65: categorías esenciales en la base: catálogo, migración v13, cambios
// con fecha, respaldo y borrado.

import 'dart:ffi' show DynamicLibrary;
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:peso_a_peso/core/utils/essential.dart';
import 'package:peso_a_peso/data/backup/backup_validation.dart';
import 'package:peso_a_peso/data/local/app_database.dart';

void main() {
  setUpAll(() {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
  });

  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<Category> get(String id) =>
      (db.select(db.categories)..where((c) => c.id.equals(id))).getSingle();

  test('el catálogo trae las esenciales del documento', () async {
    final essential = {
      for (final c in await db.select(db.categories).get())
        if (c.essential) c.name
    };
    expect(essential, {
      'Supermercado y feria',
      'Transporte',
      'Vivienda',
      'Cuentas y servicios',
      'Salud',
      'Educación',
      'Créditos y deudas',
    });
  });

  test('cambiar la marca anota la fecha; repetir el valor no hace nada',
      () async {
    final at = DateTime(2026, 11, 10, 12);
    await db.setCategoryEssential('ocio', true, at: at);
    await db.setCategoryEssential('ocio', true, at: DateTime(2026, 11, 11));
    expect((await get('ocio')).essential, isTrue);
    final changes = await db.select(db.categoryEssentialChanges).get();
    expect(changes, hasLength(1));
    expect(changes.single.changedAt, at);

    final resolver =
        EssentialResolver(await db.select(db.categories).get(), changes);
    expect(resolver.isEssentialAt('ocio', DateTime(2026, 11, 9)), isFalse);
    expect(resolver.isEssentialAt('ocio', DateTime(2026, 11, 10, 13)), isTrue);
  });

  test('las respuestas de la revisión no cambian al cambiar la marca',
      () async {
    final id = await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
            categoryId: 'ocio', amount: 9000, date: DateTime(2026, 11, 1)));
    await (db.update(db.transactions)..where((t) => t.id.equals(id)))
        .write(const TransactionsCompanion(worthIt: Value(false)));
    await db.setCategoryEssential('ocio', true);
    final tx = await (db.select(db.transactions)..where((t) => t.id.equals(id)))
        .getSingle();
    expect(tx.worthIt, isFalse);
  });

  test('crear una categoría propia: no esencial salvo que se elija', () async {
    await db.insertCategory(
        id: 'gimnasio', name: 'Gimnasio', colorValue: 1, iconKey: 'x');
    await db.insertCategory(
        id: 'colegio',
        name: 'Colegio',
        colorValue: 1,
        iconKey: 'x',
        essential: true);
    expect((await get('gimnasio')).essential, isFalse);
    expect((await get('colegio')).essential, isTrue);
  });

  test('fusionar o eliminar la categoría borra su historial', () async {
    await db.setCategoryEssential('ocio', true);
    await db.setCategoryEssential('mascotas', true);
    await db.mergeCategory('ocio', 'otros');
    await db.deleteCategory('mascotas');
    expect(await db.select(db.categoryEssentialChanges).get(), isEmpty);
  });

  test('el respaldo conserva la marca y su historial', () async {
    await db.setCategoryEssential('ocio', true);
    await db.setCategoryEssential('salud', false);
    final data = await db.exportAllData();
    validateBackupData(data);
    await db.restoreAllData(data);
    expect((await get('ocio')).essential, isTrue);
    expect((await get('salud')).essential, isFalse);
    expect(await db.select(db.categoryEssentialChanges).get(), hasLength(2));
  });

  test('un respaldo anterior a RF65 toma la clasificación del catálogo',
      () async {
    await db.setCategoryEssential('ocio', true);
    final data = await db.exportAllData()
      ..['version'] = 3
      ..remove('categoryEssentialChanges');
    for (final row
        in (data['categories'] as List).cast<Map<String, dynamic>>()) {
      row.remove('essential');
    }
    validateBackupData(data);
    await db.restoreAllData(data);
    expect((await get('ocio')).essential, isFalse);
    expect((await get('supermercado')).essential, isTrue);
  });

  test('migración v12 → v13 marca las esenciales del catálogo', () async {
    final dir = await Directory.systemTemp.createTemp('migration_v13');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/v12.db');

    // Una base actual sin la columna ni la tabla nuevas queda igual a una v12.
    final current = AppDatabase.forTesting(NativeDatabase(file));
    await current.insertCategory(
        id: 'gimnasio', name: 'Gimnasio', colorValue: 1, iconKey: 'x');
    await current.close();
    final raw = sqlite3.sqlite3.open(file.path);
    raw.execute('''
      DROP TABLE category_essential_changes;
      ALTER TABLE categories DROP COLUMN essential;
      PRAGMA user_version = 12;
    ''');
    raw.dispose();

    final migrated = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(migrated.close);
    final byId = {
      for (final c in await migrated.select(migrated.categories).get())
        c.id: c.essential
    };
    expect(byId['supermercado'], isTrue);
    expect(byId['creditos'], isTrue);
    expect(byId['ocio'], isFalse);
    expect(byId['gimnasio'], isFalse);
    expect(await migrated.select(migrated.categoryEssentialChanges).get(),
        isEmpty);
  });
}
