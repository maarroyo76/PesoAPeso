import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/repositories/backup_repository.dart';
import '../../data/repositories/categories_repository.dart';
import '../../data/repositories/payment_methods_repository.dart';
import '../../data/repositories/quick_expense_templates_repository.dart';
import '../../data/repositories/recurring_templates_repository.dart';
import '../../data/repositories/savings_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/transactions_repository.dart';
import '../utils/budget_resolver.dart';

/// Mes calendario en curso. Se refresca al volver la app a primer plano, para
/// que una sesión que cruza el cambio de mes no siga mostrando el mes viejo.
final currentMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// Pestaña visible del RootShell. Es un provider para que otras pantallas
/// puedan llevar al usuario a otra pestaña (UX10: Resumen vacío → Agregar).
final selectedTabProvider = StateProvider<int>((ref) => 0);

/// Índice de la pestaña Agregar en el RootShell.
const kAgregarTabIndex = 1;

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

/// RF51: total aportado a metas en [month]; sale del presupuesto del mes.
final monthContributedProvider = StreamProvider.family((ref, DateTime month) =>
    ref.watch(savingsRepositoryProvider).watchContributedInMonth(month));

final goalContributionsProvider = StreamProvider.family((ref, int goalId) =>
    ref.watch(savingsRepositoryProvider).watchContributions(goalId));

final goalQuickAddsProvider = StreamProvider.family((ref, int goalId) =>
    ref.watch(savingsRepositoryProvider).watchQuickAdds(goalId));

final paymentMethodsRepositoryProvider = Provider<PaymentMethodsRepository>(
  (ref) => PaymentMethodsRepository(ref.watch(appDatabaseProvider)),
);

/// RF31: métodos de pago, en el orden en que se crearon.
final paymentMethodsProvider = StreamProvider(
    (ref) => ref.watch(paymentMethodsRepositoryProvider).watchPaymentMethods());

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

/// Presupuesto BASE por categoría para [month]: la fila propia de ese mes si
/// existe, o la más reciente anterior. Es lo que se edita en Presupuestos;
/// no incluye los ajustes de un solo mes (RF50).
final monthBaseBudgetsProvider = Provider.family<Map<String, int>, DateTime>(
  (ref, month) => resolveBudgetsForMonth(
    ref.watch(categoryBudgetsProvider).valueOrNull ?? const [],
    month,
  ),
);

final monthlyAdjustmentsProvider = StreamProvider(
    (ref) => ref.watch(categoriesRepositoryProvider).watchAllAdjustments());

/// RF50: ajustes de un solo mes (p. ej. el remanente del mes anterior).
final monthAdjustmentsProvider =
    Provider.family<List<MonthlyAdjustment>, DateTime>(
  (ref, month) => adjustmentsForMonth(
    ref.watch(monthlyAdjustmentsProvider).valueOrNull ?? const [],
    month,
  ),
);

/// Presupuesto vigente por categoría para [month]: base más ajustes del mes.
/// Se recalcula solo con cualquier edición de presupuesto o ajuste.
final monthBudgetsProvider = Provider.family<Map<String, int>, DateTime>(
  (ref, month) => withCategoryAdjustments(
    ref.watch(monthBaseBudgetsProvider(month)),
    ref.watch(monthAdjustmentsProvider(month)),
  ),
);

final monthlyBudgetsProvider = StreamProvider(
    (ref) => ref.watch(categoriesRepositoryProvider).watchAllMonthlyBudgets());

/// Presupuesto TOTAL base para [month] — fijado directamente por el usuario,
/// NO es la suma de los presupuestos por categoría. 0 si nunca se fijó.
final monthBaseTotalBudgetProvider = Provider.family<int, DateTime>(
  (ref, month) => resolveMonthlyBudgetForMonth(
    ref.watch(monthlyBudgetsProvider).valueOrNull ?? const [],
    month,
  ),
);

/// Presupuesto TOTAL vigente para [month]: base más todos los ajustes del mes.
final monthTotalBudgetProvider = Provider.family<int, DateTime>(
  (ref, month) => withTotalAdjustments(
    ref.watch(monthBaseTotalBudgetProvider(month)),
    ref.watch(monthAdjustmentsProvider(month)),
  ),
);
