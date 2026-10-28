// RF52 (corrige I3): "Usar ahorro" registra un gasto pagado con una meta,
// que descuenta del saldo de la meta y no del presupuesto del mes.

import 'dart:convert';
import 'dart:ffi';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_a_peso/core/startup/remainder_prompt.dart';
import 'package:peso_a_peso/core/utils/daily_allowance.dart';
import 'package:peso_a_peso/data/local/app_database.dart';
import 'package:peso_a_peso/data/repositories/categories_repository.dart';
import 'package:peso_a_peso/data/repositories/savings_repository.dart';
import 'package:peso_a_peso/data/repositories/transactions_repository.dart';
import 'package:peso_a_peso/features/metodos_pago/payment_method_labels.dart';
import 'package:sqlite3/open.dart';

void main() {
  setUpAll(() {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
  });

  late AppDatabase db;
  late SavingsRepository savings;
  late int goalId;
  final month = DateTime(2026, 9);
  final date = DateTime(2026, 9, 20, 12);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    savings = SavingsRepository(db);
    await CategoriesRepository(db).setMonthlyBudgetForMonth(month, 500000);
    goalId = await savings.createGoal(name: 'Bicicleta', targetAmount: 300000);
    await savings.addContribution(
        goalId: goalId, amount: 200000, date: DateTime(2026, 8, 5));
  });
  tearDown(() => db.close());

  Future<int> balance() async =>
      (await savings.watchGoalBalances().first)[goalId]!;

  Future<int> remainder() => monthRemainder(
      categories: CategoriesRepository(db),
      transactions: TransactionsRepository(db),
      savings: savings,
      month: month);

  test('baja el saldo de la meta y no el disponible del mes', () async {
    final before = await remainder();
    await savings.spendFromGoal(
        goalId: goalId,
        categoryId: 'ocio',
        amount: 150000,
        date: date,
        note: 'Bicicleta');

    expect(await balance(), 50000);
    expect(await remainder(), before);
    final txs =
        await TransactionsRepository(db).watchTransactionsForMonth(month).first;
    expect(txs.single.categoryId, 'ocio',
        reason: 'el gasto sigue en su categoría (Estadísticas)');
    expect(budgetSpent(txs), 0);
    expect(
        transactionPaymentLabel(txs.single, const {}), kFundedBySavingsLabel);
  });

  test('no se puede usar más que el saldo de la meta', () async {
    await expectLater(
        () => savings.spendFromGoal(
            goalId: goalId, categoryId: 'ocio', amount: 200001, date: date),
        throwsStateError);
    expect(await db.select(db.transactions).get(), isEmpty);
  });

  test('al eliminar la meta, el gasto queda y vuelve al presupuesto', () async {
    await savings.spendFromGoal(
        goalId: goalId, categoryId: 'ocio', amount: 100000, date: date);
    await savings.deleteGoal(goalId);
    final tx = (await db.select(db.transactions).get()).single;
    expect(tx.fundedByGoalId, isNull);
    expect(budgetSpent([tx]), 100000);
  });

  test('el respaldo conserva la meta de origen del gasto', () async {
    await savings.spendFromGoal(
        goalId: goalId, categoryId: 'ocio', amount: 100000, date: date);
    final data = jsonDecode(jsonEncode(await db.exportAllData()))
        as Map<String, dynamic>;
    final db2 = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db2.close);
    await db2.restoreAllData(data);
    final tx = (await db2.select(db2.transactions).get()).single;
    expect(tx.fundedByGoalId, goalId);
    expect((await SavingsRepository(db2).watchGoalBalances().first)[goalId],
        100000);
  });
}
