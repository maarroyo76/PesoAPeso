import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/repositories/backup_repository.dart';
import '../../data/repositories/categories_repository.dart';
import '../../data/repositories/quick_expense_templates_repository.dart';
import '../../data/repositories/recurring_templates_repository.dart';
import '../../data/repositories/savings_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/transactions_repository.dart';
import '../utils/budget_resolver.dart';

/// Una sola instancia de la base de datos para toda la app.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final categoriesRepositoryProvider = Provider<CategoriesRepository>(
  (ref) => CategoriesRepository(ref.watch(appDatabaseProvider)),
);

final transactionsRepositoryProvider = Provider<TransactionsRepository>(
  (ref) => TransactionsRepository(ref.watch(appDatabaseProvider)),
);

final recurringTemplatesRepositoryProvider =
    Provider<RecurringTemplatesRepository>(
  (ref) => RecurringTemplatesRepository(ref.watch(appDatabaseProvider)),
);

/// RF25: lista reactiva de recurrentes ya creados, para verlos/editarlos.
final recurringTemplatesProvider = StreamProvider(
    (ref) => ref.watch(recurringTemplatesRepositoryProvider).watchTemplates());

final quickExpenseTemplatesRepositoryProvider =
    Provider<QuickExpenseTemplatesRepository>(
  (ref) => QuickExpenseTemplatesRepository(ref.watch(appDatabaseProvider)),
);

/// RF02/RF24: accesos rápidos de gasto configurables por el usuario.
final quickExpenseTemplatesProvider = StreamProvider(
    (ref) => ref.watch(quickExpenseTemplatesRepositoryProvider).watchAll());

final savingsRepositoryProvider = Provider<SavingsRepository>(
  (ref) => SavingsRepository(ref.watch(appDatabaseProvider)),
);

final savingsGoalsProvider =
    StreamProvider((ref) => ref.watch(savingsRepositoryProvider).watchGoals());

final savingsTotalsProvider = StreamProvider<Map<int, int>>((ref) =>
    ref.watch(savingsRepositoryProvider).watchTotalContributedByGoal());

final goalContributionsProvider = StreamProvider.family((ref, int goalId) =>
    ref.watch(savingsRepositoryProvider).watchContributions(goalId));

final goalQuickAddsProvider = StreamProvider.family((ref, int goalId) =>
    ref.watch(savingsRepositoryProvider).watchQuickAdds(goalId));

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(appDatabaseProvider)),
);

final backupRepositoryProvider = Provider<BackupRepository>(
  (ref) => BackupRepository(ref.watch(appDatabaseProvider)),
);

/// Streams que las pantallas consumen directamente. Cualquier insert en
/// TransactionsRepository hace que estos providers se recalculen solos.
final categoriesProvider = StreamProvider(
    (ref) => ref.watch(categoriesRepositoryProvider).watchCategories());

final monthTransactionsProvider = StreamProvider.family((ref, DateTime month) =>
    ref.watch(transactionsRepositoryProvider).watchTransactionsForMonth(month));

final categoryBudgetsProvider = StreamProvider(
    (ref) => ref.watch(categoriesRepositoryProvider).watchAllBudgets());

/// Presupuesto vigente por categoría para [month]: la fila propia de ese mes
/// si existe, o la más reciente anterior. Se recalcula solo cuando cambia
/// categoryBudgetsProvider (cualquier edición de presupuesto).
final monthBudgetsProvider = Provider.family<Map<String, int>, DateTime>(
  (ref, month) => resolveBudgetsForMonth(
    ref.watch(categoryBudgetsProvider).valueOrNull ?? const [],
    month,
  ),
);

final monthlyBudgetsProvider = StreamProvider(
    (ref) => ref.watch(categoriesRepositoryProvider).watchAllMonthlyBudgets());

/// Presupuesto TOTAL vigente para [month] — fijado directamente por el
/// usuario, NO es la suma de monthBudgetsProvider. 0 si nunca se fijó.
final monthTotalBudgetProvider = Provider.family<int, DateTime>(
  (ref, month) => resolveMonthlyBudgetForMonth(
    ref.watch(monthlyBudgetsProvider).valueOrNull ?? const [],
    month,
  ),
);
