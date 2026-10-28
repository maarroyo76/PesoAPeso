// RF45: una instalación nueva trae "Carga bip!" en Transporte entre los
// accesos rápidos por defecto.

import 'dart:ffi';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_a_peso/data/local/app_database.dart';
import 'package:sqlite3/open.dart';

void main() {
  setUpAll(() {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
  });

  test('instalación nueva: Carga bip! en Transporte, junto a Micro/Metro',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final quick = await (db.select(db.quickExpenseTemplates)
          ..orderBy([(q) => OrderingTerm.asc(q.id)]))
        .get();

    expect(quick.map((q) => q.label), [
      'Café',
      'Colación',
      'Micro/Metro',
      kBipTopUpLabel,
      'Bencina',
      'Salida',
    ]);
    final bip = quick.firstWhere((q) => q.label == kBipTopUpLabel);
    expect(bip.categoryId, 'transporte');
  });
}
