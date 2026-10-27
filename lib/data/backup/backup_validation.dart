/// Versión del formato que escribe `exportAllData`. Subirla al cambiar el
/// formato de forma incompatible; un respaldo con versión mayor la rechaza.
///
/// v2 (RNF19): agrega `paymentMethods` y `transactions.paymentMethodId`.
/// Los respaldos v1 se siguen aceptando: sus gastos quedan sin método.
const kBackupFormatVersion = 2;

/// Tamaño máximo aceptado para un archivo de respaldo (un respaldo real pesa
/// unos pocos MB incluso con años de gastos).
const kMaxBackupBytes = 20 * 1024 * 1024;

/// Mensajes pensados para mostrarse tal cual al usuario (sin jerga de tablas
/// ni tipos). Todos los errores de importación llegan como [FormatException]
/// con uno de estos textos.
const kBackupNotARespaldoMessage =
    'Este archivo no parece ser un respaldo de Peso a Peso. Elige el archivo '
    '.json que exportaste desde la app (Respaldo → Exportar respaldo).';
const kBackupCorruptMessage =
    'El respaldo está incompleto o dañado, así que no se puede usar. Prueba '
    'con otro archivo de respaldo.';
const kBackupUnreadableMessage =
    'No pudimos leer el archivo. Asegúrate de elegir un respaldo .json '
    'exportado desde Peso a Peso y que no esté vacío.';
const kBackupTooLargeMessage =
    'El archivo es demasiado grande para ser un respaldo de Peso a Peso.';

/// Valida la estructura de un respaldo ANTES de tocar la base (restaurar
/// borra todo primero). Lanza [FormatException] con un mensaje apto para
/// mostrar al usuario.
void validateBackupData(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException(kBackupNotARespaldoMessage);
  }

  final version = decoded['version'];
  if (version is! int || decoded['categories'] is! List) {
    throw const FormatException(kBackupNotARespaldoMessage);
  }
  if (version > kBackupFormatVersion) {
    throw const FormatException(
        'Este respaldo fue creado con una versión más nueva de Peso a Peso. '
        'Actualiza la app para poder restaurarlo.');
  }

  // Tablas obligatorias en todo respaldo; el resto puede faltar en respaldos
  // antiguos (restoreAllData las trata como vacías).
  const required = [
    'categories',
    'categoryBudgets',
    'transactions',
    'recurringTemplates',
    'savingsGoals',
    'savingsContributions',
    'savingsQuickAdds',
  ];
  const optional = [
    'monthlyBudgets',
    'quickExpenseTemplates',
    'monthlyAdjustments',
    'paymentMethods',
    'appSettings',
  ];

  List<Map<String, dynamic>> rows(String key, {required bool mustExist}) {
    final value = decoded[key];
    if (value == null && !mustExist) return const [];
    if (value is! List || value.any((r) => r is! Map<String, dynamic>)) {
      throw const FormatException(kBackupCorruptMessage);
    }
    return value.cast<Map<String, dynamic>>();
  }

  for (final key in required) {
    rows(key, mustExist: true);
  }
  for (final key in optional) {
    rows(key, mustExist: false);
  }

  // Integridad referencial: restaurar con huérfanos dejaría pantallas rotas.
  final categoryIds = {
    for (final r in rows('categories', mustExist: true)) r['id']
  };
  final goalIds = {
    for (final r in rows('savingsGoals', mustExist: true)) r['id']
  };

  final templateIds = {
    for (final r in rows('recurringTemplates', mustExist: true)) r['id']
  };
  final paymentMethodIds = {
    for (final r in rows('paymentMethods', mustExist: false)) r['id']
  };

  void checkRefs(String table, String column, Set<Object?> valid,
      {bool nullable = false}) {
    // Un gasto, presupuesto, etc. que apunta a algo que no está en el archivo.
    for (final r in rows(table, mustExist: false)) {
      if (nullable && r[column] == null) continue;
      if (!valid.contains(r[column])) {
        throw const FormatException(kBackupCorruptMessage);
      }
    }
  }

  checkRefs('categoryBudgets', 'categoryId', categoryIds);
  checkRefs('transactions', 'categoryId', categoryIds);
  checkRefs('recurringTemplates', 'categoryId', categoryIds);
  checkRefs('quickExpenseTemplates', 'categoryId', categoryIds);
  checkRefs('savingsContributions', 'goalId', goalIds);
  checkRefs('savingsQuickAdds', 'goalId', goalIds);
  checkRefs('transactions', 'recurringTemplateId', templateIds, nullable: true);
  checkRefs('monthlyAdjustments', 'categoryId', categoryIds, nullable: true);
  checkRefs('transactions', 'paymentMethodId', paymentMethodIds,
      nullable: true);
}
