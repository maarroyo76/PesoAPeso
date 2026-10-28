import '../../data/local/app_database.dart';

/// RF47: modos de una plantilla de RecurringTemplates. 'auto' es el pago fijo
/// mensual que se registra solo (RF12); 'confirm' es un gasto habitual, que
/// se repite ciertos días de la semana pero solo se registra si el usuario lo
/// confirma (feriados, teletrabajo y vacaciones hacen que no siempre ocurra).
const kRecurringModeAuto = 'auto';
const kRecurringModeConfirm = 'confirm';

/// Decisión del usuario sobre un día de un gasto habitual (RF48/RF49).
const kHabitualRegistered = 'registered';
const kHabitualSkipped = 'skipped';

/// RF49: los días sin confirmar de hace más de una semana se descartan solos.
const kHabitualPendingDays = 7;

/// Bit del día en la máscara de `weekdays`: lunes = 1 … domingo = 64.
int weekdayBit(int weekday) => 1 << (weekday - 1);

bool includesWeekday(int mask, int weekday) => mask & weekdayBit(weekday) != 0;

const kWeekdayInitials = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
const _weekdayShortNames = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

/// Texto corto de los días elegidos, p. ej. "lun a vie" o "lun, mié, vie".
String describeWeekdays(int mask) {
  if (mask == 0x7F) return 'Todos los días';
  if (mask == 0x1F) return 'lun a vie';
  if (mask == 0x60) return 'Fines de semana';
  return [
    for (var d = 1; d <= 7; d++)
      if (includesWeekday(mask, d)) _weekdayShortNames[d - 1],
  ].join(', ');
}

/// Hora "HH:mm" como (hora, minuto); null si el texto no es válido.
({int hour, int minute})? parseReminderTime(String? text) {
  final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(text ?? '');
  if (match == null) return null;
  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if (hour > 23 || minute > 59) return null;
  return (hour: hour, minute: minute);
}

String formatReminderTime(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool isHabitual(RecurringTemplate t) => t.mode == kRecurringModeConfirm;

/// Fecha y hora con que se registra el gasto de [day]: la del recordatorio,
/// para que el historial muestre una hora real y no "00:00" (I7).
DateTime habitualTransactionDate(RecurringTemplate template, DateTime day) {
  final time = parseReminderTime(template.reminderTime);
  return DateTime(
      day.year, day.month, day.day, time?.hour ?? 12, time?.minute ?? 0);
}

/// Si [day] es un día programado de [template] cuyo recordatorio ya pasó en
/// [now]. Hoy cuenta solo desde la hora del recordatorio.
bool _isDue(RecurringTemplate template, DateTime day, DateTime now) {
  if (!includesWeekday(template.weekdays ?? 0, day.weekday)) return false;
  final start = template.startDate;
  if (start != null && day.isBefore(dateOnly(start))) return false;
  return !habitualTransactionDate(template, day).isAfter(now);
}

/// Un día programado de un gasto habitual que el usuario aún no decidió.
typedef PendingHabitual = ({RecurringTemplate template, DateTime day});

/// RF49: días programados de los gastos habituales activos, sin registrar ni
/// descartar, de la última semana. Un día programado sin fila en
/// HabitualOccurrences es un pendiente; los más antiguos se descartan solos
/// (no se muestran). Ordenados del más antiguo al más reciente.
List<PendingHabitual> pendingHabituals({
  required List<RecurringTemplate> templates,
  required List<HabitualOccurrence> occurrences,
  required DateTime now,
}) {
  final decided = {
    for (final o in occurrences) (o.templateId, dateOnly(o.date)),
  };
  final today = dateOnly(now);
  final pending = <PendingHabitual>[];
  for (var back = kHabitualPendingDays; back >= 0; back--) {
    final day = DateTime(today.year, today.month, today.day - back);
    for (final t in templates) {
      if (!isHabitual(t) || !t.active) continue;
      if (!_isDue(t, day, now)) continue;
      if (decided.contains((t.id, day))) continue;
      pending.add((template: t, day: day));
    }
  }
  return pending;
}

/// RF48: día al que corresponde un recordatorio respondido en [now]: el
/// último día programado cuyo recordatorio ya sonó. Así, responder tarde
/// (pasada la medianoche) no anota el gasto en el día equivocado. Null si no
/// hay ninguno en la última semana.
DateTime? lastDueDay(RecurringTemplate template, DateTime now) {
  final today = dateOnly(now);
  for (var back = 0; back <= kHabitualPendingDays; back++) {
    final day = DateTime(today.year, today.month, today.day - back);
    if (_isDue(template, day, now)) return day;
  }
  return null;
}
