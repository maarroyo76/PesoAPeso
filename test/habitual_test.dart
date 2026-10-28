// RF47-RF49: gastos habituales. Días programados que piden confirmación,
// registro y "Hoy no" (también desde la notificación), pendientes de la
// última semana, migración v10 -> v11 y respaldo.

import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_a_peso/core/notifications/habitual_reminders.dart';
import 'package:peso_a_peso/core/utils/habitual.dart';
import 'package:peso_a_peso/data/backup/backup_validation.dart';
import 'package:peso_a_peso/data/local/app_database.dart';
import 'package:peso_a_peso/data/repositories/recurring_templates_repository.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// Lunes 20 de octubre de 2025, para fijar los días de la semana.
final _monday = DateTime(2025, 10, 20);

RecurringTemplate _template({
  int id = 1,
  int weekdays = 0x1F,
  String reminderTime = '08:00',
  bool active = true,
  DateTime? startDate,
}) =>
    RecurringTemplate(
      id: id,
      categoryId: 'transporte',
      amount: 1640,
      note: 'Micro/Metro',
      dayOfMonth: 0,
      active: active,
      lastGeneratedYearMonth: 0,
      mode: kRecurringModeConfirm,
      weekdays: weekdays,
      reminderTime: reminderTime,
      startDate: startDate ?? DateTime(2025, 1, 1),
    );

NotificationResponse _response(String action, int templateId) =>
    NotificationResponse(
      notificationResponseType:
          NotificationResponseType.selectedNotificationAction,
      actionId: action,
      payload: 'habitual:$templateId',
    );

