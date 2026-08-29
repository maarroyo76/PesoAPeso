import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import 'connection.dart';

part 'app_database.g.dart';

// --- Esquema -----------------------------------------------------------

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get colorValue => integer()();
  // RF03 ampliado: key hacia `kSelectableCategoryIcons` (core/theme/category_icons.dart).
  // Default 'category' == el mismo Icons.category_outlined que ya se usaba como
  // fallback antes de que el ícono fuera elegible.
  TextColumn get iconKey => text().withDefault(const Constant('category'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Presupuesto de una categoría, versionado por mes. Si un mes no tiene fila
/// propia, el valor vigente es el de la fila anterior más reciente (ver
/// `resolveBudgetsForMonth` en `core/utils/budget_resolver.dart`). Editar el
/// presupuesto desde la UI solo escribe/actualiza la fila del mes actual —
/// nunca reescribe meses pasados.
class CategoryBudgets extends Table {
  TextColumn get categoryId => text().references(Categories, #id)();
  IntColumn get year => integer()();
  IntColumn get month => integer()();
  IntColumn get amount => integer()();

  @override
  Set<Column> get primaryKey => {categoryId, year, month};
}

/// RF04 (corrección): presupuesto mensual TOTAL, fijado directamente por el
/// usuario — NO es la suma de CategoryBudgets. Versionado igual que
/// CategoryBudgets (ver `resolveMonthlyBudgetForMonth`). La diferencia entre
/// este total y lo asignado en categorías es una reserva sin asignar; se
/// calcula siempre al vuelo, nunca se guarda como columna aparte. Si lo
/// asignado en categorías supera este total, es un estado de
/// sobre-asignación que la UI debe advertir.
class MonthlyBudgets extends Table {
  IntColumn get year => integer()();
  IntColumn get month => integer()();
  IntColumn get amount => integer()();

  @override
  Set<Column> get primaryKey => {year, month};
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get categoryId => text().references(Categories, #id)();
  IntColumn get amount => integer()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().withDefault(const Constant(''))();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
}

/// RF12: plantilla de gasto recurrente (arriendo, suscripciones). Se crea al
/// marcar "Gasto recurrente" en Agregar. `lastGeneratedYearMonth` (formato
/// yyyyMM) evita generar dos veces la ocurrencia de un mismo mes.
class RecurringTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get categoryId => text().references(Categories, #id)();
  IntColumn get amount => integer()();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get dayOfMonth => integer()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  IntColumn get lastGeneratedYearMonth => integer()();
}

/// RF24: acceso rápido de gasto (RF02), configurable por el usuario — antes
/// era la lista fija `kQuickTemplates` en código. Distinto de
/// RecurringTemplates (RF12/RF25): esto es un monto frecuente de un toque
/// (ej. café), no un cargo que se repite solo cada mes.
class QuickExpenseTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text()();
  IntColumn get amount => integer()();
  TextColumn get categoryId => text().references(Categories, #id)();
}

/// RF13: meta de ahorro con nombre y monto objetivo. El progreso se calcula
/// sumando SavingsContributions — no se guarda como campo derivado.
class SavingsGoals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get targetAmount => integer()();
}

/// RF14: aporte manual a una meta.
class SavingsContributions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get goalId => integer().references(SavingsGoals, #id)();
  IntColumn get amount => integer()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().withDefault(const Constant(''))();
}

/// RF19: acceso rápido de aporte a una meta — monto fijo o % del presupuesto
/// mensual total —, con CRUD de usuario. `mode` es 'fixed' o 'percent'.
class SavingsQuickAdds extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get goalId => integer().references(SavingsGoals, #id)();
  TextColumn get label => text()();
  TextColumn get mode => text()();
  IntColumn get value => integer()();
}

/// Almacén simple clave/valor. Usado por RF15 para recordar el mes de la
/// última sesión y no repetir el aviso de remanente.
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Defaults históricos de RF02 (antes hardcodeados en `kQuickTemplates`),
/// usados tanto en `onCreate` como al migrar instalaciones existentes en
/// `onUpgrade` (from < 7), para que nadie pierda sus accesos rápidos.
final _defaultQuickExpenseTemplates = [
  QuickExpenseTemplatesCompanion.insert(
      label: 'Café', amount: 2500, categoryId: 'alimentacion'),
  QuickExpenseTemplatesCompanion.insert(
      label: 'Colación', amount: 3500, categoryId: 'alimentacion'),
  QuickExpenseTemplatesCompanion.insert(
      label: 'Micro/Metro', amount: 790, categoryId: 'transporte'),
  QuickExpenseTemplatesCompanion.insert(
      label: 'Bencina', amount: 20000, categoryId: 'transporte'),
  QuickExpenseTemplatesCompanion.insert(
      label: 'Salida', amount: 15000, categoryId: 'ocio'),
];

// --- Base de datos -------------------------------------------------------

@DriftDatabase(tables: [
  Categories,
  CategoryBudgets,
  Transactions,
  RecurringTemplates,
  AppSettings,
  SavingsGoals,
  SavingsContributions,
  SavingsQuickAdds,
  MonthlyBudgets,
  QuickExpenseTemplates,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openDatabaseConnection());

  @visibleForTesting
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          final now = DateTime.now();
          await batch((b) {
            b.insertAll(categories, [
              CategoriesCompanion.insert(
                  id: 'alimentacion',
                  name: 'Alimentación',
                  colorValue: 0xFF2F6F4E,
                  iconKey: const Value('restaurant')),
              CategoriesCompanion.insert(
                  id: 'transporte',
                  name: 'Transporte',
                  colorValue: 0xFFB8842E,
                  iconKey: const Value('directions_car')),
              CategoriesCompanion.insert(
                  id: 'vivienda',
                  name: 'Vivienda',
                  colorValue: 0xFF3B6B78,
                  iconKey: const Value('home')),
              CategoriesCompanion.insert(
                  id: 'ocio',
                  name: 'Ocio',
                  colorValue: 0xFF6B3F5C,
                  iconKey: const Value('theaters')),
              CategoriesCompanion.insert(
                  id: 'salud',
                  name: 'Salud',
                  colorValue: 0xFF4B7A3E,
                  iconKey: const Value('favorite')),
              CategoriesCompanion.insert(
                  id: 'compras',
                  name: 'Compras',
                  colorValue: 0xFF8A5A2B,
                  iconKey: const Value('shopping_bag')),
            ]);
            b.insertAll(categoryBudgets, [
              CategoryBudgetsCompanion.insert(
                  categoryId: 'alimentacion',
                  year: now.year,
                  month: now.month,
                  amount: 150000),
              CategoryBudgetsCompanion.insert(
                  categoryId: 'transporte',
                  year: now.year,
                  month: now.month,
                  amount: 40000),
              CategoryBudgetsCompanion.insert(
                  categoryId: 'vivienda',
                  year: now.year,
                  month: now.month,
                  amount: 250000),
              CategoryBudgetsCompanion.insert(
                  categoryId: 'ocio',
                  year: now.year,
                  month: now.month,
                  amount: 60000),
              CategoryBudgetsCompanion.insert(
                  categoryId: 'salud',
                  year: now.year,
                  month: now.month,
                  amount: 30000),
              CategoryBudgetsCompanion.insert(
                  categoryId: 'compras',
                  year: now.year,
                  month: now.month,
                  amount: 50000),
            ]);
            // Mismo total que la suma de las categorías seedeadas arriba, para
            // que una instalación nueva no arranque en estado de
            // sobre-asignación por defecto.
            b.insert(
              monthlyBudgets,
              MonthlyBudgetsCompanion.insert(
                  year: now.year, month: now.month, amount: 580000),
            );
            b.insertAll(quickExpenseTemplates, _defaultQuickExpenseTemplates);
          });
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v1 tenía `categories.monthly_budget` como valor único mutable.
            // Lo migramos a una fila de CategoryBudgets del mes actual (sin
            // backfill histórico — no hay datos de usuarios reales todavía)
            // y luego recreamos `categories` sin esa columna.
            final now = DateTime.now();
            final oldBudgets =
                await customSelect('SELECT id, monthly_budget FROM categories')
                    .get();
            await m.createTable(categoryBudgets);
            for (final row in oldBudgets) {
              await into(categoryBudgets).insert(
                CategoryBudgetsCompanion.insert(
                  categoryId: row.read<String>('id'),
                  year: now.year,
                  month: now.month,
                  amount: row.read<int>('monthly_budget'),
                ),
              );
            }
            await m.alterTable(TableMigration(categories));
          }
          if (from < 3) {
            await m.createTable(recurringTemplates);
          }
          if (from < 4) {
            await m.createTable(savingsGoals);
            await m.createTable(savingsContributions);
            await m.createTable(savingsQuickAdds);
          }
          if (from < 5) {
            await m.createTable(appSettings);
          }
          if (from < 6) {
            await m.createTable(monthlyBudgets);
          }
          if (from < 7) {
            // RF24: los accesos rápidos eran una lista fija en código
            // (kQuickTemplates); al pasar a ser editables por el usuario, se
            // seedean con los mismos 5 que ya tenía todo el mundo, para no
            // cambiarle la pantalla de Agregar a nadie de un día para otro.
            await m.createTable(quickExpenseTemplates);
            await batch((b) => b.insertAll(
                quickExpenseTemplates, _defaultQuickExpenseTemplates));
            // RF23: el onboarding es solo para instalaciones nuevas (ver
            // onCreate). Quien ya tenía la app instalada antes de este
            // cambio ya configuró todo a mano — marcarlo como completado
            // acá evita que le aparezca el wizard de la nada en el próximo
            // inicio.
            await into(appSettings).insertOnConflictUpdate(
              AppSettingsCompanion.insert(
                  key: 'onboarding_completed', value: 'true'),
            );
          }
          if (from < 8) {
            // RF03 ampliado: el ícono de categoría pasa de derivarse del id
            // (mapeo fijo en código) a ser elegible y guardado en la fila.
            // Backfill: las 6 categorías default heredan su ícono de siempre;
            // cualquier categoría propia del usuario queda en el default de
            // la columna ('category'), que es exactamente el mismo ícono de
            // respaldo (Icons.category_outlined) que ya se usaba para ellas.
            //
            // Si `from < 2` corrió arriba, `alterTable(TableMigration(categories))`
            // ya reconstruyó la tabla con el esquema ACTUAL de Categories —
            // que ya incluye iconKey —, así que agregarla de nuevo acá
            // fallaría con "duplicate column". Solo hace falta agregarla a
            // mano cuando no pasamos por ese camino (from >= 2).
            if (from >= 2) {
              await m.addColumn(categories, categories.iconKey);
            }
            const legacyIconByCategoryId = {
              'alimentacion': 'restaurant',
              'transporte': 'directions_car',
              'vivienda': 'home',
              'ocio': 'theaters',
              'salud': 'favorite',
              'compras': 'shopping_bag',
            };
            for (final entry in legacyIconByCategoryId.entries) {
              await (update(categories)..where((c) => c.id.equals(entry.key)))
                  .write(CategoriesCompanion(iconKey: Value(entry.value)));
            }
          }
        },
      );

  Future<int> deleteTransaction(int id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();

  Future<void> updateTransaction({
    required int id,
    required String categoryId,
    required int amount,
    required DateTime date,
    required String note,
    required bool isRecurring,
  }) {
    return (update(transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        categoryId: Value(categoryId),
        amount: Value(amount),
        date: Value(date),
        note: Value(note),
        isRecurring: Value(isRecurring),
      ),
    );
  }

  /// Streams para que la UI se actualice sola cuando cambian los datos.
  Stream<List<Category>> watchCategories() => select(categories).watch();

  Future<void> insertCategory(
      {required String id,
      required String name,
      required int colorValue,
      required String iconKey}) {
    return into(categories).insert(CategoriesCompanion.insert(
        id: id, name: name, colorValue: colorValue, iconKey: Value(iconKey)));
  }

  Future<void> updateCategoryInfo(String id,
      {required String name,
      required int colorValue,
      required String iconKey}) {
    return (update(categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
          name: Value(name),
          colorValue: Value(colorValue),
          iconKey: Value(iconKey)),
    );
  }

  Future<int> countTransactionsForCategory(String categoryId) async {
    final rows = await (select(transactions)
          ..where((t) => t.categoryId.equals(categoryId)))
        .get();
    return rows.length;
  }

  Future<int> countRecurringTemplatesForCategory(String categoryId) async {
    final rows = await (select(recurringTemplates)
          ..where((t) => t.categoryId.equals(categoryId)))
        .get();
    return rows.length;
  }

  Future<int> countQuickExpenseTemplatesForCategory(String categoryId) async {
    final rows = await (select(quickExpenseTemplates)
          ..where((t) => t.categoryId.equals(categoryId)))
        .get();
    return rows.length;
  }

  Future<void> deleteCategory(String id) async {
    await (delete(categoryBudgets)..where((b) => b.categoryId.equals(id))).go();
    await (delete(categories)..where((c) => c.id.equals(id))).go();
  }

  Stream<List<CategoryBudget>> watchAllBudgets() =>
      select(categoryBudgets).watch();

  /// Crea o actualiza la fila de presupuesto de [categoryId] para el mes de
  /// [month]. Nunca toca filas de otros meses.
  Future<void> setBudgetForMonth(
      String categoryId, DateTime month, int amount) {
    return into(categoryBudgets).insertOnConflictUpdate(
      CategoryBudgetsCompanion.insert(
        categoryId: categoryId,
        year: month.year,
        month: month.month,
        amount: amount,
      ),
    );
  }

  Stream<List<MonthlyBudget>> watchAllMonthlyBudgets() =>
      select(monthlyBudgets).watch();

  /// Crea o actualiza la fila del presupuesto TOTAL de [month]. Mismo
  /// criterio que [setBudgetForMonth]: nunca toca filas de otros meses.
  Future<void> setMonthlyBudgetForMonth(DateTime month, int amount) {
    return into(monthlyBudgets).insertOnConflictUpdate(
      MonthlyBudgetsCompanion.insert(
        year: month.year,
        month: month.month,
        amount: amount,
      ),
    );
  }

  // --- Accesos rápidos de gasto (RF02/RF24) --------------------------------

  Stream<List<QuickExpenseTemplate>> watchQuickExpenseTemplates() =>
      select(quickExpenseTemplates).watch();

  Future<int> insertQuickExpenseTemplate(
      {required String label,
      required int amount,
      required String categoryId}) {
    return into(quickExpenseTemplates).insert(
      QuickExpenseTemplatesCompanion.insert(
          label: label, amount: amount, categoryId: categoryId),
    );
  }

  Future<void> updateQuickExpenseTemplate(int id,
      {required String label,
      required int amount,
      required String categoryId}) {
    return (update(quickExpenseTemplates)..where((t) => t.id.equals(id))).write(
      QuickExpenseTemplatesCompanion(
          label: Value(label),
          amount: Value(amount),
          categoryId: Value(categoryId)),
    );
  }

  Future<void> deleteQuickExpenseTemplate(int id) =>
      (delete(quickExpenseTemplates)..where((t) => t.id.equals(id))).go();

  Stream<List<Transaction>> watchTransactionsForMonth(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return (select(transactions)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end)))
        .watch();
  }

  Future<List<Transaction>> transactionsForMonth(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return (select(transactions)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end)))
        .get();
  }

  Future<int> totalSpentByCategory(String categoryId, DateTime month) async {
    final rows = await transactionsForMonth(month);
    return rows
        .where((t) => t.categoryId == categoryId)
        .fold<int>(0, (sum, t) => sum + t.amount);
  }

  Stream<List<RecurringTemplate>> watchRecurringTemplates() =>
      select(recurringTemplates).watch();

  Future<void> insertRecurringTemplate({
    required String categoryId,
    required int amount,
    required String note,
    required int dayOfMonth,
    required int initialYearMonth,
  }) {
    return into(recurringTemplates).insert(
      RecurringTemplatesCompanion.insert(
        categoryId: categoryId,
        amount: amount,
        note: Value(note),
        dayOfMonth: dayOfMonth,
        lastGeneratedYearMonth: initialYearMonth,
      ),
    );
  }

  /// RF25: editar un recurrente ya creado (categoría, monto, nota, día del
  /// mes, activo/pausado). No toca `lastGeneratedYearMonth` — si el usuario
  /// sube el monto a mitad de mes, no vuelve a generar la ocurrencia ya
  /// hecha, solo cambia el monto de las futuras.
  Future<void> updateRecurringTemplate(
    int id, {
    required String categoryId,
    required int amount,
    required String note,
    required int dayOfMonth,
    required bool active,
  }) {
    return (update(recurringTemplates)..where((t) => t.id.equals(id))).write(
      RecurringTemplatesCompanion(
        categoryId: Value(categoryId),
        amount: Value(amount),
        note: Value(note),
        dayOfMonth: Value(dayOfMonth),
        active: Value(active),
      ),
    );
  }

  Future<void> deleteRecurringTemplate(int id) =>
      (delete(recurringTemplates)..where((t) => t.id.equals(id))).go();

  int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  /// RF12: revisa las plantillas activas al abrir la app y genera SOLO la
  /// ocurrencia del mes actual si todavía falta y ya pasó `dayOfMonth`. Sin
  /// backfill de meses saltados — evita gastos "fantasma" si el usuario
  /// estuvo mucho tiempo sin abrir la app. Devuelve las transacciones
  /// generadas (para el aviso de RF20).
  Future<List<Transaction>> runRecurringCatchUp() async {
    final now = DateTime.now();
    final currentYm = now.year * 100 + now.month;
    final templates = await (select(recurringTemplates)
          ..where((t) => t.active.equals(true)))
        .get();

    final generated = <Transaction>[];
    for (final tpl in templates) {
      if (tpl.lastGeneratedYearMonth >= currentYm) continue;
      if (now.day < tpl.dayOfMonth) continue;

      final day = tpl.dayOfMonth.clamp(1, _daysInMonth(now.year, now.month));
      final date = DateTime(now.year, now.month, day);
      final id = await into(transactions).insert(
        TransactionsCompanion.insert(
          categoryId: tpl.categoryId,
          amount: tpl.amount,
          date: date,
          note: Value(tpl.note),
          isRecurring: const Value(true),
        ),
      );
      await (update(recurringTemplates)..where((t) => t.id.equals(tpl.id)))
          .write(RecurringTemplatesCompanion(
              lastGeneratedYearMonth: Value(currentYm)));
      generated.add(await (select(transactions)..where((t) => t.id.equals(id)))
          .getSingle());
    }
    return generated;
  }

  // --- Metas de ahorro (RF13/RF14/RF19) -----------------------------------

  Stream<List<SavingsGoal>> watchSavingsGoals() => select(savingsGoals).watch();

  Future<int> insertSavingsGoal(
          {required String name, required int targetAmount}) =>
      into(savingsGoals).insert(
          SavingsGoalsCompanion.insert(name: name, targetAmount: targetAmount));

  Future<void> updateSavingsGoal(int id,
      {required String name, required int targetAmount}) {
    return (update(savingsGoals)..where((g) => g.id.equals(id))).write(
      SavingsGoalsCompanion(
          name: Value(name), targetAmount: Value(targetAmount)),
    );
  }

  Future<void> deleteSavingsGoal(int id) async {
    await (delete(savingsContributions)..where((c) => c.goalId.equals(id)))
        .go();
    await (delete(savingsQuickAdds)..where((q) => q.goalId.equals(id))).go();
    await (delete(savingsGoals)..where((g) => g.id.equals(id))).go();
  }

  /// Total aportado por meta, reactivo — la barra de progreso se recalcula
  /// sola con cada aporte nuevo.
  Stream<Map<int, int>> watchTotalContributedByGoal() {
    return select(savingsContributions).watch().map((rows) {
      final totals = <int, int>{};
      for (final r in rows) {
        totals[r.goalId] = (totals[r.goalId] ?? 0) + r.amount;
      }
      return totals;
    });
  }

  Stream<List<SavingsContribution>> watchContributionsForGoal(int goalId) {
    return (select(savingsContributions)
          ..where((c) => c.goalId.equals(goalId))
          ..orderBy([(c) => OrderingTerm.desc(c.date)]))
        .watch();
  }

  Future<void> addContribution(
      {required int goalId,
      required int amount,
      required DateTime date,
      String note = ''}) {
    return into(savingsContributions).insert(
      SavingsContributionsCompanion.insert(
          goalId: goalId, amount: amount, date: date, note: Value(note)),
    );
  }

  Future<void> deleteContribution(int id) =>
      (delete(savingsContributions)..where((c) => c.id.equals(id))).go();

  Stream<List<SavingsQuickAdd>> watchQuickAddsForGoal(int goalId) =>
      (select(savingsQuickAdds)..where((q) => q.goalId.equals(goalId))).watch();

  Future<void> insertSavingsQuickAdd(
      {required int goalId,
      required String label,
      required String mode,
      required int value}) {
    return into(savingsQuickAdds).insert(
      SavingsQuickAddsCompanion.insert(
          goalId: goalId, label: label, mode: mode, value: value),
    );
  }

  Future<void> updateSavingsQuickAdd(int id,
      {required String label, required String mode, required int value}) {
    return (update(savingsQuickAdds)..where((q) => q.id.equals(id))).write(
      SavingsQuickAddsCompanion(
          label: Value(label), mode: Value(mode), value: Value(value)),
    );
  }

  Future<void> deleteSavingsQuickAdd(int id) =>
      (delete(savingsQuickAdds)..where((q) => q.id.equals(id))).go();

  // --- Settings (RF15) -----------------------------------------------------

  Future<String?> getSetting(String key) async {
    final row = await (select(appSettings)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) {
    return into(appSettings).insertOnConflictUpdate(
        AppSettingsCompanion.insert(key: key, value: value));
  }

  // --- Respaldo local (RF16/RF17/RNF09) -------------------------------------

  /// Vuelca todas las tablas a JSON, listo para escribir a un archivo local.
  Future<Map<String, dynamic>> exportAllData() async {
    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'categories':
          (await select(categories).get()).map((r) => r.toJson()).toList(),
      'categoryBudgets':
          (await select(categoryBudgets).get()).map((r) => r.toJson()).toList(),
      'monthlyBudgets':
          (await select(monthlyBudgets).get()).map((r) => r.toJson()).toList(),
      'transactions':
          (await select(transactions).get()).map((r) => r.toJson()).toList(),
      'recurringTemplates': (await select(recurringTemplates).get())
          .map((r) => r.toJson())
          .toList(),
      'quickExpenseTemplates': (await select(quickExpenseTemplates).get())
          .map((r) => r.toJson())
          .toList(),
      'savingsGoals':
          (await select(savingsGoals).get()).map((r) => r.toJson()).toList(),
      'savingsContributions': (await select(savingsContributions).get())
          .map((r) => r.toJson())
          .toList(),
      'savingsQuickAdds': (await select(savingsQuickAdds).get())
          .map((r) => r.toJson())
          .toList(),
      'appSettings':
          (await select(appSettings).get()).map((r) => r.toJson()).toList(),
    };
  }

  /// Reemplaza todos los datos actuales por los del respaldo [data] (mismo
  /// formato de [exportAllData]). Todo o nada: corre en una transacción.
  Future<void> restoreAllData(Map<String, dynamic> data) async {
    await transaction(() async {
      await delete(savingsQuickAdds).go();
      await delete(savingsContributions).go();
      await delete(savingsGoals).go();
      await delete(recurringTemplates).go();
      await delete(quickExpenseTemplates).go();
      await delete(transactions).go();
      await delete(categoryBudgets).go();
      await delete(monthlyBudgets).go();
      await delete(categories).go();
      await delete(appSettings).go();

      for (final row
          in (data['categories'] as List).cast<Map<String, dynamic>>()) {
        // Respaldos hechos antes de RF03 ampliado (ícono elegible) no traen
        // `iconKey` — sin este fallback, Category.fromJson revienta con un
        // cast de null a String en vez de restaurar con el ícono default.
        row.putIfAbsent('iconKey', () => 'category');
        await into(categories)
            .insertOnConflictUpdate(Category.fromJson(row).toCompanion(false));
      }
      for (final row
          in (data['categoryBudgets'] as List).cast<Map<String, dynamic>>()) {
        await into(categoryBudgets).insertOnConflictUpdate(
            CategoryBudget.fromJson(row).toCompanion(false));
      }
      // `?? []`: respaldos hechos antes de agregar esta tabla no traen la
      // clave — restaurarlos no debe fallar, solo dejar el total sin fijar.
      for (final row in (data['monthlyBudgets'] as List? ?? [])
          .cast<Map<String, dynamic>>()) {
        await into(monthlyBudgets).insertOnConflictUpdate(
            MonthlyBudget.fromJson(row).toCompanion(false));
      }
      for (final row
          in (data['transactions'] as List).cast<Map<String, dynamic>>()) {
        await into(transactions).insertOnConflictUpdate(
            Transaction.fromJson(row).toCompanion(false));
      }
      for (final row in (data['recurringTemplates'] as List)
          .cast<Map<String, dynamic>>()) {
        await into(recurringTemplates).insertOnConflictUpdate(
            RecurringTemplate.fromJson(row).toCompanion(false));
      }
      // `?? []`: respaldos hechos antes de agregar esta tabla no traen la
      // clave — restaurarlos no debe fallar, solo dejar los accesos rápidos
      // vacíos (el usuario los vuelve a crear).
      for (final row in (data['quickExpenseTemplates'] as List? ?? [])
          .cast<Map<String, dynamic>>()) {
        await into(quickExpenseTemplates).insertOnConflictUpdate(
            QuickExpenseTemplate.fromJson(row).toCompanion(false));
      }
      for (final row
          in (data['savingsGoals'] as List).cast<Map<String, dynamic>>()) {
        await into(savingsGoals).insertOnConflictUpdate(
            SavingsGoal.fromJson(row).toCompanion(false));
      }
      for (final row in (data['savingsContributions'] as List)
          .cast<Map<String, dynamic>>()) {
        await into(savingsContributions).insertOnConflictUpdate(
            SavingsContribution.fromJson(row).toCompanion(false));
      }
      for (final row
          in (data['savingsQuickAdds'] as List).cast<Map<String, dynamic>>()) {
        await into(savingsQuickAdds).insertOnConflictUpdate(
            SavingsQuickAdd.fromJson(row).toCompanion(false));
      }
      for (final row in (data['appSettings'] as List? ?? [])
          .cast<Map<String, dynamic>>()) {
        await into(appSettings).insertOnConflictUpdate(
            AppSetting.fromJson(row).toCompanion(false));
      }
    });
  }
}
