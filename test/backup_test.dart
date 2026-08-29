// Verifica RF16/RF17: exportar todas las tablas a JSON y restaurarlas en una
// base nueva reproduce los mismos datos (ida y vuelta completa).

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasto_a_mano/data/local/app_database.dart';
import 'package:sqlite3/open.dart';

void main() {
  setUpAll(() {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
  });

  test('exportAllData -> restoreAllData reproduce los mismos datos', () async {
    final dir = await Directory.systemTemp.createTemp('backup_test');
    addTearDown(() => dir.delete(recursive: true));

    final db = AppDatabase.forTesting(NativeDatabase(File('${dir.path}/a.db')));
    addTearDown(db.close);

    // Poblar más allá del seed por defecto: presupuesto editado, gasto,
    // recurrente, meta con aporte y acceso rápido.
    await db.setBudgetForMonth('alimentacion', DateTime.now(), 999000);
    final txId = await db.into(db.transactions).insert(
          TransactionsCompanion.insert(
            categoryId: 'alimentacion',
            amount: 5000,
            date: DateTime.now(),
            note: const Value('almuerzo'),
          ),
        );
    await db.insertRecurringTemplate(
      categoryId: 'vivienda',
      amount: 250000,
      note: 'Arriendo',
      dayOfMonth: 1,
      initialYearMonth: DateTime.now().year * 100 + DateTime.now().month,
    );
    final goalId =
        await db.insertSavingsGoal(name: 'Vacaciones', targetAmount: 500000);
    await db.addContribution(
        goalId: goalId, amount: 20000, date: DateTime.now());
    await db.insertSavingsQuickAdd(
        goalId: goalId, label: '10%', mode: 'percent', value: 10);
    await db.setSetting('last_open_year_month', '202601');

    final exported = await db.exportAllData();
    // Debe ser serializable a JSON real (RF16 pide un archivo JSON portable).
    final jsonStr = jsonEncode(exported);
    final roundTripped = jsonDecode(jsonStr) as Map<String, dynamic>;

    // Restaurar sobre una base DISTINTA, ya con su propio seed por defecto,
    // para probar que restoreAllData reemplaza (no fusiona) los datos.
    final db2 =
        AppDatabase.forTesting(NativeDatabase(File('${dir.path}/b.db')));
    addTearDown(db2.close);
    await db2.restoreAllData(roundTripped);

    final categories = await db2.select(db2.categories).get();
    final budgets = await db2.select(db2.categoryBudgets).get();
    final txs = await db2.select(db2.transactions).get();
    final templates = await db2.select(db2.recurringTemplates).get();
    final goals = await db2.select(db2.savingsGoals).get();
    final contributions = await db2.select(db2.savingsContributions).get();
    final quickAdds = await db2.select(db2.savingsQuickAdds).get();
    final lastOpen = await db2.getSetting('last_open_year_month');

    expect(categories, hasLength(6),
        reason: 'las 6 categorías seed originales');
    expect(
      budgets.firstWhere((b) => b.categoryId == 'alimentacion').amount,
      999000,
    );
    expect(txs, hasLength(1));
    expect(txs.single.id, txId, reason: 'el id se preserva, no se reasigna');
    expect(txs.single.note, 'almuerzo');
    expect(templates, hasLength(1));
    expect(templates.single.categoryId, 'vivienda');
    expect(goals, hasLength(1));
    expect(goals.single.name, 'Vacaciones');
    expect(contributions, hasLength(1));
    expect(contributions.single.amount, 20000);
    expect(quickAdds, hasLength(1));
    expect(quickAdds.single.value, 10);
    expect(lastOpen, '202601');
  });
}
