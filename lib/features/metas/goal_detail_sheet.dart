import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/ledger_paper.dart';
import '../../core/widgets/section_label.dart';
import '../../data/local/app_database.dart';
import 'metas_screen.dart' show showGoalEditor;

final _dateFmt = DateFormat('d MMM, HH:mm', 'es_CL');

/// RF14/RF19: aportar manualmente a una meta, usar accesos rápidos de
/// aporte (monto fijo o % del presupuesto mensual total) y administrarlos.
class GoalDetailSheet extends ConsumerStatefulWidget {
  const GoalDetailSheet({super.key, required this.goal});
  final SavingsGoal goal;

  @override
  ConsumerState<GoalDetailSheet> createState() => _GoalDetailSheetState();
}

class _GoalDetailSheetState extends ConsumerState<GoalDetailSheet> {
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _contribute(int amount) async {
    if (amount <= 0) return;
    await ref.read(savingsRepositoryProvider).addContribution(
          goalId: widget.goal.id,
          amount: amount,
          date: DateTime.now(),
        );
    if (!mounted) return;
    _amountController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Aportado — ${currencyFmt.format(amount)}'),
        duration: const Duration(milliseconds: 900),
        backgroundColor: AppColors.ink,
      ),
    );
  }

  Future<int> _resolveQuickAddAmount(SavingsQuickAdd qa) async {
    if (qa.mode == 'fixed') return qa.value;
    // RF04/RF19: "% del presupuesto mensual total" es el total que el
    // usuario fija directamente (MonthlyBudgets), no la suma de
    // presupuestos por categoría.
    final now = DateTime.now();
    final totalBudget =
        ref.read(monthTotalBudgetProvider(DateTime(now.year, now.month)));
    return (totalBudget * qa.value / 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final contributionsAsync =
        ref.watch(goalContributionsProvider(widget.goal.id));
    final quickAddsAsync = ref.watch(goalQuickAddsProvider(widget.goal.id));
    final totals = ref.watch(savingsTotalsProvider).valueOrNull ?? const {};
    final contributed = totals[widget.goal.id] ?? 0;
    final ratio = widget.goal.targetAmount > 0
        ? (contributed / widget.goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            width: 36,
            height: 4,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.rule,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(widget.goal.name,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink)),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 20, color: AppColors.inkSoft),
                onPressed: () =>
                    showGoalEditor(context, ref, goal: widget.goal),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: AppColors.inkSoft),
                onPressed: _confirmDeleteGoal,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LedgerCuadreBar(ratio: ratio, color: AppColors.green),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
              children: [
                TextSpan(
                    text: currencyFmt.format(contributed),
                    style: appAmountTextStyle.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink)),
                TextSpan(
                    text:
                        ' de ${currencyFmt.format(widget.goal.targetAmount)}'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionLabel('Accesos rápidos'),
              IconButton(
                icon: const Icon(Icons.add, size: 18, color: AppColors.inkSoft),
                onPressed: () => _showQuickAddEditor(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          quickAddsAsync.when(
            loading: () => const SizedBox(),
            error: (e, _) => Text('Error: $e'),
            data: (quickAdds) => quickAdds.isEmpty
                ? const Text('Sin accesos rápidos todavía.',
                    style: TextStyle(fontSize: 12, color: AppColors.inkSoft))
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: quickAdds
                        .map((qa) => _QuickAddChip(
                              quickAdd: qa,
                              onTap: () async {
                                final amount = await _resolveQuickAddAmount(qa);
                                await _contribute(amount);
                              },
                              onLongPress: () =>
                                  _showQuickAddEditor(context, quickAdd: qa),
                            ))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 20),
          const SectionLabel('Aporte manual'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: appAmountTextStyle,
                  decoration: const InputDecoration(
                    prefixText: '\$ ',
                    border: UnderlineInputBorder(),
                    hintText: '0',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
                onPressed: () =>
                    _contribute(int.tryParse(_amountController.text) ?? 0),
                child: const Text('Aportar'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionLabel('Historial'),
          const SizedBox(height: 8),
          contributionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (contributions) => contributions.isEmpty
                ? const Text('Sin aportes todavía.',
                    style: TextStyle(fontSize: 12, color: AppColors.inkSoft))
                : Column(
                    children: contributions
                        .map((c) => _ContributionTile(
                              contribution: c,
                              onDelete: () => ref
                                  .read(savingsRepositoryProvider)
                                  .deleteContribution(c.id),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteGoal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: const Text('Eliminar meta',
            style: TextStyle(fontSize: 16, color: AppColors.ink)),
        content: Text(
          '¿Eliminar "${widget.goal.name}"? Se borrará también su historial de aportes.',
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
    if (confirmed == true) {
      await ref.read(savingsRepositoryProvider).deleteGoal(widget.goal.id);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _showQuickAddEditor(BuildContext context,
      {SavingsQuickAdd? quickAdd}) async {
    final labelController = TextEditingController(text: quickAdd?.label ?? '');
    final valueController =
        TextEditingController(text: quickAdd?.value.toString() ?? '');
    var mode = quickAdd?.mode ?? 'fixed';

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.paper,
          title: Text(
              quickAdd == null ? 'Nuevo acceso rápido' : 'Editar acceso rápido',
              style: const TextStyle(fontSize: 16, color: AppColors.ink)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                autofocus: true,
                decoration: const InputDecoration(
                    labelText: 'Etiqueta', border: UnderlineInputBorder()),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'fixed', label: Text('Monto fijo')),
                  ButtonSegment(
                      value: 'percent', label: Text('% del presupuesto')),
                ],
                selected: {mode},
                onSelectionChanged: (s) => setDialogState(() => mode = s.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valueController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: mode == 'fixed' ? 'Monto' : 'Porcentaje',
                  prefixText: mode == 'fixed' ? '\$ ' : null,
                  suffixText: mode == 'percent' ? '%' : null,
                  border: const UnderlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            if (quickAdd != null)
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
                final value = int.tryParse(valueController.text);
                if (labelController.text.trim().isEmpty ||
                    value == null ||
                    value <= 0) {
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

    final repo = ref.read(savingsRepositoryProvider);
    if (result == 'delete' && quickAdd != null) {
      await repo.deleteQuickAdd(quickAdd.id);
    } else if (result == 'save') {
      final label = labelController.text.trim();
      final value = int.parse(valueController.text);
      if (quickAdd == null) {
        await repo.createQuickAdd(
            goalId: widget.goal.id, label: label, mode: mode, value: value);
      } else {
        await repo.updateQuickAdd(quickAdd.id,
            label: label, mode: mode, value: value);
      }
    }
  }
}

class _QuickAddChip extends StatelessWidget {
  const _QuickAddChip(
      {required this.quickAdd, required this.onTap, required this.onLongPress});
  final SavingsQuickAdd quickAdd;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final valueLabel = quickAdd.mode == 'fixed'
        ? currencyFmt.format(quickAdd.value)
        : '${quickAdd.value}%';
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.rule),
          borderRadius: BorderRadius.circular(10),
          color: AppColors.paperDeep,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(quickAdd.label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(valueLabel,
                style: appAmountTextStyle.copyWith(
                    fontSize: 11, color: AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}

class _ContributionTile extends StatelessWidget {
  const _ContributionTile({required this.contribution, required this.onDelete});
  final SavingsContribution contribution;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(contribution.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 12),
        color: AppColors.rust,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(currencyFmt.format(contribution.amount),
            style: appAmountTextStyle.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(_dateFmt.format(contribution.date),
            style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
      ),
    );
  }
}
