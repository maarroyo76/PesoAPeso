import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatting.dart';
import '../../core/utils/quick_suggestions.dart';

/// Después de registrar a mano el gasto [transactionId], si se repite
/// ofrece una de dos cosas:
/// - RF56: guardarlo como acceso rápido (mismo monto y nota 3 veces en 30
///   días);
/// - si no, convertirlo en recurrente (misma categoría y monto que un gasto
///   del mes anterior), sugerencia que salió del onboarding.
/// Cada combinación se sugiere una sola vez, se acepte o no.
///
/// El aviso se pone en cola en [messenger] después del de "Deshacer", que
/// se muestra al volver de este registro (por eso espera al siguiente
/// cuadro).
Future<void> suggestQuickAccessIfRepeated(
    WidgetRef ref, ScaffoldMessengerState messenger, int transactionId) async {
  final txRepo = ref.read(transactionsRepositoryProvider);
  final settings = ref.read(settingsRepositoryProvider);
  final quickRepo = ref.read(quickExpenseTemplatesRepositoryProvider);
  final recurringRepo = ref.read(recurringTemplatesRepositoryProvider);
  final last = await txRepo.transactionById(transactionId);
  if (last == null) return;
  final windowStart =
      last.date.subtract(const Duration(days: kQuickSuggestionWindowDays));
  final prevMonthStart = DateTime(last.date.year, last.date.month - 1);
  final recent = await txRepo.transactionsSince(
      prevMonthStart.isBefore(windowStart) ? prevMonthStart : windowStart);
  final seen =
      decodeSeenSuggestions(await settings.get(kQuickSuggestionsSeenKey));

  final String message;
  final String actionLabel;
  final Future<void> Function() onAccept;
  final String key;
  if (shouldSuggestQuickAccess(
      last: last,
      recent: recent,
      templates: await quickRepo.getAll(),
      seen: seen)) {
    final label = last.note.trim();
    key = quickSuggestionKey(last.amount, last.note);
    message = 'Registras seguido "$label" por '
        '${currencyFmt.format(last.amount)}. ¿Lo guardas como acceso rápido?';
    actionLabel = 'Guardar';
    onAccept = () => quickRepo.create(
        label: label, amount: last.amount, categoryId: last.categoryId);
  } else if (shouldSuggestRecurring(
      last: last,
      recent: recent,
      templates: await recurringRepo.getAll(),
      seen: seen)) {
    key = recurringSuggestionKey(last.categoryId, last.amount);
    message = 'El mes pasado también pagaste '
        '${currencyFmt.format(last.amount)} en esta categoría. ¿Es un pago '
        'fijo? Regístralo solo cada mes.';
    actionLabel = 'Hacerlo recurrente';
    // Desde el mes siguiente: el de este mes ya está registrado.
    onAccept = () => recurringRepo.createTemplate(
          categoryId: last.categoryId,
          amount: last.amount,
          note: last.note,
          dayOfMonth: last.date.day,
          initialYearMonth: last.date.year * 100 + last.date.month,
        );
  } else {
    return;
  }
  await settings.set(
      kQuickSuggestionsSeenKey, encodeSeenSuggestions({...seen, key}));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!messenger.mounted) return;
    final colors = messenger.context.colors;
    messenger.showSnackBar(SnackBar(
      duration: const Duration(seconds: 8),
      persist: false,
      backgroundColor: colors.ink,
      content: Text(message),
      action: SnackBarAction(
        label: actionLabel,
        textColor: colors.paper,
        onPressed: onAccept,
      ),
    ));
  });
  WidgetsBinding.instance.ensureVisualUpdate();
}
