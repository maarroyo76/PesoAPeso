import '../../core/utils/habitual.dart';
import '../local/app_database.dart';

class RecurringTemplatesRepository {
  RecurringTemplatesRepository(this._db);
  final AppDatabase _db;

  Stream<List<RecurringTemplate>> watchTemplates() =>
      _db.watchRecurringTemplates();

  Future<int> createTemplate({
    required String categoryId,
    required int amount,
    required String note,
    required int dayOfMonth,
    required int initialYearMonth,
  }) {
    return _db.insertRecurringTemplate(
      categoryId: categoryId,
      amount: amount,
      note: note,
      dayOfMonth: dayOfMonth,
      initialYearMonth: initialYearMonth,
    );
  }

  Future<List<Transaction>> runCatchUp() => _db.runRecurringCatchUp();

  Future<List<RecurringTemplate>> getAll() =>
      _db.select(_db.recurringTemplates).get();

  /// RF25: editar/eliminar un recurrente ya creado.
  Future<void> updateTemplate(
    int id, {
    required String categoryId,
    required int amount,
    required String note,
    required int dayOfMonth,
    required bool active,
  }) {
    return _db.updateRecurringTemplate(
      id,
      categoryId: categoryId,
      amount: amount,
      note: note,
      dayOfMonth: dayOfMonth,
      active: active,
    );
  }

  Future<void> deleteTemplate(int id) => _db.deleteRecurringTemplate(id);

  // --- Gastos habituales (RF47/RF48/RF49) ---------------------------------

  Future<int> createHabitual({
    required String categoryId,
    required int amount,
    required String note,
    required int weekdays,
    required String reminderTime,
    required int? paymentMethodId,
    DateTime? today,
  }) {
    final now = today ?? DateTime.now();
    return _db.insertHabitualTemplate(
      categoryId: categoryId,
      amount: amount,
      note: note,
      weekdays: weekdays,
      reminderTime: reminderTime,
      paymentMethodId: paymentMethodId,
      startDate: DateTime(now.year, now.month, now.day),
    );
  }

  Future<void> updateHabitual(
    int id, {
    required String categoryId,
    required int amount,
    required String note,
    required int weekdays,
    required String reminderTime,
    required int? paymentMethodId,
    required bool active,
    DateTime? today,
  }) =>
      _db.updateHabitualTemplate(
        id,
        categoryId: categoryId,
        amount: amount,
        note: note,
        weekdays: weekdays,
        reminderTime: reminderTime,
        paymentMethodId: paymentMethodId,
        active: active,
        today: today ?? DateTime.now(),
      );

  /// Decisiones de la última semana más un día de margen (RF49).
  Stream<List<HabitualOccurrence>> watchRecentOccurrences(DateTime now) =>
      _db.watchHabitualOccurrencesSince(
          DateTime(now.year, now.month, now.day - kHabitualPendingDays - 1));

  /// Registra el gasto de [day]. Devuelve su id, o null si ya estaba decidido.
  Future<int?> registerHabitual(RecurringTemplate template, DateTime day) =>
      _db.registerHabitual(
        templateId: template.id,
        day: dateOnly(day),
        date: habitualTransactionDate(template, day),
      );

  Future<void> skipHabitual(int templateId, DateTime day) =>
      _db.skipHabitual(templateId: templateId, day: dateOnly(day));

  Future<void> undoHabitualDecision(int templateId, DateTime day) =>
      _db.undoHabitualDecision(templateId: templateId, day: dateOnly(day));

  /// UX02: borra y devuelve cómo deshacerlo.
  Future<Future<void> Function()> deleteTemplateUndoable(int id) =>
      _db.deleteRecurringTemplateUndoable(id);
}
