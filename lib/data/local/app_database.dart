import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import '../../core/utils/installments.dart';
import '../backup/backup_validation.dart';
import 'connection.dart';

part 'app_database.g.dart';

// --- Esquema -----------------------------------------------------------
//
// Las claves foráneas se declaran como `customConstraints` de tabla y no con
// `.references()`: drift_dev 2.31 no reconoce el nombre de la tabla dentro de
// `references(...)` con el analyzer actual (lo trata como type literal), avisa
// "This parameter should be a simple class name" y genera la columna SIN
// `REFERENCES`. Así quedaron las tablas hasta v8. drift_dev >= 2.32 lo
// corrige, pero exige sqlite3 ^3, que reemplaza a sqlcipher_flutter_libs.

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get colorValue => integer()();
  // RF03 ampliado: key hacia `kSelectableCategoryIcons` (core/theme/category_icons.dart).
  // Default 'category' == el mismo Icons.category_outlined que ya se usaba como
  // fallback antes de que el ícono fuera elegible.
  TextColumn get iconKey => text().withDefault(const Constant('category'))();

  /// RF53: archivada. No se ofrece al registrar ni en Presupuestos, pero
  /// sigue en el historial y en Estadísticas, y se puede restaurar.
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Presupuesto de una categoría, versionado por mes. Si un mes no tiene fila
/// propia, el valor vigente es el de la fila anterior más reciente (ver
/// `resolveBudgetsForMonth` en `core/utils/budget_resolver.dart`). Editar el
/// presupuesto desde la UI solo escribe/actualiza la fila del mes actual —
/// nunca reescribe meses pasados.
class CategoryBudgets extends Table {
  TextColumn get categoryId => text()();
  IntColumn get year => integer()();
  IntColumn get month => integer()();
  IntColumn get amount => integer()();

  @override
  Set<Column> get primaryKey => {categoryId, year, month};

  @override
  List<String> get customConstraints =>
      ['FOREIGN KEY (category_id) REFERENCES categories (id)'];
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

/// Tipos de método de pago (columna `PaymentMethods.kind`).
const kPaymentKindCash = 'cash';
const kPaymentKindDebit = 'debit';
const kPaymentKindCredit = 'credit';
const kPaymentKinds = [kPaymentKindCash, kPaymentKindDebit, kPaymentKindCredit];

/// RF31: método de pago con alias ("CMR", "Débito Santander"). RNF16: nunca
/// se guarda el número completo, el CVV ni el vencimiento; a lo más los
/// últimos 4 dígitos. Los días de facturación y de pago (RF33) solo tienen
/// sentido en crédito.
class PaymentMethods extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get alias => text()();
  TextColumn get kind => text()();
  IntColumn get colorValue => integer()();
  TextColumn get last4 => text().nullable()();
  IntColumn get billingDay => integer().nullable()();
  IntColumn get dueDay => integer().nullable()();

  @override
  List<String> get customConstraints => [
        "CHECK (kind IN ('cash', 'debit', 'credit'))",
        // RNF16: también se valida en la base, no solo en el formulario.
        "CHECK (last4 IS NULL OR (length(last4) BETWEEN 1 AND 4 "
            "AND last4 NOT GLOB '*[^0-9]*'))",
        'CHECK (billing_day IS NULL OR billing_day BETWEEN 1 AND 31)',
        'CHECK (due_day IS NULL OR due_day BETWEEN 1 AND 31)',
      ];
}

/// RF34: compra en cuotas con tarjeta de crédito. Cada cuota es un gasto
/// normal (Transactions con `installmentPlanId`), generado al crear el plan:
/// así Resumen, Presupuestos y Estadísticas las cuentan sin lógica especial,
/// y lo comprometido en los meses siguientes (RF36) se ve desde el primer día.
class InstallmentPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get paymentMethodId => integer()();
  TextColumn get categoryId => text()();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get totalAmount => integer()();
  IntColumn get installmentCount => integer()();
  DateTimeColumn get purchaseDate => dateTime()();

  /// RF35: prepagado; las cuotas futuras se reemplazaron por un solo pago.
  BoolColumn get prepaid => boolean().withDefault(const Constant(false))();

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (payment_method_id) REFERENCES payment_methods (id)',
        'FOREIGN KEY (category_id) REFERENCES categories (id)',
        'CHECK (installment_count BETWEEN 2 AND 48)',
      ];
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get categoryId => text()();
  IntColumn get amount => integer()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().withDefault(const Constant(''))();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();

  /// Plantilla recurrente (RF12) que generó este gasto, para poder ir de un
  /// gasto a su recurrente. Null en gastos manuales, en los anteriores a v9
  /// que no se pudieron enlazar, y si la plantilla se eliminó.
  IntColumn get recurringTemplateId => integer().nullable()();

  /// RF32: con qué se pagó. Null = "Sin especificar": todos los gastos
  /// anteriores a v10 (RNF18) y los que el usuario no asignó.
  IntColumn get paymentMethodId => integer().nullable()();

  /// RF34: plan de cuotas al que pertenece, y qué cuota es (desde 1). El
  /// prepago (RF35) también lleva el plan, pero sin número de cuota.
  IntColumn get installmentPlanId => integer().nullable()();
  IntColumn get installmentNumber => integer().nullable()();

  /// RF52: meta de ahorro con que se pagó. Descuenta del saldo de la meta y
  /// no del presupuesto del mes; sigue contando en su categoría en
  /// Estadísticas.
  IntColumn get fundedByGoalId => integer().nullable()();

  /// RF37: revisión semanal. true = "valió la pena", false = "no tanto",
  /// null = no revisado.
  BoolColumn get worthIt => boolean().nullable()();

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (category_id) REFERENCES categories (id)',
        'FOREIGN KEY (recurring_template_id) REFERENCES recurring_templates (id) '
            'ON DELETE SET NULL',
        'FOREIGN KEY (payment_method_id) REFERENCES payment_methods (id)',
        'FOREIGN KEY (installment_plan_id) REFERENCES installment_plans (id)',
        'FOREIGN KEY (funded_by_goal_id) REFERENCES savings_goals (id)',
      ];
}

