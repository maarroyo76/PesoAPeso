import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/budget_alert.dart';
import '../../core/utils/formatting.dart';
import '../../core/utils/habitual.dart';
import '../../core/widgets/undo_snack_bar.dart';
import '../../data/local/app_database.dart';

/// RF49: días de gastos habituales sin confirmar, con opciones para
/// registrarlos todos o revisarlos uno por uno. Un día pendiente no genera
/// gasto hasta confirmarse; los de hace más de una semana no se muestran.
class HabitualPendingCard extends ConsumerWidget {
  const HabitualPendingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(recurringTemplatesProvider).valueOrNull;
    // Sin gastos habituales activos no hace falta leer sus decisiones.
    if (templates == null || !templates.any((t) => isHabitual(t) && t.active)) {
      return const SizedBox.shrink();
    }
    final occurrences = ref.watch(habitualOccurrencesProvider).valueOrNull;
    if (occurrences == null) return const SizedBox.shrink();
    final pending = pendingHabituals(
        templates: templates, occurrences: occurrences, now: DateTime.now());
    if (pending.isEmpty) return const SizedBox.shrink();

    final total = pending.fold<int>(0, (a, p) => a + p.template.amount);
    final single = pending.length == 1 ? pending.single : null;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.paperDeep,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.colors.rule),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                single == null
                    ? 'Gastos habituales sin confirmar'
                    : '¿Registras "${habitualLabel(ref, single.template)}"?',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: context.colors.ink)),
            const SizedBox(height: 4),
            Text(
              single == null
                  ? '${pending.length} días pendientes · '
                      '${currencyFmt.format(total)} en total'
                  : '${pendingDayLabel(single.day)} · '
                      '${currencyFmt.format(single.template.amount)}',
              style: TextStyle(fontSize: 13, color: context.colors.inkSoft),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: context.colors.ink),
                  onPressed: () => registerPending(context, ref, pending),
                  child: Text(single == null ? 'Registrar todos' : 'Registrar'),
                ),
                if (single == null)
                  TextButton(
                    onPressed: () => _showReviewSheet(context),
                    child: const Text('Revisar uno por uno'),
                  )
                else
                  TextButton(
                    onPressed: () => skipPending(context, ref, single),
                    child: Text(skipLabel(single.day)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _HabitualReviewSheet(),
    );
  }
}

/// Nombre visible de un gasto habitual: su nota o, si no tiene, su categoría.
String habitualLabel(WidgetRef ref, RecurringTemplate template) {
  if (template.note.isNotEmpty) return template.note;
  final categories = ref.read(categoriesProvider).valueOrNull ?? const [];
  return categories
          .where((c) => c.id == template.categoryId)
          .firstOrNull
          ?.name ??
      '';
}

String pendingDayLabel(DateTime day) {
  final today = dateOnly(DateTime.now());
  if (day == today) return 'Hoy';
  if (day == DateTime(today.year, today.month, today.day - 1)) return 'Ayer';
  final label = DateFormat('EEEE d MMM', 'es_CL').format(day);
  return label[0].toUpperCase() + label.substring(1);
}

/// "Hoy no" (como en la notificación, RF48) para hoy; para un día pasado,
/// "No ocurrió".
String skipLabel(DateTime day) =>
    day == dateOnly(DateTime.now()) ? 'Hoy no' : 'No ocurrió';

/// Registra [pending] y ofrece deshacerlo. Avisa si el registro dejó alguna
/// categoría o el total cerca de su presupuesto (RF18/RF55).
Future<void> registerPending(
    BuildContext context, WidgetRef ref, List<PendingHabitual> pending) async {
  final messenger = ScaffoldMessenger.of(context);
  final repo = ref.read(recurringTemplatesRepositoryProvider);
  final registered = <PendingHabitual>[];
  for (final p in pending) {
    if (await repo.registerHabitual(p.template, p.day) != null) {
      registered.add(p);
    }
  }
  if (registered.isEmpty) return;
  final alerts = <BudgetAlertInfo>[];
  for (final categoryId in {
    for (final p in registered) p.template.categoryId
  }) {
    final last =
        registered.lastWhere((p) => p.template.categoryId == categoryId);
    alerts.addAll(await checkBudgetAlerts(ref,
        categoryId: categoryId,
        date: habitualTransactionDate(last.template, last.day)));
  }
  // El aviso del total (RF55) sale una sola vez por umbral y mes, aunque se
  // revise una vez por categoría.
  if (context.mounted) showBudgetAlertBanner(context, alerts);
  showUndoSnackBar(
    messenger,
    message: registered.length == 1
        ? 'Registrado: ${habitualLabel(ref, registered.single.template)}'
        : '${registered.length} gastos registrados',
    onUndo: () async {
      for (final p in registered) {
        await repo.undoHabitualDecision(p.template.id, p.day);
      }
    },
  );
}

/// "Hoy no": el día queda descartado, sin gasto. Se puede deshacer.
Future<void> skipPending(
    BuildContext context, WidgetRef ref, PendingHabitual p) async {
  final messenger = ScaffoldMessenger.of(context);
  final repo = ref.read(recurringTemplatesRepositoryProvider);
  await repo.skipHabitual(p.template.id, p.day);
  showUndoSnackBar(
    messenger,
    message: 'Descartado: ${habitualLabel(ref, p.template)}',
    onUndo: () => repo.undoHabitualDecision(p.template.id, p.day),
  );
}

/// RF49: revisar los pendientes uno por uno.
class _HabitualReviewSheet extends ConsumerWidget {
  const _HabitualReviewSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(recurringTemplatesProvider).valueOrNull ?? [];
    final occurrences =
        ref.watch(habitualOccurrencesProvider).valueOrNull ?? [];
    final pending = pendingHabituals(
            templates: templates, occurrences: occurrences, now: DateTime.now())
        .reversed
        .toList();

    // El aviso de "Deshacer" va en el messenger propio de la hoja: el de la
    // app queda detrás de ella.
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gastos habituales sin confirmar',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.colors.ink)),
                const SizedBox(height: 4),
                Text(
                  'Registra los que ocurrieron. Los de hace más de una '
                  'semana se descartan solos.',
                  style: TextStyle(fontSize: 12, color: context.colors.inkSoft),
                ),
                const SizedBox(height: 12),
                if (pending.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('No quedan días pendientes.',
                        style: TextStyle(color: context.colors.inkSoft)),
                  ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final p in pending)
                        Builder(
                          builder: (context) => _PendingRow(
                            pending: p,
                            label: habitualLabel(ref, p.template),
                            onRegister: () =>
                                registerPending(context, ref, [p]),
                            onSkip: () => skipPending(context, ref, p),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({
    required this.pending,
    required this.label,
    required this.onRegister,
    required this.onSkip,
  });
  final PendingHabitual pending;
  final String label;
  final VoidCallback onRegister;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                    '${pendingDayLabel(pending.day)} · '
                    '${currencyFmt.format(pending.template.amount)}',
                    style:
                        TextStyle(fontSize: 12, color: context.colors.inkSoft)),
              ],
            ),
          ),
          TextButton(onPressed: onSkip, child: Text(skipLabel(pending.day))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.colors.ink),
            onPressed: onRegister,
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }
}
