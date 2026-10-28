// RF31/RF32: métodos de pago. RNF16: a lo más los últimos 4 dígitos.
// RNF18: la migración v9 -> v10 no cambia los gastos existentes.
// RNF19: respaldo v2 con métodos, que sigue aceptando respaldos v1.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter/material.dart' show ListView, Offset;
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_a_peso/data/backup/backup_validation.dart';
import 'package:peso_a_peso/data/local/app_database.dart';
import 'package:peso_a_peso/data/repositories/backup_repository.dart';
import 'package:peso_a_peso/data/repositories/payment_methods_repository.dart';
import 'package:peso_a_peso/data/repositories/transactions_repository.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:peso_a_peso/features/resumen/resumen_screen.dart';

import 'support/main_screens.dart';

void main() {
  setUpAll(() async {
    await setUpMainScreens();
  });

  testWidgets('RF32: Resumen muestra con qué se pagó cada gasto',
      (tester) async {
    final dispose = await pumpMainScreen(tester, const ResumenScreen());
    await tester.dragUntilVisible(find.textContaining('CMR'),
        find.byType(ListView).first, const Offset(0, -200));
    expect(find.textContaining('· CMR ···· 1234'), findsOneWidget,
        reason: 'solo el gasto con método lo muestra');
    await dispose();
  });

  group('métodos de pago', () {
    late AppDatabase db;
    late PaymentMethodsRepository methods;
    late TransactionsRepository transactions;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      methods = PaymentMethodsRepository(db);
      transactions = TransactionsRepository(db);
    });
    tearDown(() => db.close());

    test('los días de facturación y pago solo se guardan en crédito', () async {
      final id = await methods.createPaymentMethod(
          alias: 'CMR',
          kind: kPaymentKindCredit,
          colorValue: 1,
          last4: '1234',
          billingDay: 20,
          dueDay: 5);
      var m = (await methods.watchPaymentMethods().first).single;
      expect((m.billingDay, m.dueDay), (20, 5));

      await methods.updatePaymentMethod(id,
          alias: 'CMR',
          kind: kPaymentKindDebit,
          colorValue: 1,
          last4: '1234',
          billingDay: 20,
          dueDay: 5);
      m = (await methods.watchPaymentMethods().first).single;
      expect((m.billingDay, m.dueDay), (null, null),
          reason: 'al pasar a débito los días ya no aplican');
    });

    test('RNF16: la base rechaza más de 4 dígitos o letras', () async {
      Future<int> create(String last4) => methods.createPaymentMethod(
          alias: 'Tarjeta $last4',
          kind: kPaymentKindDebit,
          colorValue: 1,
          last4: last4);
      await create('0042');
      await expectLater(create('12345'), throwsA(isA<SqliteException>()));
      await expectLater(create('12a4'), throwsA(isA<SqliteException>()));
    });

    test('RF31: no se puede eliminar un método con gastos', () async {
      final id = await methods.createPaymentMethod(
          alias: 'Efectivo', kind: kPaymentKindCash, colorValue: 1);
      expect(await methods.canDeletePaymentMethod(id), isTrue);

      await transactions.addTransaction(
          categoryId: 'ocio',
          amount: 5000,
          date: DateTime(2026, 10, 1),
          paymentMethodId: id);
      expect(await methods.canDeletePaymentMethod(id), isFalse);
      // La clave foránea lo impide aunque se saltara la UI.
      await expectLater(
          methods.deletePaymentMethod(id), throwsA(isA<SqliteException>()));
    });

    test('RF32: propone el método del último gasto que tenía uno', () async {
      expect(await methods.lastUsedPaymentMethodId(), isNull);
      final cash = await methods.createPaymentMethod(
          alias: 'Efectivo', kind: kPaymentKindCash, colorValue: 1);
      final debit = await methods.createPaymentMethod(
          alias: 'Débito', kind: kPaymentKindDebit, colorValue: 1);
      final date = DateTime(2026, 10, 1);
      await transactions.addTransaction(
          categoryId: 'ocio', amount: 1, date: date, paymentMethodId: cash);
      await transactions.addTransaction(
          categoryId: 'ocio', amount: 1, date: date, paymentMethodId: debit);
      await transactions.addTransaction(
          categoryId: 'ocio', amount: 1, date: date);
      expect(await methods.lastUsedPaymentMethodId(), debit,
          reason: 'un gasto sin método no cambia la sugerencia');
    });
  });

  test('RNF18: migración v9 -> v10 conserva los gastos, sin método', () async {
    final dir = await Directory.systemTemp.createTemp('migration_v10');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/v9.db');

    // Esquema v9 tal como lo crea la app (sqlite_master de una base v9).
    final raw = sqlite3.sqlite3.open(file.path);
    raw.execute('''
      CREATE TABLE "categories" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "color_value" INTEGER NOT NULL, "icon_key" TEXT NOT NULL DEFAULT 'category', PRIMARY KEY ("id"));
      CREATE TABLE "category_budgets" ("category_id" TEXT NOT NULL, "year" INTEGER NOT NULL, "month" INTEGER NOT NULL, "amount" INTEGER NOT NULL, PRIMARY KEY ("category_id", "year", "month"), FOREIGN KEY (category_id) REFERENCES categories (id));
      CREATE TABLE "recurring_templates" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "category_id" TEXT NOT NULL, "amount" INTEGER NOT NULL, "note" TEXT NOT NULL DEFAULT '', "day_of_month" INTEGER NOT NULL, "active" INTEGER NOT NULL DEFAULT 1 CHECK ("active" IN (0, 1)), "last_generated_year_month" INTEGER NOT NULL, FOREIGN KEY (category_id) REFERENCES categories (id));
      CREATE TABLE "transactions" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "category_id" TEXT NOT NULL, "amount" INTEGER NOT NULL, "date" INTEGER NOT NULL, "note" TEXT NOT NULL DEFAULT '', "is_recurring" INTEGER NOT NULL DEFAULT 0 CHECK ("is_recurring" IN (0, 1)), "recurring_template_id" INTEGER NULL, FOREIGN KEY (category_id) REFERENCES categories (id), FOREIGN KEY (recurring_template_id) REFERENCES recurring_templates (id) ON DELETE SET NULL);
      CREATE TABLE "app_settings" ("key" TEXT NOT NULL, "value" TEXT NOT NULL, PRIMARY KEY ("key"));
      CREATE TABLE "savings_goals" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "name" TEXT NOT NULL, "target_amount" INTEGER NOT NULL);
      CREATE TABLE "savings_contributions" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "goal_id" INTEGER NOT NULL, "amount" INTEGER NOT NULL, "date" INTEGER NOT NULL, "note" TEXT NOT NULL DEFAULT '', FOREIGN KEY (goal_id) REFERENCES savings_goals (id));
      CREATE TABLE "savings_quick_adds" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "goal_id" INTEGER NOT NULL, "label" TEXT NOT NULL, "mode" TEXT NOT NULL, "value" INTEGER NOT NULL, FOREIGN KEY (goal_id) REFERENCES savings_goals (id));
      CREATE TABLE "monthly_budgets" ("year" INTEGER NOT NULL, "month" INTEGER NOT NULL, "amount" INTEGER NOT NULL, PRIMARY KEY ("year", "month"));
      CREATE TABLE "quick_expense_templates" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "label" TEXT NOT NULL, "amount" INTEGER NOT NULL, "category_id" TEXT NOT NULL, FOREIGN KEY (category_id) REFERENCES categories (id));
      CREATE TABLE "monthly_adjustments" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "year" INTEGER NOT NULL, "month" INTEGER NOT NULL, "category_id" TEXT NULL, "amount" INTEGER NOT NULL, "reason" TEXT NOT NULL DEFAULT '', FOREIGN KEY (category_id) REFERENCES categories (id));
      INSERT INTO categories (id, name, color_value) VALUES
        ('ocio', 'Ocio', 1), ('vivienda', 'Vivienda', 2);
      INSERT INTO recurring_templates
        (id, category_id, amount, day_of_month, last_generated_year_month)
        VALUES (7, 'vivienda', 350000, 5, 202610);
      INSERT INTO transactions
        (id, category_id, amount, date, note, is_recurring, recurring_template_id)
        VALUES
        (1, 'ocio', 12345, 1790000000, 'cine', 0, NULL),
        (2, 'vivienda', 350000, 1790100000, '', 1, 7),
        (3, 'ocio', 990, 1790200000, '', 0, NULL);
      PRAGMA user_version = 9;
    ''');
    raw.dispose();

    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);
    final txs = await (db.select(db.transactions)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();

    expect(
        txs.map((t) => (t.id, t.amount)), [(1, 12345), (2, 350000), (3, 990)]);
    expect(txs.map((t) => t.note), ['cine', '', '']);
    expect(txs[1].recurringTemplateId, 7,
        reason: 'el enlace de I4 se conserva');
    expect(txs.every((t) => t.paymentMethodId == null), isTrue,
        reason: 'todos quedan como "Sin especificar"');
    expect(await db.select(db.paymentMethods).get(), isEmpty);
    expect((await db.select(db.categories).get()).every((c) => !c.archived),
        isTrue,
        reason: 'RF53: las categorías existentes quedan activas');

    // La columna nueva quedó con su clave foránea.
    final fks = await db
        .customSelect(
            "SELECT \"table\" FROM pragma_foreign_key_list('transactions')")
        .get();
    expect(fks.map((r) => r.read<String>('table')),
        containsAll(['payment_methods', 'savings_goals']));
  });

  group('respaldo v2', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('ida y vuelta conserva métodos y el método de cada gasto', () async {
      final methods = PaymentMethodsRepository(db);
      final id = await methods.createPaymentMethod(
          alias: 'CMR',
          kind: kPaymentKindCredit,
          colorValue: 1,
          last4: '1234',
          billingDay: 20);
      await TransactionsRepository(db).addTransaction(
          categoryId: 'ocio',
          amount: 5000,
          date: DateTime(2026, 10, 1),
          paymentMethodId: id);

      final exported = jsonDecode(jsonEncode(await db.exportAllData()))
          as Map<String, dynamic>;
      expect(exported['version'], kBackupFormatVersion);

      final db2 = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db2.close);
      await BackupRepository(db2).restoreFromBytes(
          Uint8List.fromList(utf8.encode(jsonEncode(exported))));
      final m = (await db2.select(db2.paymentMethods).get()).single;
      expect((m.alias, m.last4, m.billingDay), ('CMR', '1234', 20));
      final tx = (await db2.select(db2.transactions).get()).single;
      expect(tx.paymentMethodId, m.id);
    });

    test('un respaldo v1 se restaura con los gastos sin método', () async {
      final v1 = jsonDecode(jsonEncode(await db.exportAllData()))
          as Map<String, dynamic>
        ..['version'] = 1
        ..remove('paymentMethods')
        ..['transactions'] = [
          {
            'id': 1,
            'categoryId': 'ocio',
            'amount': 4200,
            'date': DateTime(2026, 9, 1).millisecondsSinceEpoch,
            'note': '',
            'isRecurring': false,
          }
        ];

      final db2 = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db2.close);
      await BackupRepository(db2)
          .restoreFromBytes(Uint8List.fromList(utf8.encode(jsonEncode(v1))));
      final tx = (await db2.select(db2.transactions).get()).single;
      expect((tx.amount, tx.paymentMethodId), (4200, null));
    });

    test('un gasto que apunta a un método inexistente se rechaza', () async {
      final data = jsonDecode(jsonEncode(await db.exportAllData()))
          as Map<String, dynamic>
        ..['transactions'] = [
          {
            'id': 1,
            'categoryId': 'ocio',
            'amount': 4200,
            'date': DateTime(2026, 9, 1).millisecondsSinceEpoch,
            'note': '',
            'isRecurring': false,
            'paymentMethodId': 99,
          }
        ];
      expect(
          () => validateBackupData(data),
          throwsA(isA<FormatException>()
              .having((e) => e.message, 'message', kBackupCorruptMessage)));
    });
  });
}