/// RF12: plantilla de gasto recurrente (arriendo, suscripciones). Se crea al
/// marcar "Gasto recurrente" en Agregar. `lastGeneratedYearMonth` (formato
/// yyyyMM) evita generar dos veces la ocurrencia de un mismo mes.
class RecurringTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get categoryId => text()();
  IntColumn get amount => integer()();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get dayOfMonth => integer()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  IntColumn get lastGeneratedYearMonth => integer()();

  /// RF47: 'auto' (pago fijo mensual, se registra solo) o 'confirm' (gasto
  /// habitual: pide confirmación cada día programado). Ver
  /// `core/utils/habitual.dart`. En modo confirm no se usan `dayOfMonth` ni
  /// `lastGeneratedYearMonth` (quedan en 0).
  TextColumn get mode => text().withDefault(const Constant('auto'))();

  /// Solo modo confirm: días como máscara de bits (lunes = 1 … domingo = 64),
  /// hora del recordatorio "HH:mm" (RF48) y método de pago del gasto.
  IntColumn get weekdays => integer().nullable()();
  TextColumn get reminderTime => text().nullable()();
  IntColumn get paymentMethodId => integer().nullable()();

  /// Solo modo confirm: desde qué día hay pendientes (RF49). Se fija al crear
  /// y al reactivar, para que los días en pausa no aparezcan como pendientes.
  DateTimeColumn get startDate => dateTime().nullable()();

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (category_id) REFERENCES categories (id)',
        'FOREIGN KEY (payment_method_id) REFERENCES payment_methods (id)',
      ];
}

/// RF48/RF49: decisión del usuario sobre un día programado de un gasto
/// habitual. Un día programado sin fila es un pendiente. Con la plantilla se
/// borran sus decisiones; el gasto registrado se mantiene.
class HabitualOccurrences extends Table {
  IntColumn get templateId => integer()();
  DateTimeColumn get date => dateTime()();

  /// 'registered' o 'skipped' ("Hoy no").
  TextColumn get status => text()();
  IntColumn get transactionId => integer().nullable()();

  @override
  Set<Column> get primaryKey => {templateId, date};

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (template_id) REFERENCES recurring_templates (id) '
            'ON DELETE CASCADE',
        'FOREIGN KEY (transaction_id) REFERENCES transactions (id) '
            'ON DELETE SET NULL',
        "CHECK (status IN ('registered', 'skipped'))",
      ];
}

/// RF24: acceso rápido de gasto (RF02), configurable por el usuario — antes
/// era la lista fija `kQuickTemplates` en código. Distinto de
/// RecurringTemplates (RF12/RF25): esto es un monto frecuente de un toque
/// (ej. café), no un cargo que se repite solo cada mes.
class QuickExpenseTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text()();
  IntColumn get amount => integer()();
  TextColumn get categoryId => text()();

  @override
  List<String> get customConstraints =>
      ['FOREIGN KEY (category_id) REFERENCES categories (id)'];
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
  IntColumn get goalId => integer()();
  IntColumn get amount => integer()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().withDefault(const Constant(''))();

  @override
  List<String> get customConstraints =>
      ['FOREIGN KEY (goal_id) REFERENCES savings_goals (id)'];
}

/// RF19: acceso rápido de aporte a una meta — monto fijo o % del presupuesto
/// mensual total —, con CRUD de usuario. `mode` es 'fixed' o 'percent'.
class SavingsQuickAdds extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get goalId => integer()();
  TextColumn get label => text()();
  TextColumn get mode => text()();
  IntColumn get value => integer()();

  @override
  List<String> get customConstraints =>
      ['FOREIGN KEY (goal_id) REFERENCES savings_goals (id)'];
}

/// RF50 (corrige I1): ajuste del presupuesto que vale SOLO para un mes, sin
/// heredarse a los siguientes como las filas de CategoryBudgets /
/// MonthlyBudgets. Lo crea, por ejemplo, el remanente del mes anterior.
/// `categoryId` null = ajuste solo al total; con categoría, sube esa
/// categoría y también el total (es plata extra, no una reasignación).
class MonthlyAdjustments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get year => integer()();
  IntColumn get month => integer()();
  TextColumn get categoryId => text().nullable()();
  IntColumn get amount => integer()();
  TextColumn get reason => text().withDefault(const Constant(''))();

  @override
  List<String> get customConstraints =>
      ['FOREIGN KEY (category_id) REFERENCES categories (id)'];
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
/// usados al migrar instalaciones existentes en `onUpgrade` (from < 7),
/// para que nadie pierda sus accesos rápidos. Apuntan a las categorías del
/// catálogo anterior, que esas instalaciones tienen.
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

/// RF45: acceso por defecto para cargar la tarjeta bip!. Solo en
/// instalaciones nuevas (onCreate): la migración (from < 7) sigue creando
/// exactamente los cinco accesos de siempre.
const kBipTopUpLabel = 'Carga bip!';

/// Una categoría del catálogo por defecto.
typedef DefaultCategory = ({
  String id,
  String name,
  int colorValue,
  String iconKey,
  bool preselected,
});

/// Catálogo de instalaciones nuevas: según para qué fue el gasto, no dónde
/// se compró. Quien ya tenía la app conserva sus categorías (solo cambia
/// onCreate). Los ids de Transporte, Vivienda, Salud y Ocio son los de
/// siempre.
const List<DefaultCategory> kDefaultCategories = [
  (
    id: 'supermercado',
    name: 'Supermercado y feria',
    colorValue: 0xFF2F6F4E,
    iconKey: 'local_grocery_store',
    preselected: true
  ),
  (
    id: 'comida_fuera',
    name: 'Comida fuera',
    colorValue: 0xFFA63D2B,
    iconKey: 'restaurant',
    preselected: true
  ),
  (
    id: 'transporte',
    name: 'Transporte',
    colorValue: 0xFFB8842E,
    iconKey: 'directions_bus',
    preselected: true
  ),
  (
    id: 'vivienda',
    name: 'Vivienda',
    colorValue: 0xFF3B6B78,
    iconKey: 'home',
    preselected: true
  ),
  (
    id: 'cuentas',
    name: 'Cuentas y servicios',
    colorValue: 0xFF2B6B8A,
    iconKey: 'bolt',
    preselected: true
  ),
  (
    id: 'salud',
    name: 'Salud',
    colorValue: 0xFF4B7A3E,
    iconKey: 'medical_services',
    preselected: true
  ),
  (
    id: 'ocio',
    name: 'Ocio y salidas',
    colorValue: 0xFF6B3F5C,
    iconKey: 'theaters',
    preselected: true
  ),
  (
    id: 'otros',
    name: 'Otros',
    colorValue: 0xFF5C6B54,
    iconKey: 'category',
    preselected: true
  ),
  (
    id: 'suscripciones',
    name: 'Suscripciones',
    colorValue: 0xFF7A4B8A,
    iconKey: 'subscriptions',
    preselected: false
  ),
  (
    id: 'educacion',
    name: 'Educación',
    colorValue: 0xFF4B4B8A,
    iconKey: 'school',
    preselected: false
  ),
  (
    id: 'ropa',
    name: 'Ropa y cuidado personal',
    colorValue: 0xFF8A2B45,
    iconKey: 'checkroom',
    preselected: false
  ),
  (
    id: 'hogar',
    name: 'Hogar y tecnología',
    colorValue: 0xFF8A5A2B,
    iconKey: 'devices',
    preselected: false
  ),
  (
    id: 'mascotas',
    name: 'Mascotas',
    colorValue: 0xFF8A7A2B,
    iconKey: 'pets',
    preselected: false
  ),
  (
    id: 'regalos',
    name: 'Regalos y familia',
    colorValue: 0xFF8A3F6B,
    iconKey: 'card_giftcard',
    preselected: false
  ),
  (
    id: 'creditos',
    name: 'Créditos y deudas',
    colorValue: 0xFF6B4B2B,
    iconKey: 'credit_card',
    preselected: false
  ),
];

