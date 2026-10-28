import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/amount_input.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/load_error.dart';
import '../../data/local/app_database.dart';
import '../metodos_pago/payment_method_labels.dart';
import '../categorias/category_filters.dart';

final _dayFmt = DateFormat('d MMM yyyy', 'es_CL');

/// Fin del día de hoy: una cuota con fecha anterior ya se cargó (pagada).
DateTime _endOfToday() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + 1);
}

/// Estado de un plan calculado desde sus gastos.
class _PlanStatus {
  _PlanStatus(this.plan, List<Transaction> all)
      : rows = all.where((t) => t.installmentPlanId == plan.id).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

  final InstallmentPlan plan;
  final List<Transaction> rows;

  late final _end = _endOfToday();
  Iterable<Transaction> get paid => rows.where((t) => t.date.isBefore(_end));
  Iterable<Transaction> get pending =>
      rows.where((t) => !t.date.isBefore(_end));
  int get pendingAmount => pending.fold(0, (a, t) => a + t.amount);
  int get paidInstallments =>
      paid.where((t) => t.installmentNumber != null).length;
}

String _planTitle(InstallmentPlan plan, Map<String, Category> categoriesById) =>
    plan.note.isNotEmpty
        ? plan.note
        : categoriesById[plan.categoryId]?.name ?? 'Compra en cuotas';

/// RF35: compras en cuotas, con lo pagado y lo pendiente de cada una.
class CuotasScreen extends ConsumerWidget {
  const CuotasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(installmentPlansProvider);
    final txs = ref.watch(installmentTransactionsProvider).valueOrNull ?? [];
    final categoriesById = {
      for (final c in ref.watch(categoriesProvider).valueOrNull ?? <Category>[])
        c.id: c
    };
    final methodsById =
        paymentMethodsById(ref.watch(paymentMethodsProvider).valueOrNull);

    return Scaffold(
      backgroundColor: context.colors.paper,
      appBar: AppBar(title: const Text('Compras en cuotas')),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => LoadError(e),
        data: (plans) => plans.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Aún no tienes compras en cuotas. Para registrar una, en '
                  'Agregar elige una tarjeta de crédito como método de pago e '
                  'indica el número de cuotas.',
                  style: TextStyle(fontSize: 13, color: context.colors.inkSoft),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: plans.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 20),
                itemBuilder: (context, i) {
                  final status = _PlanStatus(plans[i], txs);
                  final plan = status.plan;
                  final method = methodsById[plan.paymentMethodId];
                  final state = plan.prepaid
                      ? 'Prepagada'
                      : status.pending.isEmpty
                          ? 'Pagada'
                          : '${status.paidInstallments} de '
                              '${plan.installmentCount} pagadas · quedan '
                              '${currencyFmt.format(status.pendingAmount)}';
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    title: Text(_planTitle(plan, categoriesById),
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(
                      [
                        if (method != null) paymentMethodLabel(method),
                        state,
                      ].join(' · '),
                      style: TextStyle(
                          fontSize: 12, color: context.colors.inkSoft),
                    ),
                    trailing: Text(
                      currencyFmt.format(plan.totalAmount),
                      style: appAmountTextStyle.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.colors.ink),
                    ),
                    onTap: () => showInstallmentPlanSheet(context, plan.id),
                  );
                },
              ),
      ),
    );
  }
}

/// RF35: detalle de un plan de cuotas.
Future<void> showInstallmentPlanSheet(BuildContext context, int planId) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PlanSheet(planId: planId),
    );

