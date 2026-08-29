import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/budget_alert.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/section_label.dart';
import '../../data/local/app_database.dart';
import 'expense_form.dart';

class AgregarScreen extends ConsumerWidget {
  const AgregarScreen({super.key});

  Future<bool> _confirmQuickAdd(
      BuildContext context, QuickExpenseTemplate qa) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.paper,
            title: const Text('Confirmar gasto',
                style: TextStyle(fontSize: 16, color: AppColors.ink)),
            content: Text(
              '${qa.label} — ${currencyFmt.format(qa.amount)}',
              style: const TextStyle(color: AppColors.inkSoft),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar',
                    style: TextStyle(color: AppColors.inkSoft)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Registrar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Devuelve true si el gasto se registró (false si el usuario canceló la
  /// confirmación), para que el chip solo muestre el feedback "✓ Listo"
  /// cuando realmente se agregó algo.
  Future<bool> _handleQuickAdd(
      BuildContext context, WidgetRef ref, QuickExpenseTemplate qa) async {
    final confirmed = await _confirmQuickAdd(context, qa);
    if (!confirmed || !context.mounted) return false;
    final date = DateTime.now();
    await ref.read(transactionsRepositoryProvider).addTransaction(
          categoryId: qa.categoryId,
          amount: qa.amount,
          date: date,
          note: qa.label,
        );
    if (!context.mounted) return true;
    // RF18: aviso inmediato en pantalla si este gasto deja la categoría en
    // 80% o más de su presupuesto del mes.
    final alert =
        await checkBudgetAlert(ref, categoryId: qa.categoryId, date: date);
    if (alert != null && context.mounted) showBudgetAlertBanner(context, alert);
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickTemplatesAsync = ref.watch(quickExpenseTemplatesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Registro rápido'),
            InkWell(
              onTap: () {
                final categories = categoriesAsync.valueOrNull ?? const [];
                if (categories.isEmpty) return;
                _showQuickTemplateEditor(context, ref, categories);
              },
              child: const Icon(Icons.add_circle_outline,
                  size: 18, color: AppColors.inkSoft),
            ),
          ],
        ),
        const SizedBox(height: 8),
        quickTemplatesAsync.when(
          loading: () => const SizedBox(
              height: 64, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Text('Error: $e'),
          data: (templates) {
            if (templates.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Sin accesos rápidos todavía. Toca "+" para crear uno.',
                  style: TextStyle(color: AppColors.inkSoft, fontSize: 12),
                ),
              );
            }
            return SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: templates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final qa = templates[i];
                  return _QuickAddChip(
                    template: qa,
                    onTap: () => _handleQuickAdd(context, ref, qa),
                    onLongPress: () {
                      final categories =
                          categoriesAsync.valueOrNull ?? const [];
                      if (categories.isEmpty) return;
                      _showQuickTemplateEditor(context, ref, categories,
                          template: qa);
                    },
                  );
                },
              ),
            );
          },
        ),
        const Divider(height: 32),
        const SectionLabel('Gasto manual'),
        const SizedBox(height: 12),
        ExpenseForm(
          onSubmit: ({
            required categoryId,
            required amount,
            required date,
            required note,
            required recurring,
          }) async {
            await ref.read(transactionsRepositoryProvider).addTransaction(
                  categoryId: categoryId,
                  amount: amount,
                  date: date,
                  note: note,
                  isRecurring: recurring,
                );
            if (recurring) {
              // RF12: además de registrar el gasto de hoy, crea la plantilla
              // que el catch-up usará los meses siguientes.
              await ref
                  .read(recurringTemplatesRepositoryProvider)
                  .createTemplate(
                    categoryId: categoryId,
                    amount: amount,
                    note: note,
                    dayOfMonth: date.day,
                    initialYearMonth: date.year * 100 + date.month,
                  );
            }
            if (!context.mounted) return;
            // RF18: aviso inmediato en pantalla si este gasto deja la
            // categoría en 80% o más de su presupuesto del mes.
            final alert =
                await checkBudgetAlert(ref, categoryId: categoryId, date: date);
            if (alert != null && context.mounted)
              showBudgetAlertBanner(context, alert);
          },
        ),
      ],
    );
  }
}

/// RF24: crear/editar (o eliminar, si [template] no es null) un acceso
/// rápido de gasto.
Future<void> _showQuickTemplateEditor(
  BuildContext context,
  WidgetRef ref,
  List<Category> categories, {
  QuickExpenseTemplate? template,
}) async {
  final labelController = TextEditingController(text: template?.label ?? '');
  final amountController =
      TextEditingController(text: template?.amount.toString() ?? '');
  var selectedCategoryId = template?.categoryId ?? categories.first.id;

  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text(
          template == null ? 'Nuevo acceso rápido' : 'Editar acceso rápido',
          style: const TextStyle(fontSize: 16, color: AppColors.ink),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: labelController,
                autofocus: true,
                decoration: const InputDecoration(
                    labelText: 'Etiqueta', border: UnderlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixText: '\$ ',
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Categoría',
                  style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories
                    .map((c) => ExpenseCategoryChip(
                          category: c,
                          selected: c.id == selectedCategoryId,
                          onTap: () =>
                              setDialogState(() => selectedCategoryId = c.id),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        actions: [
          if (template != null)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'delete'),
              child: const Text('Eliminar',
                  style: TextStyle(color: AppColors.rust)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.inkSoft)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
            onPressed: () {
              final amount = int.tryParse(amountController.text);
              if (labelController.text.trim().isEmpty ||
                  amount == null ||
                  amount <= 0) {
                return;
              }
              Navigator.pop(ctx, 'save');
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );

  final repo = ref.read(quickExpenseTemplatesRepositoryProvider);
  if (result == 'delete' && template != null) {
    await repo.delete(template.id);
  } else if (result == 'save') {
    final label = labelController.text.trim();
    final amount = int.parse(amountController.text);
    if (template == null) {
      await repo.create(
          label: label, amount: amount, categoryId: selectedCategoryId);
    } else {
      await repo.update(template.id,
          label: label, amount: amount, categoryId: selectedCategoryId);
    }
  }
}

class _QuickAddChip extends StatefulWidget {
  const _QuickAddChip(
      {required this.template, required this.onTap, required this.onLongPress});
  final QuickExpenseTemplate template;
  final Future<bool> Function() onTap;
  final VoidCallback onLongPress;

  @override
  State<_QuickAddChip> createState() => _QuickAddChipState();
}

class _QuickAddChipState extends State<_QuickAddChip> {
  bool _pressed = false;
  bool _justAdded = false;

  Future<void> _handleTap() async {
    final added = await widget.onTap();
    if (!mounted || !added) return;
    setState(() => _justAdded = true);
    await Future.delayed(const Duration(milliseconds: 650));
    if (mounted) setState(() => _justAdded = false);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleTap,
            onLongPress: widget.onLongPress,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _justAdded ? AppColors.green : AppColors.rule,
                ),
                borderRadius: BorderRadius.circular(10),
                color: _justAdded
                    ? AppColors.green.withValues(alpha: 0.15)
                    : AppColors.paperDeep,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _justAdded
                    ? const Row(
                        key: ValueKey('done'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 16, color: AppColors.green),
                          SizedBox(width: 6),
                          Text('Listo',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.green)),
                        ],
                      )
                    : Column(
                        key: const ValueKey('label'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(widget.template.label,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500)),
                          Text(currencyFmt.format(widget.template.amount),
                              style: appAmountTextStyle.copyWith(
                                  fontSize: 11, color: AppColors.inkSoft)),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