void main() {
  setUpAll(() {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
  });

  group('días y pendientes', () {
    test('máscara de días: lunes = 1 … domingo = 64', () {
      expect(weekdayBit(DateTime.monday), 1);
      expect(weekdayBit(DateTime.sunday), 64);
      expect(includesWeekday(0x1F, DateTime.friday), isTrue);
      expect(includesWeekday(0x1F, DateTime.saturday), isFalse);
      expect(describeWeekdays(0x1F), 'lun a vie');
      expect(describeWeekdays(0x7F), 'Todos los días');
      expect(describeWeekdays(1 | 4 | 16), 'lun, mié, vie');
    });

    test('hora del recordatorio', () {
      expect(parseReminderTime('08:30'), (hour: 8, minute: 30));
      expect(parseReminderTime('24:00'), isNull);
      expect(parseReminderTime('8:30'), isNull);
      expect(formatReminderTime(7, 5), '07:05');
    });

    test('hoy cuenta solo desde la hora del recordatorio', () {
      final t = _template();
      final before = DateTime(2025, 10, 20, 7, 59);
      final after = DateTime(2025, 10, 20, 8, 0);
      expect(
          pendingHabituals(templates: [t], occurrences: [], now: before)
              .map((p) => p.day),
          isNot(contains(_monday)));
      expect(
          pendingHabituals(templates: [t], occurrences: [], now: after)
              .map((p) => p.day),
          contains(_monday));
    });

    test('solo los días programados de la última semana, sin decididos', () {
      // Domingo 26: la semana de lunes 20 a viernes 24 está programada.
      final now = DateTime(2025, 10, 26, 20);
      final t = _template();
      final occurrences = [
        HabitualOccurrence(
            templateId: 1,
            date: DateTime(2025, 10, 21),
            status: kHabitualRegistered),
        HabitualOccurrence(
            templateId: 1,
            date: DateTime(2025, 10, 22),
            status: kHabitualSkipped),
      ];
      final days =
          pendingHabituals(templates: [t], occurrences: occurrences, now: now)
              .map((p) => p.day.day)
              .toList();
      // Viernes 17 y anteriores ya se descartaron solos (más de 7 días).
      expect(days, [20, 23, 24]);
    });

    test('nada antes de crearlo, pausado ni en modo automático', () {
      final now = DateTime(2025, 10, 24, 20);
      expect(
          pendingHabituals(
                  templates: [_template(startDate: DateTime(2025, 10, 23))],
                  occurrences: [],
                  now: now)
              .map((p) => p.day.day),
          [23, 24]);
      expect(
          pendingHabituals(
              templates: [_template(active: false)], occurrences: [], now: now),
          isEmpty);
      expect(
          pendingHabituals(
              templates: [_template().copyWith(mode: kRecurringModeAuto)],
              occurrences: [],
              now: now),
          isEmpty);
    });

    test('responder tarde anota el día del recordatorio, no el de hoy', () {
      // Sábado 1:00: el último recordatorio que sonó fue el del viernes.
      expect(lastDueDay(_template(), DateTime(2025, 10, 25, 1)),
          DateTime(2025, 10, 24));
      // Lunes antes de las 8: todavía corresponde el viernes.
      expect(lastDueDay(_template(), DateTime(2025, 10, 27, 7)),
          DateTime(2025, 10, 24));
    });
  });

  group('base de datos', () {
    late Directory dir;
    late AppDatabase db;
    late RecurringTemplatesRepository repo;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('habitual');
      db = AppDatabase.forTesting(NativeDatabase(File('${dir.path}/test.db')));
      repo = RecurringTemplatesRepository(db);
      await db.insertCategory(
          id: 'transporte_test',
          name: 'Transporte Test',
          colorValue: 0xFF3B6B78,
          iconKey: 'directions_car');
    });

    tearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });

    Future<RecurringTemplate> createHabitual() async {
      final id = await repo.createHabitual(
        categoryId: 'transporte_test',
        amount: 1640,
        note: 'Micro/Metro',
        weekdays: 0x1F,
        reminderTime: '08:15',
        paymentMethodId: null,
        today: DateTime(2025, 10, 1),
      );
      return (await repo.getAll()).singleWhere((t) => t.id == id);
    }

    test('registrar crea un gasto con la hora del recordatorio, una vez',
        () async {
      final t = await createHabitual();
      final txId = await repo.registerHabitual(t, _monday);
      expect(txId, isNotNull);
      // Un segundo registro del mismo día (p. ej. notificación y Resumen)
      // no duplica el gasto.
      expect(await repo.registerHabitual(t, _monday), isNull);

      final txs = await db.select(db.transactions).get();
      expect(txs, hasLength(1));
      expect(txs.single.amount, 1640);
      expect(txs.single.note, 'Micro/Metro');
      expect(txs.single.date, DateTime(2025, 10, 20, 8, 15));
      expect(txs.single.isRecurring, isFalse);

      final occ = await db.select(db.habitualOccurrences).getSingle();
      expect(occ.status, kHabitualRegistered);
      expect(occ.transactionId, txId);
    });

    test('"Hoy no" no crea gasto, y deshacer vuelve a dejarlo pendiente',
        () async {
      final t = await createHabitual();
      await repo.skipHabitual(t.id, _monday);
      expect(await db.select(db.transactions).get(), isEmpty);
      // Ya decidido: registrarlo después no hace nada.
      expect(await repo.registerHabitual(t, _monday), isNull);

      await repo.undoHabitualDecision(t.id, _monday);
      expect(await db.select(db.habitualOccurrences).get(), isEmpty);
    });

    test('deshacer un registro borra el gasto', () async {
      final t = await createHabitual();
      await repo.registerHabitual(t, _monday);
      await repo.undoHabitualDecision(t.id, _monday);
      expect(await db.select(db.transactions).get(), isEmpty);
      expect(await db.select(db.habitualOccurrences).get(), isEmpty);
    });

    test('el catch-up mensual no registra gastos habituales', () async {
      await createHabitual();
      final generated =
          await db.runRecurringCatchUp(today: DateTime(2025, 10, 28));
      expect(generated, isEmpty);
    });

    test('reactivar uno pausado no pide los días en pausa', () async {
      final t = await createHabitual();
      Future<void> setActive(bool active, DateTime today) =>
          repo.updateHabitual(
            t.id,
            categoryId: t.categoryId,
            amount: t.amount,
            note: t.note,
            weekdays: t.weekdays!,
            reminderTime: t.reminderTime!,
            paymentMethodId: null,
            active: active,
            today: today,
          );
      await setActive(false, DateTime(2025, 10, 20));
      await setActive(true, DateTime(2025, 10, 23, 9));
      final updated = (await repo.getAll()).single;
      expect(updated.startDate, DateTime(2025, 10, 23));
    });

    test(
        'eliminar borra sus decisiones pero no los gastos; deshacer las '
        'restaura', () async {
      final t = await createHabitual();
      final txId = await repo.registerHabitual(t, _monday);
      await repo.skipHabitual(t.id, DateTime(2025, 10, 21));

      final undo = await repo.deleteTemplateUndoable(t.id);
      expect(await db.select(db.habitualOccurrences).get(), isEmpty);
      expect(await db.select(db.transactions).get(), hasLength(1));

      await undo();
      final occ = await db.select(db.habitualOccurrences).get();
      expect(occ, hasLength(2));
      expect(
          occ.firstWhere((o) => o.status == kHabitualRegistered).transactionId,
          txId);
    });

    test('las acciones de la notificación registran o descartan', () async {
      final t = await createHabitual();
      // Martes 21 a las 9: el recordatorio de hoy ya sonó.
      final now = DateTime(2025, 10, 21, 9);
      await handleHabitualResponse(
          db, _response(kHabitualRegisterAction, t.id), now);
      // Tocar de nuevo (o responder desde Resumen) no duplica.
      await handleHabitualResponse(
          db, _response(kHabitualRegisterAction, t.id), now);
      expect(await db.select(db.transactions).get(), hasLength(1));

      await handleHabitualResponse(
          db, _response(kHabitualSkipAction, t.id), DateTime(2025, 10, 22, 9));
      final occ = await db.select(db.habitualOccurrences).get();
      expect({
        for (final o in occ) o.date.day: o.status
      }, {
        21: kHabitualRegistered,
        22: kHabitualSkipped,
      });
    });

    test('tocar la notificación sin acción no registra nada', () async {
      final t = await createHabitual();
      await handleHabitualResponse(
        db,
        NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: 'habitual:${t.id}',
        ),
        DateTime(2025, 10, 21, 9),
      );
      expect(await db.select(db.habitualOccurrences).get(), isEmpty);
    });

    test('el respaldo conserva gastos habituales y sus decisiones', () async {
      final t = await createHabitual();
      await repo.registerHabitual(t, _monday);
      await repo.skipHabitual(t.id, DateTime(2025, 10, 21));
      final data = await db.exportAllData();
      expect(data['version'], 3);
      validateBackupData(data);

      await db.restoreAllData(data);
      final restored = (await repo.getAll()).single;
      expect(restored.mode, kRecurringModeConfirm);
      expect(restored.weekdays, 0x1F);
      expect(await db.select(db.habitualOccurrences).get(), hasLength(2));
    });

    test(
        'un respaldo anterior a RF47 restaura sus recurrentes como pagos '
        'fijos', () async {
      await db.insertRecurringTemplate(
          categoryId: 'transporte_test',
          amount: 30000,
          note: 'Bencina',
          dayOfMonth: 5,
          initialYearMonth: 202510);
      final data = await db.exportAllData();
      for (final row in (data['recurringTemplates'] as List)
          .cast<Map<String, dynamic>>()) {
        row
          ..remove('mode')
          ..remove('weekdays')
          ..remove('reminderTime')
          ..remove('paymentMethodId')
          ..remove('startDate');
      }
      data.remove('habitualOccurrences');
      data['version'] = 2;
      validateBackupData(data);
      await db.restoreAllData(data);
      expect((await repo.getAll()).single.mode, kRecurringModeAuto);
    });
  });

  test('migración v10 -> v11: los recurrentes existentes quedan en modo auto',
      () async {
    final dir = await Directory.systemTemp.createTemp('migration_v11');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/v10.db');

    final raw = sqlite3.sqlite3.open(file.path);
    raw.execute('''
      CREATE TABLE categories (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        icon_key TEXT NOT NULL DEFAULT 'category',
        archived INTEGER NOT NULL DEFAULT 0
      );
      CREATE TABLE recurring_templates (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        category_id TEXT NOT NULL,
        amount INTEGER NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        day_of_month INTEGER NOT NULL,
        active INTEGER NOT NULL DEFAULT 1,
        last_generated_year_month INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      );
      INSERT INTO categories (id, name, color_value)
        VALUES ('vivienda', 'Vivienda', 1);
      INSERT INTO recurring_templates
        (category_id, amount, note, day_of_month, last_generated_year_month)
        VALUES ('vivienda', 450000, 'Arriendo', 5, 202510);
      PRAGMA user_version = 10;
    ''');
    raw.dispose();

    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);
    final templates = await db.select(db.recurringTemplates).get();
    expect(templates, hasLength(1));
    expect(templates.single.note, 'Arriendo');
    expect(templates.single.mode, kRecurringModeAuto);
    expect(templates.single.weekdays, isNull);
    expect(await db.select(db.habitualOccurrences).get(), isEmpty);
  });
}
