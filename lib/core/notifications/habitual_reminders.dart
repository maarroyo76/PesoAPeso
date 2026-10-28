import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../data/local/app_database.dart';
import '../utils/formatting.dart';
import '../utils/habitual.dart';
import 'mobile_platform.dart';
import 'notification_service.dart';

/// RF48: acciones de la notificación de un gasto habitual. Funcionan con la
/// app cerrada (ver [habitualNotificationBackgroundHandler]).
const kHabitualRegisterAction = 'habitual_register';
const kHabitualSkipAction = 'habitual_skip';

/// Categoría de iOS que declara las dos acciones (ver NotificationService).
const kHabitualDarwinCategory = 'habitual';

const _payloadPrefix = 'habitual:';

/// Los recordatorios usan ids desde acá: uno por plantilla y día de la
/// semana. Las alertas de presupuesto usan el id del gasto, muy por debajo.
const _idBase = 1000000000;

int _notificationId(int templateId, int weekday) =>
    _idBase + templateId * 8 + weekday;

bool _timezoneReady = false;

Future<void> _ensureTimezone() async {
  if (_timezoneReady) return;
  tz_data.initializeTimeZones();
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));
  } catch (_) {
    // La app es para Chile (CLP): si el sistema no informa su zona, se usa
    // la de Santiago, que también sigue el horario de verano.
    tz.setLocalLocation(tz.getLocation('America/Santiago'));
  }
  _timezoneReady = true;
}

/// Próxima vez (después de ahora) que cae [weekday] a la hora indicada.
tz.TZDateTime _nextInstance(int weekday, int hour, int minute) {
  final now = tz.TZDateTime.now(tz.local);
  var date =
      tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
  while (date.weekday != weekday || !date.isAfter(now)) {
    // Se arma de nuevo con día + 1 (no sumando 24 horas) para que el cambio
    // de horario no corra la hora del recordatorio.
    date = tz.TZDateTime(
        tz.local, date.year, date.month, date.day + 1, hour, minute);
  }
  return date;
}

/// RF48: reprograma los recordatorios de todos los gastos habituales activos.
/// Se llama al abrir la app y al crear, editar, pausar o eliminar uno.
///
/// RNF20: notificaciones semanales inexactas (`inexactAllowWhileIdle`), sin
/// pedir el permiso de alarmas exactas. Android puede atrasarlas unos minutos
/// para ahorrar batería.
Future<void> syncHabitualReminders({
  required List<RecurringTemplate> templates,
  required Map<String, Category> categoriesById,
}) async {
  if (!isMobileDevice) return;
  final plugin = NotificationService.instance.plugin;
  final habituals = templates.where((t) => isHabitual(t) && t.active).toList();

  // Sin gastos habituales no se pide el permiso de notificaciones.
  if (habituals.isEmpty) {
    final pending = await plugin.pendingNotificationRequests();
    for (final p in pending.where((p) => p.id >= _idBase)) {
      await plugin.cancel(id: p.id);
    }
    return;
  }

  await NotificationService.instance.init();
  await _ensureTimezone();
  final pending = await plugin.pendingNotificationRequests();
  for (final p in pending.where((p) => p.id >= _idBase)) {
    await plugin.cancel(id: p.id);
  }

  for (final t in habituals) {
    final time = parseReminderTime(t.reminderTime);
    final mask = t.weekdays ?? 0;
    if (time == null || mask == 0) continue;
    final categoryName = categoriesById[t.categoryId]?.name ?? '';
    final label = t.note.isNotEmpty ? t.note : categoryName;
    for (var weekday = 1; weekday <= 7; weekday++) {
      if (!includesWeekday(mask, weekday)) continue;
      await plugin.zonedSchedule(
        id: _notificationId(t.id, weekday),
        title: '¿Registras "$label"?',
        body: '${currencyFmt.format(t.amount)} · $categoryName',
        scheduledDate: _nextInstance(weekday, time.hour, time.minute),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: '$_payloadPrefix${t.id}',
      );
    }
  }
}

const _details = NotificationDetails(
  android: AndroidNotificationDetails(
    'habitual_reminders',
    'Gastos habituales',
    channelDescription:
        'Pregunta si ocurrió un gasto habitual, como el metro o la colación.',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    actions: [
      AndroidNotificationAction(kHabitualRegisterAction, 'Registrar'),
      AndroidNotificationAction(kHabitualSkipAction, 'Hoy no'),
    ],
  ),
  iOS: DarwinNotificationDetails(categoryIdentifier: kHabitualDarwinCategory),
);

/// RF48: aplica la respuesta a la notificación de un gasto habitual. Tocar
/// la notificación (sin acción) solo abre la app, donde el día aparece como
/// pendiente en Resumen (RF49).
Future<void> handleHabitualResponse(
    AppDatabase db, NotificationResponse response, DateTime now) async {
  final payload = response.payload;
  if (payload == null || !payload.startsWith(_payloadPrefix)) return;
  final action = response.actionId;
  if (action != kHabitualRegisterAction && action != kHabitualSkipAction) {
    return;
  }
  final templateId = int.tryParse(payload.substring(_payloadPrefix.length));
  if (templateId == null) return;
  final template = await (db.select(db.recurringTemplates)
        ..where((t) => t.id.equals(templateId)))
      .getSingleOrNull();
  if (template == null || !isHabitual(template) || !template.active) return;
  final day = lastDueDay(template, now);
  if (day == null) return;
  if (action == kHabitualRegisterAction) {
    await db.registerHabitual(
      templateId: templateId,
      day: day,
      date: habitualTransactionDate(template, day),
    );
  } else {
    await db.skipHabitual(templateId: templateId, day: day);
  }
}

/// RF48: corre en un isolate aparte cuando el usuario toca "Registrar" u
/// "Hoy no" con la app cerrada o en segundo plano. Abre su propia conexión a
/// la base (la clave de cifrado se lee del Keystore/Keychain igual que en la
/// app) y la cierra al terminar.
@pragma('vm:entry-point')
Future<void> habitualNotificationBackgroundHandler(
    NotificationResponse response) async {
  DartPluginRegistrant.ensureInitialized();
  final db = AppDatabase();
  try {
    await handleHabitualResponse(db, response, DateTime.now());
  } finally {
    await db.close();
  }
}

/// Reprograma los recordatorios leyendo plantillas y categorías de [db].
Future<void> syncHabitualRemindersFrom(AppDatabase db) async {
  if (!isMobileDevice) return;
  await syncHabitualReminders(
    templates: await db.select(db.recurringTemplates).get(),
    categoriesById: {
      for (final c in await db.select(db.categories).get()) c.id: c,
    },
  );
}
