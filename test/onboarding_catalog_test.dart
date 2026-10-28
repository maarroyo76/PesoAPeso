// Onboarding rediseñado: catálogo de 15 categorías sin presupuestos
// sembrados, "Aún no sé" y las sugerencias que salieron del onboarding.

import 'dart:ffi' show DynamicLibrary;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';
import 'package:peso_a_peso/core/startup/budget_suggestion.dart';
import 'package:peso_a_peso/core/utils/quick_suggestions.dart';
import 'package:peso_a_peso/data/local/app_database.dart';
import 'package:peso_a_peso/data/repositories/categories_repository.dart';

Transaction _tx(int id, DateTime date,
        {int amount = 9990, String category = 'suscripciones'}) =>
    Transaction(
        id: id,
        categoryId: category,
        amount: amount,
        date: date,
        note: '',
        isRecurring: false);

void main() {
  setUpAll(() {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
  });

  group('instalación nueva', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('15 categorías, 8 activas, sin presupuestos sembrados', () async {
      final categories = await db.select(db.categories).get();
      expect(categories, hasLength(15));
      expect(categories.where((c) => !c.archived).map((c) => c.id).toSet(), {
        'supermercado',
        'comida_fuera',
        'transporte',
        'vivienda',
        'cuentas',
        'salud',
        'ocio',
        'otros',
      });
      expect(await db.select(db.categoryBudgets).get(), isEmpty);
      expect(await db.select(db.monthlyBudgets).get(), isEmpty);
    });

    test('los accesos por defecto apuntan al catálogo nuevo', () async {
      final quick = {
        for (final q in await db.select(db.quickExpenseTemplates).get())
          q.label: q.categoryId
      };
      expect(quick['Café'], 'comida_fuera');
      expect(quick['Colación'], 'comida_fuera');
      expect(quick['Micro/Metro'], 'transporte');
      expect(quick[kBipTopUpLabel], 'transporte');
      expect(quick['Salida'], 'ocio');
    });

    test('el onboarding deja activas solo las elegidas', () async {
      await CategoriesRepository(db)
          .setActiveCategories({'supermercado', 'mascotas'});
      final active = (await db.select(db.categories).get())
          .where((c) => !c.archived)
          .map((c) => c.id);
      expect(active.toSet(), {'supermercado', 'mascotas'});
    });

    test('"Aún no sé": al mes siguiente, si sigue sin presupuesto', () async {
      final categories = CategoriesRepository(db);
      Future<DateTime?> pending(String? stored, DateTime today) =>
          pendingBudgetSuggestionMonth(
              stored: stored, categories: categories, today: today);

      expect(await pending('202610', DateTime(2026, 10, 28)), isNull,
          reason: 'el mes todavía no termina');
      expect(
          await pending('202610', DateTime(2026, 11, 2)), DateTime(2026, 10));
      expect(await pending('', DateTime(2026, 11, 2)), isNull,
          reason: 'ya se sugirió');
      await categories.setMonthlyBudgetForMonth(DateTime(2026, 11), 400000);
      expect(await pending('202610', DateTime(2026, 11, 2)), isNull,
          reason: 'el usuario ya fijó uno');
    });
  });

  test('el presupuesto sugerido redondea hacia arriba a \$10.000', () {
    expect(suggestedBudget(431200), 440000);
    expect(suggestedBudget(430000), 430000);
  });

  group('sugerir un recurrente', () {
    final last = _tx(2, DateTime(2026, 10, 5));
    bool suggest(List<Transaction> recent,
            {List<RecurringTemplate> templates = const [],
            Set<String> seen = const {}}) =>
        shouldSuggestRecurring(
            last: last, recent: recent, templates: templates, seen: seen);

    test('mismo monto y categoría el mes anterior', () {
      expect(suggest([_tx(1, DateTime(2026, 9, 5)), last]), isTrue);
    });

    test('no si fue hace dos meses, con otro monto o ya es recurrente', () {
      expect(suggest([_tx(1, DateTime(2026, 8, 5)), last]), isFalse);
      expect(
          suggest([_tx(1, DateTime(2026, 9, 5), amount: 5990), last]), isFalse);
      expect(
          suggest([
            _tx(1, DateTime(2026, 9, 5)),
            last
          ], templates: const [
            RecurringTemplate(
                id: 1,
                categoryId: 'suscripciones',
                amount: 9990,
                note: '',
                dayOfMonth: 5,
                active: true,
                lastGeneratedYearMonth: 202609,
                mode: 'auto')
          ]),
          isFalse);
      expect(
          suggest([_tx(1, DateTime(2026, 9, 5)), last],
              seen: {recurringSuggestionKey('suscripciones', 9990)}),
          isFalse);
    });
  });
}
