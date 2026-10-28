// RF37: revisión semanal "¿Valió la pena?". RF44: lo marcado "no tanto".

import 'dart:ffi' show DynamicLibrary;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqlite3/open.dart';
import 'package:peso_a_peso/core/providers/app_providers.dart';
import 'package:peso_a_peso/core/utils/weekly_review.dart';
import 'package:peso_a_peso/data/local/app_database.dart';
import 'package:peso_a_peso/features/revision/weekly_review_screen.dart';

Transaction _tx(int id, DateTime date,
        {int amount = 1000,
        String category = 'ocio',
        bool recurring = false,
        int? installment,
        bool? worthIt}) =>
    Transaction(
      id: id,
      categoryId: category,
      amount: amount,
      date: date,
      note: '',
      isRecurring: recurring,
      installmentPlanId: installment == null ? null : 1,
      installmentNumber: installment,
      worthIt: worthIt,
    );

void main() {
  setUpAll(() async {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    await initializeDateFormatting('es_CL', null);
  });

  final today = DateTime(2026, 10, 28, 9);

  test('se revisan los gastos de los últimos 7 días que fueron decisión', () {
    final txs = [
      _tx(1, DateTime(2026, 10, 22)), // hace 6 días: entra
      _tx(2, DateTime(2026, 10, 21, 23)), // hace 7: queda fuera
      _tx(3, DateTime(2026, 10, 28, 20)), // hoy más tarde: entra
      _tx(4, DateTime(2026, 10, 25), recurring: true),
      _tx(5, DateTime(2026, 10, 25), installment: 1),
      _tx(6, DateTime(2026, 10, 25), installment: 2),
    ];
    expect(weeklyReviewCandidates(txs, today).map((t) => t.id), [3, 5, 1]);
  });

  test('se propone una vez por semana y solo si hay algo sin revisar', () {
    final pending = [_tx(1, today)];
    expect(weeklyReviewDue(lastReview: null, today: today, candidates: pending),
        isTrue);
    expect(
        weeklyReviewDue(
            lastReview: '2026-10-22', today: today, candidates: pending),
        isFalse);
    expect(
        weeklyReviewDue(
            lastReview: '2026-10-21', today: today, candidates: pending),
        isTrue);
    expect(
        weeklyReviewDue(
            lastReview: null,
            today: today,
            candidates: [_tx(1, today, worthIt: true)]),
        isFalse);
  });

  test('RF44: "no tanto" por categoría; lo no revisado va aparte', () {
    final summary = worthItSummary([
      _tx(1, today, amount: 5000, worthIt: false),
      _tx(2, today, amount: 3000, category: 'comida', worthIt: false),
      _tx(3, today, amount: 2000, worthIt: false),
      _tx(4, today, amount: 9000, worthIt: true),
      _tx(5, today, amount: 700),
      _tx(6, today, amount: 50000, recurring: true),
    ]);
    expect(summary.notWorthByCategory, {'ocio': 7000, 'comida': 3000});
    expect(summary.notWorthTotal, 10000);
    expect(summary.reviewedCount, 4);
    expect((summary.unreviewedCount, summary.unreviewedAmount), (1, 700));
  });

  testWidgets('marcar "No tanto" se guarda y "Listo" cierra la revisión',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));
    final now = DateTime.now();
    final tx = (await tester.runAsync(() async {
      final id = await db.into(db.transactions).insert(
          TransactionsCompanion.insert(
              categoryId: 'ocio', amount: 15000, date: now));
      return (db.select(db.transactions)..where((t) => t.id.equals(id)))
          .getSingle();
    }))!;

    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        categoriesProvider.overrideWith((ref) => Stream.value(const [
              Category(
                  id: 'ocio',
                  name: 'Ocio',
                  colorValue: 1,
                  iconKey: 'x',
                  archived: false)
            ])),
        monthTransactionsProvider.overrideWith((ref, m) =>
            Stream.value(m.month == now.month ? [tx] : const <Transaction>[])),
      ],
      child: const MaterialApp(home: WeeklyReviewScreen()),
    ));
    await tester.pump();

    Future<void> settle() async {
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump();
      }
    }

    await tester.tap(find.text('No tanto'));
    await settle();
    final saved =
        (await tester.runAsync(() => db.select(db.transactions).get()))!.single;
    expect(saved.worthIt, isFalse);

    await tester.tap(find.text('Listo'));
    await settle();
    expect(await tester.runAsync(() => db.getSetting(kWeeklyReviewSettingKey)),
        reviewDateKey(now));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
