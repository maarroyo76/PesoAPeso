import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/budget_alert.dart';
import '../../core/widgets/undo_snack_bar.dart';
import '../../data/local/app_database.dart';
import '../recurrentes/recurrentes_screen.dart' show showRecurringEditor;
import 'expense_form.dart';

/// RF08: editar (o eliminar) un movimiento ya registrado. Reutiliza
/// ExpenseForm precargado con los valores actuales de [transaction].
class EditTransactionScreen extends ConsumerWidget {
  const EditTransactionScreen({super.key, required this.transaction});
  final Transaction transaction;

  /// UX02: elimina sin diálogo y cierra la pantalla devolviendo cómo
  /// deshacerlo; quien la abrió muestra el aviso "Deshacer".
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final undo = await ref
        .read(transactionsRepositoryProvider)
        .deleteTransactionUndoable(transaction.id);
    if (context.mounted) Navigator.of(context).pop<UndoAction>(undo);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.colors.paper,
      appBar: AppBar(
        title: const Text('Editar gasto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eliminar gasto',
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (transaction.recurringTemplateId != null)
                _RecurringOriginCard(
                    templateId: transaction.recurringTemplateId!),
              ExpenseForm(
                isEditing: true,
                initialAmount: transaction.amount,
                initialCategoryId: transaction.categoryId,
                initialDate: transaction.date,
                initialNote: transaction.note,
                initialRecurring: transaction.isRecurring,
                initialPaymentMethodId: transaction.paymentMethodId,
                onSaved: () => Navigator.of(context).pop(),
                onSubmit: ({
                  required categoryId,
                  required amount,
                  required date,
                  required note,
                  required recurring,
                  required paymentMethodId,
                }) async {
                  await ref
                      .read(transactionsRepositoryProvider)
                      .updateTransaction(
                        id: transaction.id,
                        categoryId: categoryId,
                        amount: amount,
                        date: date,
                        note: note,
                        isRecurring: recurring,
                        paymentMethodId: paymentMethodId,
                      );
                  // RF18/RF55: editar un gasto también puede dejar la
                  // categoría o el total en 80%.
                  final alerts = await checkBudgetAlerts(ref,
                      categoryId: categoryId, date: date);
                  if (context.mounted) showBudgetAlertBanner(context, alerts);
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// I4: un gasto generado por una plantilla recurrente lleva a ella. Editar el
/// gasto solo cambia esta ocurrencia; los meses siguientes se cambian (o se
/// detienen) desde la plantilla.
class _RecurringOriginCard extends ConsumerWidget {
  const _RecurringOriginCard({required this.templateId});
  final int templateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(recurringTemplatesProvider).valueOrNull;
    final categories = ref.watch(categoriesProvider).valueOrNull;
    final template = templates?.where((t) => t.id == templateId).firstOrNull;
    if (template == null || categories == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.rule),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.repeat, size: 18, color: context.colors.inkSoft),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Generado por un gasto recurrente (día ${template.dayOfMonth}). '
              'Los cambios aquí no afectan los meses siguientes.',
              style: TextStyle(fontSize: 12, color: context.colors.inkSoft),
            ),
          ),
          TextButton(
            onPressed: () => showRecurringEditor(context, ref, categories,
                template: template),
            child: Text('Ver recurrente',
                style: TextStyle(color: context.colors.ink)),
          ),
        ],
      ),
    );
  }
}