class _PlanSheet extends ConsumerWidget {
  const _PlanSheet({required this.planId});
  final int planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref
        .watch(installmentPlansProvider)
        .valueOrNull
        ?.where((p) => p.id == planId)
        .firstOrNull;
    // El plan se eliminó (o aún no carga).
    if (plan == null) return const SizedBox(height: 120);
    final status = _PlanStatus(
        plan, ref.watch(installmentTransactionsProvider).valueOrNull ?? []);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final categoriesById = {for (final c in categories) c.id: c};
    final method = paymentMethodsById(
        ref.watch(paymentMethodsProvider).valueOrNull)[plan.paymentMethodId];
    final end = _endOfToday();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(_planTitle(plan, categoriesById),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.colors.ink)),
          const SizedBox(height: 4),
          Text(
            [
              currencyFmt.format(plan.totalAmount),
              '${plan.installmentCount} cuotas',
              if (method != null) paymentMethodLabel(method),
              'comprada el ${_dayFmt.format(plan.purchaseDate)}',
            ].join(' · '),
            style: TextStyle(fontSize: 13, color: context.colors.inkSoft),
          ),
          const SizedBox(height: 4),
          Text(
            status.pending.isEmpty
                ? (plan.prepaid ? 'Prepagada' : 'Todas las cuotas pagadas')
                : 'Quedan ${currencyFmt.format(status.pendingAmount)} '
                    'en ${status.pending.length} cuotas',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.colors.ink),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _editPlan(context, ref, plan, categories),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar'),
              ),
              if (status.pending.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _confirmPrepay(context, ref, status),
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('Prepagar'),
                ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    foregroundColor: context.colors.rust),
                onPressed: () => _confirmDelete(context, ref, plan),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Eliminar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final t in status.rows)
            Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: context.colors.rule)),
              ),
              child: Row(
                children: [
                  Icon(
                    t.date.isBefore(end)
                        ? Icons.check_circle_outline
                        : Icons.schedule,
                    size: 18,
                    color: t.date.isBefore(end)
                        ? context.colors.green
                        : context.colors.inkSoft,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.installmentNumber == null
                              ? 'Prepago'
                              : 'Cuota ${t.installmentNumber} de '
                                  '${plan.installmentCount}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${_dayFmt.format(t.date)} · '
                          '${t.date.isBefore(end) ? 'Pagada' : 'Pendiente'}',
                          style: TextStyle(
                              fontSize: 11, color: context.colors.inkSoft),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    currencyFmt.format(t.amount),
                    style: appAmountTextStyle.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.colors.ink),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _editPlan(BuildContext context, WidgetRef ref,
      InstallmentPlan plan, List<Category> categories) async {
    categories = selectableCategories(categories, keep: plan.categoryId);
    final noteController = TextEditingController(text: plan.note);
    var categoryId = plan.categoryId;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: context.colors.paper,
          title: Text('Editar compra en cuotas',
              style: TextStyle(fontSize: 16, color: context.colors.ink)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: categoryId,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: [
                  for (final c in categories)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setDialogState(() => categoryId = v!),
              ),
              TextField(
                controller: noteController,
                maxLength: kMaxNoteLength,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nota'),
              ),
              Text(
                'El cambio se aplica a todas las cuotas. Para cambiar el monto '
                'o el número de cuotas, elimina la compra y regístrala de nuevo.',
                style: TextStyle(fontSize: 12, color: context.colors.inkSoft),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar',
                  style: TextStyle(color: context.colors.inkSoft)),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(backgroundColor: context.colors.ink),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    await ref.read(installmentsRepositoryProvider).updatePlanInfo(plan.id,
        categoryId: categoryId, note: noteController.text.trim());
  }

  Future<void> _confirmPrepay(
      BuildContext context, WidgetRef ref, _PlanStatus status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.paper,
        title: Text('Prepagar compra',
            style: TextStyle(fontSize: 16, color: context.colors.ink)),
        content: Text(
          'Las ${status.pending.length} cuotas pendientes se reemplazan por un '
          'solo gasto de hoy por ${currencyFmt.format(status.pendingAmount)}, '
          'que cuenta en el presupuesto de este mes. Las cuotas ya pagadas '
          'no cambian.',
          style: TextStyle(color: context.colors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TextStyle(color: context.colors.inkSoft)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.colors.ink),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Prepagar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(installmentsRepositoryProvider).prepay(status.plan.id);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, InstallmentPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.paper,
        title: Text('Eliminar compra en cuotas',
            style: TextStyle(fontSize: 16, color: context.colors.ink)),
        content: Text(
          'Se eliminan sus ${plan.installmentCount} cuotas, también las ya '
          'pagadas. Esta acción no se puede deshacer.',
          style: TextStyle(color: context.colors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TextStyle(color: context.colors.inkSoft)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.colors.rust),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(installmentsRepositoryProvider).deletePlan(plan.id);
    if (context.mounted) Navigator.of(context).pop();
  }
}