/// Accesos de una instalación nueva, en las categorías del catálogo. Los de
/// una categoría que el usuario no elija no se muestran (está archivada).
final _defaultQuickExpenseTemplatesForNewInstall = [
  QuickExpenseTemplatesCompanion.insert(
      label: 'Café', amount: 2500, categoryId: 'comida_fuera'),
  QuickExpenseTemplatesCompanion.insert(
      label: 'Colación', amount: 3500, categoryId: 'comida_fuera'),
  QuickExpenseTemplatesCompanion.insert(
      label: 'Micro/Metro', amount: 790, categoryId: 'transporte'),
  QuickExpenseTemplatesCompanion.insert(
      label: kBipTopUpLabel, amount: 5000, categoryId: 'transporte'),
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
  MonthlyAdjustments,
  PaymentMethods,
  InstallmentPlans,
  HabitualOccurrences,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openDatabaseConnection());

  @visibleForTesting
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 11;

  /// Columnas de Transactions agregadas en v10.
  List<GeneratedColumn> get _transactionColumnsV10 => [
        transactions.paymentMethodId,
        transactions.installmentPlanId,
        transactions.installmentNumber,
        transactions.fundedByGoalId,
        transactions.worthIt,
      ];

  /// Columnas de RecurringTemplates agregadas en v11 (RF47).
  List<GeneratedColumn> get _recurringColumnsV11 => [
        recurringTemplates.mode,
        recurringTemplates.weekdays,
        recurringTemplates.reminderTime,
        recurringTemplates.paymentMethodId,
        recurringTemplates.startDate,
      ];

  @override
  MigrationStrategy get migration => MigrationStrategy(
        // SQLite ignora las claves foráneas si no se activa este pragma en
        // cada conexión. Va en beforeOpen (después de onCreate / onUpgrade)
        // porque las migraciones reconstruyen tablas con `alterTable`, y eso
        // fallaría con las claves foráneas ya activas.
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
        onCreate: (m) async {
          await m.createAll();
          // Catálogo de 15 categorías; las 7 no preseleccionadas quedan
          // archivadas (RF53) y el onboarding las activa con un toque. Sin
          // presupuestos: el usuario los define o elige "Aún no sé".
          await batch((b) {
            b.insertAll(categories, [
              for (final c in kDefaultCategories)
                CategoriesCompanion.insert(
                  id: c.id,
                  name: c.name,
                  colorValue: c.colorValue,
                  iconKey: Value(c.iconKey),
                  archived: Value(!c.preselected),
                ),
            ]);
            b.insertAll(quickExpenseTemplates,
                _defaultQuickExpenseTemplatesForNewInstall);
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
            // La tabla se crea con el esquema ACTUAL: las columnas posteriores
            // a v1 van en `newColumns` para que tomen su default. Si no,
            // SQLite copia su nombre entre comillas como texto ('archived').
            // ignore: experimental_member_use
            await m.alterTable(TableMigration(categories,
                newColumns: [categories.iconKey, categories.archived]));
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
          if (from < 9) {
            // Hasta v8 las tablas se crearon sin `REFERENCES` (ver nota del
            // esquema): se reconstruyen para que tengan sus claves foráneas.
            // SQLite no permite agregarlas con ALTER TABLE.
            // ignore: experimental_member_use
            await m.alterTable(TableMigration(categoryBudgets));
            // ignore: experimental_member_use
            await m.alterTable(TableMigration(recurringTemplates,
                newColumns: _recurringColumnsV11));
            // `alterTable` crea la tabla con el esquema ACTUAL, así que
            // también trae la columna de v10; queda en null igual que allá.
            // ignore: experimental_member_use
            await m.alterTable(TableMigration(transactions, newColumns: [
              transactions.recurringTemplateId,
              ..._transactionColumnsV10,
            ]));
            // ignore: experimental_member_use
            await m.alterTable(TableMigration(quickExpenseTemplates));
            // ignore: experimental_member_use
            await m.alterTable(TableMigration(savingsContributions));
            // ignore: experimental_member_use
            await m.alterTable(TableMigration(savingsQuickAdds));
            await m.createTable(monthlyAdjustments);

            // I4: los gastos generados antes de v9 no guardaban su plantilla.
            // Se enlazan solo cuando hay una única plantilla con la misma
            // categoría y nota; si es ambiguo, quedan sin enlace.
            await customStatement('''
              UPDATE transactions SET recurring_template_id = (
                SELECT rt.id FROM recurring_templates rt
                WHERE rt.category_id = transactions.category_id
                  AND rt.note = transactions.note)
              WHERE is_recurring = 1 AND (
                SELECT COUNT(*) FROM recurring_templates rt
                WHERE rt.category_id = transactions.category_id
                  AND rt.note = transactions.note) = 1
            ''');
          }
          if (from < 10) {
            // RF31/RF32: métodos de pago; RF34: cuotas. RNF18: los gastos
            // existentes no cambian; quedan con método null ("Sin
            // especificar"), sin inventarles un efectivo que el usuario nunca
            // registró, y sin plan de cuotas.
            await m.createTable(paymentMethods);
            await m.createTable(installmentPlans);
            // Si pasamos por `from < 9`, la tabla ya se reconstruyó con la
            // columna (ver arriba). La clave foránea es de tabla, así que hay
            // que reconstruirla: `addColumn` agregaría la columna sin ella.
            if (from >= 9) {
              // ignore: experimental_member_use
              await m.alterTable(TableMigration(transactions,
                  newColumns: _transactionColumnsV10));
            }
            // RF53. Si pasamos por `from < 2`, la tabla ya se reconstruyó con
            // el esquema actual (igual que iconKey en `from < 8`).
            if (from >= 2) {
              await m.addColumn(categories, categories.archived);
            }
          }
          if (from < 11) {
            // RF47: gastos habituales. Las plantillas existentes quedan en
            // modo 'auto', como hasta ahora. Si pasamos por `from < 9`, la
            // tabla ya se reconstruyó con estas columnas; si no, se
            // reconstruye por la clave foránea del método de pago.
            if (from >= 9) {
              // ignore: experimental_member_use
              await m.alterTable(TableMigration(recurringTemplates,
                  newColumns: _recurringColumnsV11));
            }
            await m.createTable(habitualOccurrences);
          }
        },
      );

  Future<int> deleteTransaction(int id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();

  /// UX02: borra el gasto y devuelve cómo restaurarlo tal cual (mismo id).
  Future<Future<void> Function()> deleteTransactionUndoable(int id) async {
    final row =
        await (select(transactions)..where((t) => t.id.equals(id))).getSingle();
    await deleteTransaction(id);
    return () => into(transactions).insert(row.toCompanion(false));
  }

  Future<void> updateTransaction({
    required int id,
    required String categoryId,
    required int amount,
    required DateTime date,
    required String note,
    required bool isRecurring,
    required int? paymentMethodId,
  }) {
    return (update(transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        categoryId: Value(categoryId),
        amount: Value(amount),
        date: Value(date),
        note: Value(note),
        isRecurring: Value(isRecurring),
        paymentMethodId: Value(paymentMethodId),
      ),
    );
  }

  /// RF37: marca un gasto como "valió la pena" (true), "no tanto" (false) o
  /// sin revisar (null).
  Future<void> setWorthIt(int id, bool? worthIt) =>
      (update(transactions)..where((t) => t.id.equals(id)))
          .write(TransactionsCompanion(worthIt: Value(worthIt)));

  // --- Métodos de pago (RF31/RF32) -----------------------------------------

  Stream<List<PaymentMethod>> watchPaymentMethods() =>
      (select(paymentMethods)..orderBy([(p) => OrderingTerm.asc(p.id)]))
          .watch();

  Future<int> insertPaymentMethod(PaymentMethodsCompanion method) =>
      into(paymentMethods).insert(method);

  Future<void> updatePaymentMethod(int id, PaymentMethodsCompanion method) =>
      (update(paymentMethods)..where((p) => p.id.equals(id))).write(method);

  Future<int> countTransactionsForPaymentMethod(int id) =>
      _countWhere(transactions, transactions.paymentMethodId.equals(id));

  Future<int> countInstallmentPlansForPaymentMethod(int id) => _countWhere(
      installmentPlans, installmentPlans.paymentMethodId.equals(id));

  Future<int> countRecurringTemplatesForPaymentMethod(int id) => _countWhere(
      recurringTemplates, recurringTemplates.paymentMethodId.equals(id));

  /// RF31: como con las categorías, la UI solo lo permite sin gastos
  /// asociados; la clave foránea lo impide igual si se intentara.
  Future<void> deletePaymentMethod(int id) =>
      (delete(paymentMethods)..where((p) => p.id.equals(id))).go();

  // --- Cuotas (RF34/RF35/RF36) ---------------------------------------------

  Stream<List<InstallmentPlan>> watchInstallmentPlans() =>
      (select(installmentPlans)
            ..orderBy([(p) => OrderingTerm.desc(p.purchaseDate)]))
          .watch();

  /// Todos los gastos que pertenecen a un plan de cuotas (cuotas y prepagos).
  Stream<List<Transaction>> watchInstallmentTransactions() =>
      (select(transactions)..where((t) => t.installmentPlanId.isNotNull()))
          .watch();

  /// RF34: crea el plan y sus [count] cuotas de una vez, cada una en su mes.
  /// Devuelve el id del plan.
  Future<int> createInstallmentPlan({
    required int paymentMethodId,
    required String categoryId,
    required String note,
    required int totalAmount,
    required int count,
    required DateTime purchaseDate,
  }) =>
      transaction(() async {
        final planId = await into(installmentPlans).insert(
          InstallmentPlansCompanion.insert(
            paymentMethodId: paymentMethodId,
            categoryId: categoryId,
            note: Value(note),
            totalAmount: totalAmount,
            installmentCount: count,
            purchaseDate: purchaseDate,
          ),
        );
        final amounts = installmentAmounts(totalAmount, count);
        for (var k = 1; k <= count; k++) {
          await into(transactions).insert(TransactionsCompanion.insert(
            categoryId: categoryId,
            amount: amounts[k - 1],
            date: installmentDate(purchaseDate, k),
            note: Value(installmentNote(note, k, count)),
            paymentMethodId: Value(paymentMethodId),
            installmentPlanId: Value(planId),
            installmentNumber: Value(k),
          ));
        }
        return planId;
      });

  /// RF35: cambia la categoría y la nota del plan y de todas sus cuotas.
  Future<void> updateInstallmentPlanInfo(int planId,
          {required String categoryId, required String note}) =>
      transaction(() async {
        final plan = await (select(installmentPlans)
              ..where((p) => p.id.equals(planId)))
            .getSingle();
        await (update(installmentPlans)..where((p) => p.id.equals(planId)))
            .write(InstallmentPlansCompanion(
                categoryId: Value(categoryId), note: Value(note)));
        final rows = await (select(transactions)
              ..where((t) => t.installmentPlanId.equals(planId)))
            .get();
        for (final t in rows) {
          final k = t.installmentNumber;
          await (update(transactions)..where((x) => x.id.equals(t.id)))
              .write(TransactionsCompanion(
            categoryId: Value(categoryId),
            note: k == null
                ? const Value.absent()
                : Value(installmentNote(note, k, plan.installmentCount)),
          ));
        }
      });

  /// RF35: prepagar. Las cuotas ya pasadas (hasta hoy) quedan intactas; las
  /// futuras se reemplazan por un solo gasto de hoy por su suma, porque esa
  /// plata se paga ahora y debe contar en el presupuesto de este mes.
  Future<void> prepayInstallmentPlan(int planId, {DateTime? today}) =>
      transaction(() async {
        final now = today ?? DateTime.now();
        final endOfToday = DateTime(now.year, now.month, now.day + 1);
        final plan = await (select(installmentPlans)
              ..where((p) => p.id.equals(planId)))
            .getSingle();
        final future = await (select(transactions)
              ..where((t) =>
                  t.installmentPlanId.equals(planId) &
                  t.installmentNumber.isNotNull() &
                  t.date.isBiggerOrEqualValue(endOfToday))
              ..orderBy([(t) => OrderingTerm.asc(t.installmentNumber)]))
            .get();
        if (future.isNotEmpty) {
          await (delete(transactions)
                ..where((t) => t.id.isIn(future.map((t) => t.id))))
              .go();
          final first = future.first.installmentNumber!;
          final n = plan.installmentCount;
          final label = first == n
              ? 'Prepago cuota $n de $n'
              : 'Prepago cuotas $first a $n de $n';
          await into(transactions).insert(TransactionsCompanion.insert(
            categoryId: plan.categoryId,
            amount: future.fold<int>(0, (a, t) => a + t.amount),
            date: now,
            note: Value(plan.note.isEmpty ? label : '${plan.note} · $label'),
            paymentMethodId: Value(plan.paymentMethodId),
            installmentPlanId: Value(planId),
          ));
        }
        await (update(installmentPlans)..where((p) => p.id.equals(planId)))
            .write(const InstallmentPlansCompanion(prepaid: Value(true)));
      });

  /// Elimina el plan con todas sus cuotas (también las ya pagadas).
  Future<void> deleteInstallmentPlan(int planId) => transaction(() async {
        await (delete(transactions)
              ..where((t) => t.installmentPlanId.equals(planId)))
            .go();
        await (delete(installmentPlans)..where((p) => p.id.equals(planId)))
            .go();
      });

  /// RF32: método del último gasto registrado que tiene uno, para
  /// proponerlo por defecto. Null si nunca se usó uno.
  Future<int?> lastUsedPaymentMethodId() async {
    final last = await (select(transactions)
          ..where((t) => t.paymentMethodId.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(1))
        .getSingleOrNull();
    return last?.paymentMethodId;
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

  Future<int> _countWhere<T extends HasResultSet, D>(
      ResultSetImplementation<T, D> table, Expression<bool> where) async {
    final count = countAll();
    final row = await (selectOnly(table)
          ..addColumns([count])
          ..where(where))
        .getSingle();
    return row.read(count) ?? 0;
  }

  Future<int> countTransactionsForCategory(String categoryId) =>
      _countWhere(transactions, transactions.categoryId.equals(categoryId));

  Future<int> countRecurringTemplatesForCategory(String categoryId) =>
      _countWhere(
          recurringTemplates, recurringTemplates.categoryId.equals(categoryId));

  Future<int> countInstallmentPlansForCategory(String categoryId) =>
      _countWhere(
          installmentPlans, installmentPlans.categoryId.equals(categoryId));

  Future<int> countQuickExpenseTemplatesForCategory(String categoryId) =>
      _countWhere(quickExpenseTemplates,
          quickExpenseTemplates.categoryId.equals(categoryId));

  /// RF53: archiva la categoría. Su presupuesto pasa a 0 desde este mes
  /// (los meses pasados no cambian), para que no siga asignado en una
  /// categoría que ya no se muestra. Devuelve cómo deshacerlo por completo.
  Future<Future<void> Function()> archiveCategory(String id,
          {DateTime? today}) =>
      transaction(() async {
        final now = today ?? DateTime.now();
        Expression<bool> thisMonth(CategoryBudgets b) =>
            b.categoryId.equals(id) &
            b.year.equals(now.year) &
            b.month.equals(now.month);
        final previous =
            await (select(categoryBudgets)..where(thisMonth)).getSingleOrNull();
        final hasBudget = await _countWhere(
                categoryBudgets, categoryBudgets.categoryId.equals(id)) >
            0;
        await _setCategoryArchived(id, true);
        if (hasBudget) await setBudgetForMonth(id, now, 0);
        return () => transaction(() async {
              await _setCategoryArchived(id, false);
              if (!hasBudget) return;
              if (previous != null) {
                await into(categoryBudgets)
                    .insertOnConflictUpdate(previous.toCompanion(false));
              } else {
                await (delete(categoryBudgets)..where(thisMonth)).go();
              }
            });
      });

  /// Onboarding: deja activas solo las categorías [activeIds]; las demás
  /// quedan archivadas (RF53) y se pueden activar después.
  Future<void> setActiveCategories(Set<String> activeIds) =>
      transaction(() async {
        await update(categories)
            .write(const CategoriesCompanion(archived: Value(true)));
        await (update(categories)..where((c) => c.id.isIn(activeIds)))
            .write(const CategoriesCompanion(archived: Value(false)));
      });

  /// RF53: restaura una categoría archivada. Su presupuesto queda en 0
  /// hasta que el usuario le asigne uno.
  Future<void> unarchiveCategory(String id) => _setCategoryArchived(id, false);

  Future<void> _setCategoryArchived(String id, bool archived) =>
      (update(categories)..where((c) => c.id.equals(id)))
          .write(CategoriesCompanion(archived: Value(archived)));

  /// RF54: fusiona [fromId] en [intoId]. Gastos, recurrentes, accesos
  /// rápidos, planes en cuotas y ajustes de un mes pasan a la categoría
  /// destino, y la original se elimina. Los presupuestos se suman mes a
  /// mes, así ningún mes pierde lo que tenía asignado. Devuelve cuántos
  /// gastos se movieron.
  Future<int> mergeCategory(String fromId, String intoId) =>
      transaction(() async {
        if (fromId == intoId) {
          throw ArgumentError('No se puede fusionar una categoría en sí misma');
        }
        final moved = await (update(transactions)
              ..where((t) => t.categoryId.equals(fromId)))
            .write(TransactionsCompanion(categoryId: Value(intoId)));
        await (update(recurringTemplates)
              ..where((t) => t.categoryId.equals(fromId)))
            .write(RecurringTemplatesCompanion(categoryId: Value(intoId)));
        await (update(quickExpenseTemplates)
              ..where((t) => t.categoryId.equals(fromId)))
            .write(QuickExpenseTemplatesCompanion(categoryId: Value(intoId)));
        await (update(installmentPlans)
              ..where((p) => p.categoryId.equals(fromId)))
            .write(InstallmentPlansCompanion(categoryId: Value(intoId)));
        await (update(monthlyAdjustments)
              ..where((a) => a.categoryId.equals(fromId)))
            .write(MonthlyAdjustmentsCompanion(categoryId: Value(intoId)));

        // El presupuesto vigente es escalonado (cada fila vale hasta la
        // siguiente), así que basta escribir la suma en cada mes donde
        // cambia alguno de los dos.
        final rows = await (select(categoryBudgets)
              ..where((b) => b.categoryId.isIn([fromId, intoId])))
            .get();
        int resolve(String id, int ym) {
          CategoryBudget? latest;
          for (final b in rows) {
            final bym = b.year * 100 + b.month;
            if (b.categoryId != id || bym > ym) continue;
            if (latest == null || latest.year * 100 + latest.month < bym) {
              latest = b;
            }
          }
          return latest?.amount ?? 0;
        }

        final months = {for (final b in rows) b.year * 100 + b.month};
        for (final ym in months) {
          await setBudgetForMonth(intoId, DateTime(ym ~/ 100, ym % 100),
              resolve(intoId, ym) + resolve(fromId, ym));
        }
        await (delete(categoryBudgets)
              ..where((b) => b.categoryId.equals(fromId)))
            .go();
        await (delete(categories)..where((c) => c.id.equals(fromId))).go();
        return moved;
      });

  Future<void> deleteCategory(String id) => transaction(() async {
        await (delete(categoryBudgets)..where((b) => b.categoryId.equals(id)))
            .go();
        // Un ajuste de un mes era plata extra para ese mes: al borrar la
        // categoría pasa al total, para que ese mes no pierda presupuesto.
        await (update(monthlyAdjustments)
              ..where((a) => a.categoryId.equals(id)))
            .write(const MonthlyAdjustmentsCompanion(categoryId: Value(null)));
        await (delete(categories)..where((c) => c.id.equals(id))).go();
      });

  // --- Ajustes de un solo mes (RF50) ---------------------------------------

  Stream<List<MonthlyAdjustment>> watchAllAdjustments() =>
      select(monthlyAdjustments).watch();

  Future<int> insertAdjustment({
    required DateTime month,
    String? categoryId,
    required int amount,
    required String reason,
  }) =>
      into(monthlyAdjustments).insert(MonthlyAdjustmentsCompanion.insert(
        year: month.year,
        month: month.month,
        categoryId: Value(categoryId),
        amount: amount,
        reason: Value(reason),
      ));

  Future<int> deleteAdjustment(int id) =>
      (delete(monthlyAdjustments)..where((a) => a.id.equals(id))).go();

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

  Future<Transaction?> transactionById(int id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Gastos desde [from] (incluido).
  Future<List<Transaction>> transactionsSince(DateTime from) =>
      (select(transactions)..where((t) => t.date.isBiggerOrEqualValue(from)))
          .get();

  /// UX06: todos los gastos, del más reciente.
  Stream<List<Transaction>> watchAllTransactions() => (select(transactions)
        ..orderBy([
          (t) => OrderingTerm.desc(t.date),
          (t) => OrderingTerm.desc(t.id),
        ]))
      .watch();

  Stream<List<Transaction>> watchTransactionsForMonth(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return (select(transactions)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end)))
        .watch();
  }

  Stream<List<RecurringTemplate>> watchRecurringTemplates() =>
      select(recurringTemplates).watch();

  Future<int> insertRecurringTemplate({
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
  /// mes, activo/pausado). Solo toca `lastGeneratedYearMonth` al reactivar un
  /// pausado (ver abajo) — si el usuario sube el monto a mitad de mes, no
  /// vuelve a generar la ocurrencia ya hecha, solo cambia el de las futuras.
  Future<void> updateRecurringTemplate(
    int id, {
    required String categoryId,
    required int amount,
    required String note,
    required int dayOfMonth,
    required bool active,
    DateTime? today,
  }) async {
    final existing = await (select(recurringTemplates)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (existing == null) return;
    // Al reactivar un recurrente pausado, el mes en curso se da por cubierto:
    // si no, el próximo catch-up generaría de golpe el gasto de este mes
    // aunque el usuario lo haya pausado justamente para que no ocurra.
    final now = today ?? DateTime.now();
    final reactivated = !existing.active && active;
    final lastGenerated = reactivated
        ? (existing.lastGeneratedYearMonth > now.year * 100 + now.month
            ? existing.lastGeneratedYearMonth
            : now.year * 100 + now.month)
        : existing.lastGeneratedYearMonth;
    await (update(recurringTemplates)..where((t) => t.id.equals(id))).write(
      RecurringTemplatesCompanion(
        categoryId: Value(categoryId),
        amount: Value(amount),
        note: Value(note),
        dayOfMonth: Value(dayOfMonth),
        active: Value(active),
        lastGeneratedYearMonth: Value(lastGenerated),
      ),
    );
  }

  Future<void> deleteRecurringTemplate(int id) =>
      (delete(recurringTemplates)..where((t) => t.id.equals(id))).go();

  /// UX02: borra la plantilla y devuelve cómo restaurarla. Al borrarla, sus
  /// gastos quedan sin enlace (ON DELETE SET NULL); restaurar los re-enlaza.
  Future<Future<void> Function()> deleteRecurringTemplateUndoable(int id) =>
      transaction(() async {
        final row = await (select(recurringTemplates)
              ..where((t) => t.id.equals(id)))
            .getSingle();
        final linkedIds = await (selectOnly(transactions)
              ..addColumns([transactions.id])
              ..where(transactions.recurringTemplateId.equals(id)))
            .map((r) => r.read(transactions.id)!)
            .get();
        // RF49: las decisiones de un gasto habitual se borran en cascada.
        final occurrences = await (select(habitualOccurrences)
              ..where((o) => o.templateId.equals(id)))
            .get();
        await deleteRecurringTemplate(id);
        return () => transaction(() async {
              await into(recurringTemplates).insert(row.toCompanion(false));
              await (update(transactions)..where((t) => t.id.isIn(linkedIds)))
                  .write(TransactionsCompanion(recurringTemplateId: Value(id)));
              for (final o in occurrences) {
                // El gasto pudo borrarse mientras tanto (queda sin enlace).
                final txExists = o.transactionId != null &&
                    await (select(transactions)
                              ..where((t) => t.id.equals(o.transactionId!)))
                            .getSingleOrNull() !=
                        null;
                await into(habitualOccurrences).insert(o
                    .copyWith(
                        transactionId: Value(txExists ? o.transactionId : null))
                    .toCompanion(false));
              }
            });
      });

  int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  /// RF12: revisa las plantillas activas al abrir la app y genera SOLO la
  /// ocurrencia del mes actual si todavía falta y ya pasó `dayOfMonth`. Sin
  /// backfill de meses saltados — evita gastos "fantasma" si el usuario
  /// estuvo mucho tiempo sin abrir la app. Devuelve las transacciones
  /// generadas (para el aviso de RF20).
  Future<List<Transaction>> runRecurringCatchUp({DateTime? today}) async {
    final now = today ?? DateTime.now();
    final currentYm = now.year * 100 + now.month;
    // Los gastos habituales (RF47) no se registran solos.
    final templates = await (select(recurringTemplates)
          ..where((t) => t.active.equals(true) & t.mode.equals('auto')))
        .get();

    final generated = <Transaction>[];
    for (final tpl in templates) {
      if (tpl.lastGeneratedYearMonth >= currentYm) continue;
      // Se compara contra el día ya recortado al largo del mes: un recurrente
      // del 31 debe generarse el 30 de abril, no quedar sin generar nunca.
      final day = tpl.dayOfMonth.clamp(1, _daysInMonth(now.year, now.month));
      if (now.day < day) continue;
      final date = DateTime(now.year, now.month, day);
      // Gasto y marca del mes en una sola transacción: si la app se cierra
      // entre ambas escrituras, el próximo arranque generaría el gasto otra vez.
      final id = await transaction(() async {
        final id = await into(transactions).insert(
          TransactionsCompanion.insert(
            categoryId: tpl.categoryId,
            amount: tpl.amount,
            date: date,
            note: Value(tpl.note),
            isRecurring: const Value(true),
            recurringTemplateId: Value(tpl.id),
          ),
        );
        await (update(recurringTemplates)..where((t) => t.id.equals(tpl.id)))
            .write(RecurringTemplatesCompanion(
                lastGeneratedYearMonth: Value(currentYm)));
        return id;
      });
      generated.add(await (select(transactions)..where((t) => t.id.equals(id)))
          .getSingle());
    }
    return generated;
  }

  // --- Gastos habituales (RF47/RF48/RF49) ---------------------------------

  /// RF47: crea un gasto habitual. [startDate] es desde cuándo cuentan los
  /// pendientes (RF49): los días anteriores a crearlo no se piden.
  Future<int> insertHabitualTemplate({
    required String categoryId,
    required int amount,
    required String note,
    required int weekdays,
    required String reminderTime,
    required int? paymentMethodId,
    required DateTime startDate,
  }) =>
      into(recurringTemplates).insert(RecurringTemplatesCompanion.insert(
        categoryId: categoryId,
        amount: amount,
        note: Value(note),
        dayOfMonth: 0,
        lastGeneratedYearMonth: 0,
        mode: const Value('confirm'),
        weekdays: Value(weekdays),
        reminderTime: Value(reminderTime),
        paymentMethodId: Value(paymentMethodId),
        startDate: Value(startDate),
      ));

  /// RF47: editar, pausar o reactivar un gasto habitual. Al reactivarlo, los
  /// pendientes vuelven a contar desde [today]: los días en pausa no se piden.
  Future<void> updateHabitualTemplate(
    int id, {
    required String categoryId,
    required int amount,
    required String note,
    required int weekdays,
    required String reminderTime,
    required int? paymentMethodId,
    required bool active,
    required DateTime today,
  }) async {
    final existing = await (select(recurringTemplates)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (existing == null) return;
    final reactivated = !existing.active && active;
    await (update(recurringTemplates)..where((t) => t.id.equals(id))).write(
      RecurringTemplatesCompanion(
        categoryId: Value(categoryId),
        amount: Value(amount),
        note: Value(note),
        weekdays: Value(weekdays),
        reminderTime: Value(reminderTime),
        paymentMethodId: Value(paymentMethodId),
        active: Value(active),
        startDate: reactivated
            ? Value(DateTime(today.year, today.month, today.day))
            : const Value.absent(),
      ),
    );
  }

  Stream<List<HabitualOccurrence>> watchHabitualOccurrencesSince(
          DateTime since) =>
      (select(habitualOccurrences)
            ..where((o) => o.date.isBiggerOrEqualValue(since)))
          .watch();

  /// RF48/RF49: registra el gasto habitual de [day] (fecha sin hora) con
  /// fecha [date]. Gasto y decisión van juntos en una transacción. Devuelve
  /// el id del gasto, o null si ese día ya estaba decidido (p. ej. se
  /// respondió la notificación y además la tarjeta de Resumen).
  Future<int?> registerHabitual({
    required int templateId,
    required DateTime day,
    required DateTime date,
  }) =>
      transaction(() async {
        final template = await (select(recurringTemplates)
              ..where((t) => t.id.equals(templateId)))
            .getSingleOrNull();
        if (template == null || await _habitualDecided(templateId, day)) {
          return null;
        }
        final txId = await into(transactions).insert(
          TransactionsCompanion.insert(
            categoryId: template.categoryId,
            amount: template.amount,
            date: date,
            note: Value(template.note),
            paymentMethodId: Value(template.paymentMethodId),
          ),
        );
        await into(habitualOccurrences).insert(
          HabitualOccurrencesCompanion.insert(
            templateId: templateId,
            date: day,
            status: 'registered',
            transactionId: Value(txId),
          ),
        );
        return txId;
      });

  /// RF48/RF49: "Hoy no". No hace nada si ese día ya estaba decidido.
  Future<void> skipHabitual({required int templateId, required DateTime day}) =>
      into(habitualOccurrences).insert(
        HabitualOccurrencesCompanion.insert(
            templateId: templateId, date: day, status: 'skipped'),
        mode: InsertMode.insertOrIgnore,
      );

  /// Deshace un registro o un "Hoy no": el día vuelve a quedar pendiente y,
  /// si se había registrado, se borra el gasto.
  Future<void> undoHabitualDecision(
          {required int templateId, required DateTime day}) =>
      transaction(() async {
        final row = await (select(habitualOccurrences)
              ..where(
                  (o) => o.templateId.equals(templateId) & o.date.equals(day)))
            .getSingleOrNull();
        if (row == null) return;
        await (delete(habitualOccurrences)
              ..where(
                  (o) => o.templateId.equals(templateId) & o.date.equals(day)))
            .go();
        if (row.transactionId != null) {
          await deleteTransaction(row.transactionId!);
        }
      });

  Future<bool> _habitualDecided(int templateId, DateTime day) async =>
      await (select(habitualOccurrences)
            ..where(
                (o) => o.templateId.equals(templateId) & o.date.equals(day)))
          .getSingleOrNull() !=
      null;

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

  /// Los gastos pagados con su ahorro (RF52) se conservan, pero sin meta:
  /// desde ahí cuentan en el presupuesto de su mes.
  Future<void> deleteSavingsGoal(int id) => transaction(() async {
        await (update(transactions)..where((t) => t.fundedByGoalId.equals(id)))
            .write(const TransactionsCompanion(fundedByGoalId: Value(null)));
        await (delete(savingsContributions)..where((c) => c.goalId.equals(id)))
            .go();
        await (delete(savingsQuickAdds)..where((q) => q.goalId.equals(id)))
            .go();
        await (delete(savingsGoals)..where((g) => g.id.equals(id))).go();
      });

  /// Saldo por meta (aportes menos lo usado en gastos, RF52), reactivo: la
  /// barra de progreso se recalcula sola con cada aporte o uso.
  Stream<Map<int, int>> watchGoalBalances() {
    return customSelect(
      'SELECT g.id AS id, '
      'COALESCE((SELECT SUM(c.amount) FROM savings_contributions c '
      'WHERE c.goal_id = g.id), 0) - '
      'COALESCE((SELECT SUM(t.amount) FROM transactions t '
      'WHERE t.funded_by_goal_id = g.id), 0) AS balance '
      'FROM savings_goals g',
      readsFrom: {savingsGoals, savingsContributions, transactions},
    ).watch().map((rows) => {
          for (final r in rows) r.read<int>('id'): r.read<int>('balance'),
        });
  }

  /// RF52: gastos pagados con el ahorro de [goalId], del más reciente.
  Stream<List<Transaction>> watchGoalSpending(int goalId) =>
      (select(transactions)
            ..where((t) => t.fundedByGoalId.equals(goalId))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .watch();

  /// RF52: registra un gasto pagado con el ahorro de [goalId]. Falla si el
  /// monto supera el saldo de la meta. Devuelve el id del gasto.
  Future<int> spendFromGoal({
    required int goalId,
    required String categoryId,
    required int amount,
    required DateTime date,
    String note = '',
  }) =>
      transaction(() async {
        final balance = (await watchGoalBalances().first)[goalId] ?? 0;
        if (amount <= 0 || amount > balance) {
          throw StateError('El monto supera el saldo de la meta');
        }
        return into(transactions).insert(TransactionsCompanion.insert(
          categoryId: categoryId,
          amount: amount,
          date: date,
          note: Value(note),
          fundedByGoalId: Value(goalId),
        ));
      });

  Stream<List<SavingsContribution>> watchContributionsForGoal(int goalId) {
    return (select(savingsContributions)
          ..where((c) => c.goalId.equals(goalId))
          ..orderBy([(c) => OrderingTerm.desc(c.date)]))
        .watch();
  }

  /// RF51 (corrige I2): total aportado a metas en el mes de [month]. Ese
  /// dinero sale del presupuesto del mes aunque no sea gasto de categoría.
  Stream<int> watchContributedInMonth(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final total = savingsContributions.amount.sum();
    return (selectOnly(savingsContributions)
          ..addColumns([total])
          ..where(savingsContributions.date.isBiggerOrEqualValue(start) &
              savingsContributions.date.isSmallerThanValue(end)))
        .map((row) => row.read(total) ?? 0)
        .watchSingle();
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

  /// UX02: borra el aporte y devuelve cómo restaurarlo tal cual (mismo id).
  Future<Future<void> Function()> deleteContributionUndoable(int id) async {
    final row = await (select(savingsContributions)
          ..where((c) => c.id.equals(id)))
        .getSingle();
    await deleteContribution(id);
    return () => into(savingsContributions).insert(row.toCompanion(false));
  }

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

  Stream<String?> watchSetting(String key) =>
      (select(appSettings)..where((s) => s.key.equals(key)))
          .map((row) => row.value)
          .watchSingleOrNull();

  Future<void> setSetting(String key, String value) {
    return into(appSettings).insertOnConflictUpdate(
        AppSettingsCompanion.insert(key: key, value: value));
  }

  // --- Respaldo local (RF16/RF17/RNF09) -------------------------------------

  /// Vuelca todas las tablas a JSON, listo para escribir a un archivo local.
  Future<Map<String, dynamic>> exportAllData() async {
    return {
      'version': kBackupFormatVersion,
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
      'monthlyAdjustments': (await select(monthlyAdjustments).get())
          .map((r) => r.toJson())
          .toList(),
      'paymentMethods':
          (await select(paymentMethods).get()).map((r) => r.toJson()).toList(),
      'installmentPlans': (await select(installmentPlans).get())
          .map((r) => r.toJson())
          .toList(),
      'habitualOccurrences': (await select(habitualOccurrences).get())
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
      // Hijos antes que padres: con claves foráneas activas, borrar una
      // fila referenciada falla.
      await delete(savingsQuickAdds).go();
      await delete(savingsContributions).go();
      await delete(habitualOccurrences).go();
      await delete(transactions).go();
      await delete(savingsGoals).go();
      await delete(installmentPlans).go();
      // Antes que los métodos de pago: un gasto habitual (RF47) apunta a uno.
      await delete(recurringTemplates).go();
      await delete(paymentMethods).go();
      await delete(quickExpenseTemplates).go();
      await delete(monthlyAdjustments).go();
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
        row.putIfAbsent('archived', () => false); // anteriores a RF53
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
      // `?? []`: respaldos anteriores a v9 no traen ajustes de un mes.
      for (final row in (data['monthlyAdjustments'] as List? ?? [])
          .cast<Map<String, dynamic>>()) {
        await into(monthlyAdjustments).insertOnConflictUpdate(
            MonthlyAdjustment.fromJson(row).toCompanion(false));
      }
      // `?? []`: respaldos v1 no traen métodos de pago (RNF19); sus gastos
      // tampoco traen `paymentMethodId` y quedan como "Sin especificar".
      for (final row in (data['paymentMethods'] as List? ?? [])
          .cast<Map<String, dynamic>>()) {
        await into(paymentMethods).insertOnConflictUpdate(
            PaymentMethod.fromJson(row).toCompanion(false));
      }
      for (final row in (data['installmentPlans'] as List? ?? [])
          .cast<Map<String, dynamic>>()) {
        await into(installmentPlans).insertOnConflictUpdate(
            InstallmentPlan.fromJson(row).toCompanion(false));
      }
      for (final row
          in (data['savingsGoals'] as List).cast<Map<String, dynamic>>()) {
        await into(savingsGoals).insertOnConflictUpdate(
            SavingsGoal.fromJson(row).toCompanion(false));
      }
      // Plantillas, métodos, planes y metas antes que gastos: un gasto apunta
      // a ellos.
      for (final row in (data['recurringTemplates'] as List)
          .cast<Map<String, dynamic>>()) {
        row.putIfAbsent('mode', () => 'auto'); // anteriores a RF47
        await into(recurringTemplates).insertOnConflictUpdate(
            RecurringTemplate.fromJson(row).toCompanion(false));
      }
      for (final row
          in (data['transactions'] as List).cast<Map<String, dynamic>>()) {
        await into(transactions).insertOnConflictUpdate(
            Transaction.fromJson(row).toCompanion(false));
      }
      // `?? []`: respaldos anteriores a RF47 no traen gastos habituales.
      for (final row in (data['habitualOccurrences'] as List? ?? [])
          .cast<Map<String, dynamic>>()) {
        await into(habitualOccurrences).insertOnConflictUpdate(
            HabitualOccurrence.fromJson(row).toCompanion(false));
      }
      // `?? []`: respaldos hechos antes de agregar esta tabla no traen la
      // clave — restaurarlos no debe fallar, solo dejar los accesos rápidos
      // vacíos (el usuario los vuelve a crear).
      for (final row in (data['quickExpenseTemplates'] as List? ?? [])
          .cast<Map<String, dynamic>>()) {
        await into(quickExpenseTemplates).insertOnConflictUpdate(
            QuickExpenseTemplate.fromJson(row).toCompanion(false));
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
