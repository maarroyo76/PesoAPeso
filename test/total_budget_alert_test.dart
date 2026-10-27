// RF55: alertas al 80% y al 100% del presupuesto total del mes, cada umbral
// una sola vez por mes.

import 'dart:ffi';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_a_peso/core/utils/budget_alert.dart';
import 'package:peso_a_peso/data/local/app_database.dart';
import 'package:peso_a_peso/data/repositories/categories_repository.dart';
import 'package:peso_a_peso/data/repositories/settings_repository.dart';
import 'package:peso_a_peso/data/repositories/transactions_repository.dart';
import 'package:sqlite3/open.dart';

void main() {
  setUpAll(() {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
  });

  test('umbral: 80 y 100, sin repetir lo ya avisado', () {
    int? t(int spent, int notified) => totalAlertThreshold(
        spent: spent, budget: 1000, alreadyNotified: notified);
    expect(t(799, 0), isNull);
    expect(t(800, 0), 80);
    expect(t(950, 80), isNull, reason: 'el 80% ya se avisó este mes');
    expect(t(1000, 80), 100);
    expect(t(1500, 100), isNull);
    expect(t(1200, 0), 100, reason: 'si salta directo, solo avisa el 100%');
    expect(
        totalAlertThreshold(spent: 500, budget: 0, alreadyNotified: 0), isNull,
        reason: 'sin presupuesto total no hay alerta');
  });

  group('evaluateTotalBudgetAlert', () {
    late AppDatabase db;
    late CategoriesRepository categories;
    late TransactionsRepository transactions;
    late SettingsRepository settings;
    final month = DateTime(2026, 10);

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      categories = CategoriesRepository(db);
      transactions = TransactionsRepository(db);
      settings = SettingsRepository(db);
      await categories.setMonthlyBudgetForMonth(month, 100000);
    });
    tearDown(() => db.close());

    Future<BudgetAlertInfo?> spend(int amount, {int day = 10}) async {
      final date = DateTime(2026, 10, day);
      await transactions.addTransaction(
          categoryId: 'ocio', amount: amount, date: date);
      return evaluateTotalBudgetAlert(
          categories: categories,
          transactions: transactions,
          settings: settings,
          date: date);
    }

    test('avisa una vez al 80% y una vez al 100% en el mes', () async {
      expect(await spend(70000), isNull);
      final at80 = await spend(15000);
      expect(at80!.isTotal, isTrue);
      expect(at80.isOverBudget, isFalse);
      expect(await spend(5000), isNull, reason: '90%: el 80% ya se avisó');
      final at100 = await spend(20000);
      expect(at100!.isOverBudget, isTrue);
      expect(at100.message, contains('110%'));
      expect(await spend(1000), isNull);
    });

    test('el ajuste de un solo mes (RF50) sube el total', () async {
      await categories.addAdjustment(
          month: month, amount: 50000, reason: 'Remanente');
      expect(await spend(100000), isNull, reason: '100.000 de 150.000 = 67%');
    });

    test('el mes siguiente vuelve a avisar', () async {
      await spend(85000);
      final next = DateTime(2026, 11, 3);
      await transactions.addTransaction(
          categoryId: 'ocio', amount: 90000, date: next);
      final alert = await evaluateTotalBudgetAlert(
          categories: categories,
          transactions: transactions,
          settings: settings,
          date: next);
      expect(alert, isNotNull,
          reason: 'el presupuesto se hereda y el aviso es por mes');
    });
  });
}
