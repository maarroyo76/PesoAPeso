import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/category_icons.dart';
import '../../core/utils/formatting.dart';
import '../../data/local/app_database.dart';
import '../agregar_gasto/edit_transaction_screen.dart';

final _dateFmt = DateFormat('d MMM, HH:mm', 'es_CL');

class TransactionDetailSheet extends ConsumerWidget {
  const TransactionDetailSheet({
    super.key,
    required this.category,
    required this.transactions,
  });

  final Category category;
  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(category.colorValue);
    final total = transactions.fold<int>(0, (a, t) => a + t.amount);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (_, controller) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.rule,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 40,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(iconForCategory(category), size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.name,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink)),
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.inkSoft),
                          children: [
                            TextSpan(
                                text:
                                    '${transactions.length} gasto${transactions.length == 1 ? '' : 's'} · '),
                            TextSpan(
                                text: currencyFmt.format(total),
                                style: appAmountTextStyle.copyWith(
                                    fontSize: 12, color: AppColors.inkSoft)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: transactions.isEmpty
                ? const Center(
                    child: Text('Sin gastos en este período.',
                        style:
                            TextStyle(color: AppColors.inkSoft, fontSize: 13)))
                : ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 20),
                    itemBuilder: (context, i) {
                      final tx = transactions[i];
                      return _TxTile(
                        tx: tx,
                        onEdit: () async {
                          final deleted = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditTransactionScreen(transaction: tx),
                            ),
                          );
                          // Si se eliminó desde la pantalla de edición, esta
                          // hoja quedaría mostrando una lista obsoleta (es un
                          // snapshot, no un stream) — se cierra para no
                          // confundir al usuario con un gasto ya borrado.
                          if (deleted == true && context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        onDelete: () async {
                          await ref
                              .read(transactionsRepositoryProvider)
                              .deleteTransaction(tx.id);
                          if (context.mounted && transactions.length == 1) {
                            Navigator.pop(context);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  const _TxTile(
      {required this.tx, required this.onEdit, required this.onDelete});
  final Transaction tx;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dateStr = _dateFmt.format(tx.date);

    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.rust,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.paper,
            title: const Text('Eliminar gasto',
                style: TextStyle(fontSize: 16, color: AppColors.ink)),
            content: Text(
              '${currencyFmt.format(tx.amount)}${tx.note.isNotEmpty ? ' — ${tx.note}' : ''}',
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
      },
      onDismissed: (_) => onDelete(),
      child: ListTile(
        onTap: onEdit,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: Text(
          currencyFmt.format(tx.amount),
          style: appAmountTextStyle.copyWith(
              fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tx.note.isNotEmpty)
              Text(tx.note,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            Row(
              children: [
                Text(dateStr,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.inkSoft)),
                if (tx.isRecurring) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.repeat, size: 12, color: AppColors.inkSoft),
                ],
              ],
            ),
          ],
        ),
        trailing:
            const Icon(Icons.chevron_right, size: 16, color: AppColors.inkSoft),
      ),
    );
  }
}
