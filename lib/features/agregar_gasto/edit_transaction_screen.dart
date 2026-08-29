import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatting.dart';
import '../../data/local/app_database.dart';
import 'expense_form.dart';

/// RF08: editar (o eliminar) un movimiento ya registrado. Reutiliza
/// ExpenseForm precargado con los valores actuales de [transaction].
class EditTransactionScreen extends ConsumerWidget {
  const EditTransactionScreen({super.key, required this.transaction});
  final Transaction transaction;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: const Text('Eliminar gasto',
            style: TextStyle(fontSize: 16, color: AppColors.ink)),
        content: Text(
          '¿Eliminar ${currencyFmt.format(transaction.amount)}'
          '${transaction.note.isNotEmpty ? ' — ${transaction.note}' : ''}? '
          'Esta acción no se puede deshacer.',
          style: const TextStyle(color: AppColors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.inkSoft)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.rust),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref
        .read(transactionsRepositoryProvider)
        .deleteTransaction(transaction.id);
    if (context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('Editar gasto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eliminar gasto',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ExpenseForm(
            isEditing: true,
            initialAmount: transaction.amount,
            initialCategoryId: transaction.categoryId,
            initialDate: transaction.date,
            initialNote: transaction.note,
            initialRecurring: transaction.isRecurring,
            onSaved: () => Navigator.of(context).pop(),
            onSubmit: ({
              required categoryId,
              required amount,
              required date,
              required note,
              required recurring,
            }) {
              return ref.read(transactionsRepositoryProvider).updateTransaction(
                    id: transaction.id,
                    categoryId: categoryId,
                    amount: amount,
                    date: date,
                    note: note,
                    isRecurring: recurring,
                  );
            },
          ),
        ),
      ),
    );
  }
}
