// RF51 (corrige I2): los aportes a metas del mes salen del presupuesto, así
// que el remanente es presupuesto − gastos − aportes.

import 'dart:ffi';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_a_peso/core/startup/remainder_prompt.dart';
import 'package:peso_a_peso/data/local/app_database.dart';
import 'package:peso_a_peso/data/repositories/categories_repository.dart';
import 'package:peso_a_peso/data/repositories/savings_repository.dart';
import 'package:peso_a_peso/data/repositories/transactions_repository.dart';
import 'package:sqlite3/open.dart';

void main() {
  setUpAll(() {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
  });

  late AppDatabase db;
  late CategoriesRepository categories;
  late TransactionsRepository transactions;
  late SavingsRepository savings;
  late int goalId;
  final month = DateTime(2026, 9);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    categories = CategoriesRepository(db);
    transactions = TransactionsRepository(db);
    savings = SavingsRepository(db);
    await categories.setMonthlyBudgetForMonth(month, 500000);
    goalId =
        await savings.createGoal(name: 'Vacaciones', targetAmount: 1000000);
  });
  tearDown(() => db.close());

  Future<int> remainder() => monthRemainder(
      categories: categories,
      transactions: transactions,
      savings: savings,
      month: month);

  test('descuenta los aportes del mes además de los gastos', () async {
    // El ejemplo de I2: $500.000 de presupuesto, $50.000 aportados y
    // $400.000 gastados dejan $50.000 libres, no $100.000.
    await transactions.addTransaction(
        categoryId: 'vivienda', amount: 400000, date: DateTime(2026, 9, 5));
    await savings.addContribution(
        goalId: goalId, amount: 50000, date: DateTime(2026, 9, 20));
    expect(await remainder(), 50000);
  });

  test('solo cuenta los aportes de ese mes', () async {
    await savings.addContribution(
        goalId: goalId, amount: 30000, date: DateTime(2026, 8, 31));
    await savings.addContribution(
        goalId: goalId, amount: 40000, date: DateTime(2026, 10, 1));
    await savings.addContribution(
        goalId: goalId, amount: 10000, date: DateTime(2026, 9, 30, 23, 59));
    expect(await remainder(), 490000);
  });
}
