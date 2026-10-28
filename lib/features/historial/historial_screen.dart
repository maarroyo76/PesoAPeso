import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/category_icons.dart';
import '../../core/utils/formatting.dart';
import '../../core/utils/history_filter.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/undo_snack_bar.dart';
import '../../data/local/app_database.dart';
import '../agregar_gasto/edit_transaction_screen.dart';
import '../metodos_pago/payment_method_labels.dart';

final _dayFmt = DateFormat("EEEE d 'de' MMMM", 'es_CL');
final _dayYearFmt = DateFormat("EEEE d 'de' MMMM 'de' y", 'es_CL');
final _timeFmt = DateFormat('HH:mm', 'es_CL');

/// "Hoy", "Ayer" o "lunes 26 de octubre" (con el año si no es el actual).
String historyDayLabel(DateTime day, DateTime today) {
  final t = DateTime(today.year, today.month, today.day);
  if (day == t) return 'Hoy';
  if (day == t.subtract(const Duration(days: 1))) return 'Ayer';
  final label = (day.year == today.year ? _dayFmt : _dayYearFmt).format(day);
  return label[0].toUpperCase() + label.substring(1);
}

/// Abre el detalle de [tx] y, si se eliminó desde ahí, ofrece deshacerlo.
Future<void> openTransactionDetail(BuildContext context, Transaction tx) async {
  final messenger = ScaffoldMessenger.of(context);
  final undo = await Navigator.push<UndoAction>(
    context,
    MaterialPageRoute(builder: (_) => EditTransactionScreen(transaction: tx)),
  );
  if (undo != null) {
    showUndoSnackBar(messenger, message: 'Gasto eliminado', onUndo: undo);
  }
}

/// UX06: todos los gastos agrupados por día, con búsqueda por nota o
/// categoría y filtros por categoría y método de pago. Tocar un gasto abre
/// su propio detalle.
class HistorialScreen extends ConsumerStatefulWidget {
  const HistorialScreen({super.key});

  @override
  ConsumerState<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends ConsumerState<HistorialScreen> {
  final _searchController = TextEditingController();
  String? _categoryId;
  int? _paymentMethodId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(allTransactionsProvider);
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final categoriesById = {for (final c in categories) c.id: c};
    final methods = ref.watch(paymentMethodsProvider).valueOrNull ??
        const <PaymentMethod>[];
    final methodsById = paymentMethodsById(methods);

    return Scaffold(
      backgroundColor: context.colors.paper,
      appBar: AppBar(title: const Text('Historial')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar por nota o categoría',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Borrar búsqueda',
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              setState(() => _searchController.clear()),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              // Expandidos y con elipsis: con letra grande no se desbordan.
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String?>(
                      value: _categoryId,
                      isExpanded: true,
                      onChanged: (v) => setState(() => _categoryId = v),
                      items: [
                        const DropdownMenuItem(
                            value: null,
                            child: _Option('Todas las categorías')),
                        for (final c in categories)
                          DropdownMenuItem(value: c.id, child: _Option(c.name)),
                      ],
                    ),
                  ),
                  if (methods.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<int?>(
                        value: _paymentMethodId,
                        isExpanded: true,
                        onChanged: (v) => setState(() => _paymentMethodId = v),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: _Option('Todos los métodos')),
                          for (final m in methods)
                            DropdownMenuItem(
                                value: m.id,
                                child: _Option(paymentMethodLabel(m))),
                          const DropdownMenuItem(
                              value: kUnspecifiedPaymentFilter,
                              child: _Option(kNoPaymentMethodLabel)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: txAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => LoadError(e),
                data: (all) {
                  final filtered = filterHistory(
                    all.where((t) => categoriesById.containsKey(t.categoryId)),
                    query: _searchController.text,
                    categoryId: _categoryId,
                    paymentMethodId: _paymentMethodId,
                    categoryNames: {for (final c in categories) c.id: c.name},
                  );
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        all.isEmpty
                            ? 'Todavía no hay gastos registrados.'
                            : 'No hay gastos que coincidan.',
                        style: TextStyle(color: context.colors.inkSoft),
                      ),
                    );
                  }
                  final groups = groupByDay(filtered);
                  final today = DateTime.now();
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    itemCount: groups.length,
                    itemBuilder: (context, i) {
                      final (day, txs) = groups[i];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(historyDayLabel(day, today),
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: context.colors.inkSoft)),
                                ),
                                Text(
                                  currencyFmt.format(
                                      txs.fold<int>(0, (a, t) => a + t.amount)),
                                  style: appAmountTextStyle.copyWith(
                                      fontSize: 12,
                                      color: context.colors.inkSoft),
                                ),
                              ],
                            ),
                          ),
                          for (final t in txs)
                            _HistoryRow(
                              tx: t,
                              category: categoriesById[t.categoryId]!,
                              paymentLabel:
                                  transactionPaymentLabel(t, methodsById),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.tx,
    required this.category,
    required this.paymentLabel,
  });
  final Transaction tx;
  final Category category;
  final String? paymentLabel;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.category(category.colorValue);
    // I7: los gastos generados solos no tienen hora real.
    final time = tx.isRecurring ? null : _timeFmt.format(tx.date);
    final details = [
      category.name,
      if (time != null) time,
      if (paymentLabel != null) paymentLabel!,
    ].join(' · ');
    return InkWell(
      onTap: () => openTransactionDetail(context, tx),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(iconForCategory(category), size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.note.isNotEmpty ? tx.note : category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11, color: context.colors.inkSoft)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(currencyFmt.format(tx.amount),
                style: appAmountTextStyle.copyWith(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
