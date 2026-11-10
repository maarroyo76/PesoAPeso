// RF37: revisión "¿Valió la pena?". RF65: categorías esenciales. RF66: solo
// lo no esencial, cada semana o cada 15 días. RF67: lo que no valió la pena.

import 'dart:ffi' show DynamicLibrary;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqlite3/open.dart';
import 'package:peso_a_peso/core/providers/app_providers.dart';
import 'package:peso_a_peso/core/utils/essential.dart';
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

Category _cat(String id, {bool essential = false}) => Category(
    id: id,
    name: id,
    colorValue: 1,
    iconKey: 'x',
    archived: false,
    essential: essential);

/// Ocio y comida no son esenciales; supermercado sí.
final _essential = EssentialResolver([
  _cat('ocio'),
  _cat('comida'),
  _cat('supermercado', essential: true),
], const []);

CategoryEssentialChange _change(int id, String category, DateTime at,
        {required bool essential}) =>
    CategoryEssentialChange(
        id: id, categoryId: category, changedAt: at, essential: essential);

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
    expect(
        weeklyReviewCandidates(txs, today, essential: _essential)
            .map((t) => t.id),
        [3, 5, 1]);
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

  test('RF66: un gasto esencial no aparece en la revisión', () {
    final txs = [
      _tx(1, today),
      _tx(2, today, category: 'supermercado'),
      _tx(3, today, category: 'comida'),
    ];
    expect(
        weeklyReviewCandidates(txs, today, essential: _essential)
            .map((t) => t.id),
        unorderedEquals([1, 3]));
  });

  test('RF66: quincenal mira 14 días y se propone cada 14', () {
    final txs = [
      _tx(1, DateTime(2026, 10, 15)), // hace 13 días: entra
      _tx(2, DateTime(2026, 10, 14, 23)), // hace 14: fuera
    ];
    expect(
        weeklyReviewCandidates(txs, today, essential: _essential, days: 14)
            .map((t) => t.id),
        [1]);
    final pending = [_tx(1, today)];
    expect(
        weeklyReviewDue(
            lastReview: '2026-10-21',
            today: today,
            candidates: pending,
            days: 14),
        isFalse);
    expect(
        weeklyReviewDue(
            lastReview: '2026-10-14',
            today: today,
            candidates: pending,
            days: 14),
        isTrue);
  });

  test('RF66: la frecuencia guardada; semanal si falta o no es válida', () {
    expect(reviewFrequencyDays(null), 7);
    expect(reviewFrequencyDays('14'), 14);
    expect(reviewFrequencyDays('7'), 7);
    expect(reviewFrequencyDays('30'), 7);
  });

  test('RF67: "no tanto" por categoría y porcentaje de lo revisado', () {
    final summary = worthItSummary([
      _tx(1, today, amount: 5000, worthIt: false),
      _tx(2, today, amount: 3000, category: 'comida', worthIt: false),
      _tx(3, today, amount: 2000, worthIt: false),
      _tx(4, today, amount: 10000, worthIt: true),
      _tx(5, today, amount: 700),
      _tx(6, today, amount: 50000, recurring: true),
      // Esencial: no cuenta aunque se haya marcado antes de RF66.
      _tx(7, today, amount: 40000, category: 'supermercado', worthIt: false),
      // Otro mes.
      _tx(8, DateTime(2026, 9, 30), amount: 1000, worthIt: false),
    ], DateTime(2026, 10), essential: _essential);
    expect(summary.notWorthByCategory, {'ocio': 7000, 'comida': 3000});
    expect(summary.notWorthTotal, 10000);
    expect(summary.reviewedCount, 4);
    expect(summary.reviewedAmount, 20000);
    expect(summary.notWorthPercent, 50);
    expect((summary.unreviewedCount, summary.unreviewedAmount), (1, 700));
    // Los no revisados no cuentan en el porcentaje de "no tanto".
    expect(summary.reviewedPercent, 80);
  });

  test('RF67: sin gastos revisados no hay porcentaje', () {
    final summary = worthItSummary([_tx(1, today)], DateTime(2026, 10),
        essential: _essential);
    expect(summary.notWorthPercent, isNull);
    expect(summary.reviewedPercent, 0);
  });

  group('RF65: el cambio vale desde ese momento', () {
    final changedAt = DateTime(2026, 10, 15, 12);
    // Ocio pasó a ser esencial el 15 de octubre.
    final resolver = EssentialResolver([
      _cat('ocio', essential: true),
    ], [
      _change(1, 'ocio', changedAt, essential: true),
    ]);

    test('antes del cambio vale el valor anterior', () {
      expect(resolver.isEssential('ocio'), isTrue);
      expect(resolver.isEssentialAt('ocio', DateTime(2026, 10, 14)), isFalse);
      expect(resolver.isEssentialAt('ocio', changedAt), isTrue);
      expect(resolver.isEssentialAt('ocio', DateTime(2026, 11, 1)), isTrue);
      expect(resolver.isEssentialAt('desconocida', today), isFalse);
    });

    test('varios cambios: vale el último hasta esa fecha', () {
      final r = EssentialResolver([
        _cat('ocio'),
      ], [
        _change(2, 'ocio', DateTime(2026, 10, 20), essential: false),
        _change(1, 'ocio', DateTime(2026, 10, 10), essential: true),
      ]);
      expect(r.isEssentialAt('ocio', DateTime(2026, 10, 5)), isFalse);
      expect(r.isEssentialAt('ocio', DateTime(2026, 10, 15)), isTrue);
      expect(r.isEssentialAt('ocio', DateTime(2026, 10, 25)), isFalse);
    });

    test('las respuestas no cambian y la estadística respeta la fecha', () {
      final txs = [
        _tx(1, DateTime(2026, 10, 10), amount: 4000, worthIt: false),
        _tx(2, DateTime(2026, 10, 20), amount: 6000, worthIt: false),
      ];
      final summary =
          worthItSummary(txs, DateTime(2026, 10), essential: resolver);
      // El del 10 era no esencial y sigue contando; el del 20 ya no.
      expect(summary.notWorthTotal, 4000);
      expect(txs.map((t) => t.worthIt), [false, false]);
      // Desde el cambio, ocio ya no se revisa.
      expect(
          weeklyReviewCandidates([_tx(3, today)], today, essential: resolver)
              .isEmpty,
          isTrue);
    });
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
                  archived: false,
                  essential: false)
            ])),
        essentialChangesProvider
            .overrideWith((ref) => Stream.value(<CategoryEssentialChange>[])),
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
