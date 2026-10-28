import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/habitual_reminders.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/amount_input.dart';
import '../../core/utils/habitual.dart';
import '../../data/local/app_database.dart';
import '../agregar_gasto/expense_form.dart'
    show ExpenseCategoryChip, PaymentMethodPicker;
import '../categorias/category_filters.dart';

/// Lunes a viernes: el caso más común (metro, colación).
const _defaultWeekdays = 0x1F;

/// RF47: crea ([template] null) o edita un gasto habitual: monto, categoría,
/// método de pago, días de la semana y hora del recordatorio. A diferencia
/// de los pagos fijos, no se registra solo: cada día programado pide
/// confirmación (RF48/RF49).
Future<void> showHabitualEditor(
  BuildContext context,
  WidgetRef ref,
  List<Category> categories, {
  RecurringTemplate? template,
}) async {
  categories = selectableCategories(categories, keep: template?.categoryId);
  if (categories.isEmpty) return;
  final amountController = TextEditingController(
      text: template == null ? '' : formatAmountInput(template.amount));
  final noteController = TextEditingController(text: template?.note ?? '');
  var categoryId = template?.categoryId ?? categories.first.id;
  var paymentMethodId = template?.paymentMethodId;
  var weekdays = template?.weekdays ?? _defaultWeekdays;
  var time = parseReminderTime(template?.reminderTime) ?? (hour: 8, minute: 0);
  var active = template?.active ?? true;
  String? amountError;
  String? weekdaysError;

  final save = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: context.colors.paper,
        title: Text(
            template == null ? 'Nuevo gasto habitual' : 'Editar gasto habitual',
            style: TextStyle(fontSize: 16, color: context.colors.ink)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Para gastos que se repiten casi a diario, pero no siempre. '
                'A la hora que elijas te preguntamos si ocurrió; nada se '
                'registra sin tu confirmación.',
                style: TextStyle(fontSize: 12, color: context.colors.inkSoft),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                maxLength: kMaxNoteLength,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    labelText: 'Nombre (p. ej. Micro/Metro)',
                    border: UnderlineInputBorder()),
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: amountInputFormatters,
                decoration: InputDecoration(
                    labelText: 'Monto',
                    prefixText: '\$ ',
                    errorText: amountError,
                    border: const UnderlineInputBorder()),
              ),
              const SizedBox(height: 16),
              _label(context, 'Días'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var d = 1; d <= 7; d++)
                    _WeekdayChip(
                      weekday: d,
                      selected: includesWeekday(weekdays, d),
                      onTap: () => setDialogState(() {
                        weekdays ^= weekdayBit(d);
                        weekdaysError = null;
                      }),
                    ),
                ],
              ),
              if (weekdaysError != null) ...[
                const SizedBox(height: 4),
                Text(weekdaysError!,
                    style: TextStyle(fontSize: 12, color: context.colors.rust)),
              ],
              const SizedBox(height: 12),
              _label(context, 'Recordatorio'),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: context.colors.ink,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime:
                          TimeOfDay(hour: time.hour, minute: time.minute),
                    );
                    if (picked != null) {
                      setDialogState(() =>
                          time = (hour: picked.hour, minute: picked.minute));
                    }
                  },
                  icon: const Icon(Icons.schedule, size: 18),
                  label: Text(formatReminderTime(time.hour, time.minute),
                      style: appAmountTextStyle.copyWith(fontSize: 14)),
                ),
              ),
              const SizedBox(height: 8),
              _label(context, 'Categoría'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in categories)
                    ExpenseCategoryChip(
                      category: c,
                      selected: c.id == categoryId,
                      onTap: () => setDialogState(() => categoryId = c.id),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _label(context, 'Pagado con'),
              const SizedBox(height: 8),
              PaymentMethodPicker(
                selectedId: paymentMethodId,
                onSelected: (id) => setDialogState(() => paymentMethodId = id),
              ),
              if (template != null) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activo', style: TextStyle(fontSize: 13)),
                  subtitle: Text(
                      'Si lo pausas, no te preguntaremos hasta reactivarlo',
                      style: TextStyle(
                          fontSize: 11, color: context.colors.inkSoft)),
                  value: active,
                  activeThumbColor: context.colors.green,
                  onChanged: (v) => setDialogState(() => active = v),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TextStyle(color: context.colors.inkSoft)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.colors.ink),
            onPressed: () {
              final amount = parsePositiveAmount(amountController.text);
              if (amount == null || weekdays == 0) {
                setDialogState(() {
                  amountError = amount == null ? kInvalidAmountMessage : null;
                  weekdaysError =
                      weekdays == 0 ? 'Elige al menos un día' : null;
                });
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );

  if (save != true) return;
  final repo = ref.read(recurringTemplatesRepositoryProvider);
  final amount = parseAmountText(amountController.text)!;
  final reminder = formatReminderTime(time.hour, time.minute);
  if (template == null) {
    await repo.createHabitual(
      categoryId: categoryId,
      amount: amount,
      note: noteController.text.trim(),
      weekdays: weekdays,
      reminderTime: reminder,
      paymentMethodId: paymentMethodId,
    );
  } else {
    await repo.updateHabitual(
      template.id,
      categoryId: categoryId,
      amount: amount,
      note: noteController.text.trim(),
      weekdays: weekdays,
      reminderTime: reminder,
      paymentMethodId: paymentMethodId,
      active: active,
    );
  }
  await syncHabitualRemindersFrom(ref.read(appDatabaseProvider));
}

Widget _label(BuildContext context, String text) =>
    Text(text, style: TextStyle(fontSize: 12, color: context.colors.inkSoft));

class _WeekdayChip extends StatelessWidget {
  const _WeekdayChip(
      {required this.weekday, required this.selected, required this.onTap});
  final int weekday;
  final bool selected;
  final VoidCallback onTap;

  static const _names = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // UX08: la inicial sola ("M") no distingue martes de miércoles.
      label: _names[weekday - 1],
      selected: selected,
      button: true,
      excludeSemantics: true,
      child: ChoiceChip(
        label: Text(kWeekdayInitials[weekday - 1]),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
