import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/category_icons.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/undo_snack_bar.dart';
import '../../data/local/app_database.dart';
import '../agregar_gasto/edit_transaction_screen.dart';
import '../metodos_pago/payment_method_labels.dart';

final _dateFmt = DateFormat('d MMM, HH:mm', 'es_CL');
final _dayFmt = DateFormat('d MMM', 'es_CL');

class TransactionDetailSheet extends ConsumerWidget {
  const TransactionDetailSheet({
    super.key,
    required this.category,
    required this.month,
    required this.transactions,
  });

  final Category category;
  final DateTime month;

  /// Gastos al abrir la hoja; luego se usa el stream del mes, para que
  /// eliminar (y deshacer) se refleje en la lista y en el total.
  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodsById =
        paymentMethodsById(ref.watch(paymentMethodsProvider).valueOrNull);
    final transactions = (ref
            .watch(monthTransactionsProvider(month))
            .valueOrNull
            ?.where((t) => t.categoryId == category.id)
            .toList() ??
        this.transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    final color = context.colors.category(category.colorValue);
    final total = transactions.fold<int>(0, (a, t) => a + t.amount);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      // Messenger propio: el aviso "Deshacer" debe verse sobre la hoja, no
      // detrás de ella en la pantalla de la app.
      builder: (_, controller) => ScaffoldMessenger(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          body: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.rule,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                      child: Icon(iconForCategory(category),
                          size: 20, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(category.name,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.ink)),
                          Text.rich(
                            TextSpan(
                              style: TextStyle(
                                  fontSize: 12, color: context.colors.inkSoft),
                              children: [
                                TextSpan(
                                    text:
                                        '${transactions.length} gasto${transactions.length == 1 ? '' : 's'} · '),
                                TextSpan(
                                    text: currencyFmt.format(total),
                                    style: appAmountTextStyle.copyWith(
                                        fontSize: 12,
                                        color: context.colors.inkSoft)),
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
                    ? Center(
                        child: Text('Sin gastos en este período.',
                            style: TextStyle(
                                color: context.colors.inkSoft, fontSize: 13)))
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
                            paymentLabel:
                                transactionPaymentLabel(tx, methodsById),
                            onEdit: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              // Si se eliminó desde la pantalla de edición, vuelve
                              // con la acción para deshacerlo.
                              final undo = await Navigator.push<UndoAction>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EditTransactionScreen(transaction: tx),
                                ),
                              );
                              if (undo != null) {
                                showUndoSnackBar(messenger,
                                    message: 'Gasto eliminado', onUndo: undo);
                              }
                            },
                            onDelete: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final undo = await ref
                                  .read(transactionsRepositoryProvider)
                                  .deleteTransactionUndoable(tx.id);
                              showUndoSnackBar(messenger,
                                  message: 'Gasto eliminado', onUndo: undo);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  const _TxTile(
      {required this.tx,
      required this.paymentLabel,
      required this.onEdit,
      required this.onDelete});
  final Transaction tx;

  /// RF32: con qué se pagó; null si no tiene método.
  final String? paymentLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dateStr = hasMeaningfulTime(tx.date, isRecurring: tx.isRecurring)
        ? _dateFmt.format(tx.date)
        : _dayFmt.format(tx.date);

    return Semantics(
      // UX08: deslizar no está disponible con lector de pantalla; la misma
      // acción se ofrece en el menú de acciones de TalkBack / VoiceOver.
      customSemanticsActions: {
        const CustomSemanticsAction(label: 'Eliminar'): onDelete,
      },
      child: Dismissible(
        key: ValueKey(tx.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: context.colors.rust,
          child: Icon(Icons.delete_outline, color: context.colors.paper),
        ),
        onDismissed: (_) => onDelete(),
        child: ListTile(
          onTap: onEdit,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          title: Text(
            currencyFmt.format(tx.amount),
            style: appAmountTextStyle.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.colors.ink),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tx.note.isNotEmpty)
                Text(tx.note,
                    style:
                        TextStyle(fontSize: 12, color: context.colors.inkSoft)),
              Row(
                children: [
                  Flexible(
                    child: Text(
                        paymentLabel == null
                            ? dateStr
                            : '$dateStr · $paymentLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11, color: context.colors.inkSoft)),
                  ),
                  if (tx.isRecurring) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.repeat, size: 12, color: context.colors.inkSoft),
                  ],
                ],
              ),
            ],
          ),
          trailing: Icon(Icons.chevron_right,
              size: 16, color: context.colors.inkSoft),
        ),
      ),
    );
  }
}
