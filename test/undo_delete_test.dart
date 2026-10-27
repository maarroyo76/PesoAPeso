// UX02: eliminar sin diálogo depende de poder deshacer: lo borrado vuelve
// tal cual (mismo id), y una plantilla restaurada recupera sus gastos.

import 'dart:ffi';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_a_peso/data/local/app_database.dart';
import 'package:sqlite3/open.dart';

void main() {
  setUpAll(() {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
  });

  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('deshacer un gasto eliminado lo restaura con el mismo id', () async {
    final id = await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
            categoryId: 'ocio',
            amount: 15000,
            date: DateTime(2026, 10, 3, 21, 30),
            note: const Value('Cine')));
    final before = await (db.select(db.transactions)
          ..where((t) => t.id.equals(id)))
        .getSingle();

    final undo = await db.deleteTransactionUndoable(id);
    expect(await db.select(db.transactions).get(), isEmpty);

    await undo();
    final after = await db.select(db.transactions).getSingle();
    expect(after, before);
  });

  test('deshacer una plantilla eliminada la re-enlaza con sus gastos',
      () async {
    final tplId = await db.insertRecurringTemplate(
      categoryId: 'vivienda',
      amount: 300000,
      note: 'Arriendo',
      dayOfMonth: 5,
      initialYearMonth: 202610,
    );
    final txId = await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
            categoryId: 'vivienda',
            amount: 300000,
            date: DateTime(2026, 10, 5),
            isRecurring: const Value(true),
            recurringTemplateId: Value(tplId)));

    final undo = await db.deleteRecurringTemplateUndoable(tplId);
    final orphan = await db.select(db.transactions).getSingle();
    expect(orphan.recurringTemplateId, isNull,
        reason: 'ON DELETE SET NULL al borrar la plantilla');

    await undo();
    final tpl = await db.select(db.recurringTemplates).getSingle();
    final relinked = await (db.select(db.transactions)
          ..where((t) => t.id.equals(txId)))
        .getSingle();
    expect(tpl.id, tplId);
    expect(relinked.recurringTemplateId, tplId);
  });

  test('deshacer un aporte eliminado lo restaura en su meta', () async {
    final goalId = await db.into(db.savingsGoals).insert(
        SavingsGoalsCompanion.insert(name: 'Viaje', targetAmount: 500000));
    final cId = await db.into(db.savingsContributions).insert(
        SavingsContributionsCompanion.insert(
            goalId: goalId, amount: 20000, date: DateTime(2026, 10, 1)));

    final undo = await db.deleteContributionUndoable(cId);
    expect(await db.select(db.savingsContributions).get(), isEmpty);

    await undo();
    final c = await db.select(db.savingsContributions).getSingle();
    expect((c.id, c.goalId, c.amount), (cId, goalId, 20000));
  });
}
