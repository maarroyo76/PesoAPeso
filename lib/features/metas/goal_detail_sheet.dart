import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/amount_input.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/ledger_paper.dart';
import '../../core/widgets/section_label.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/undo_snack_bar.dart';
import '../../data/local/app_database.dart';
import '../categorias/category_filters.dart';
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

  /// Messenger propio de la hoja: sus avisos (y el "Deshacer") deben verse
  /// sobre ella, no detrás en la pantalla de la app.
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  ScaffoldMessengerState get _messenger =>
      _messengerKey.currentState ?? ScaffoldMessenger.of(context);

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _showError(String text) {
    _messenger.showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(milliseconds: 1800),
        backgroundColor: context.colors.rust,
      ),
    );
  }

  Future<void> _contribute(int amount) async {
    if (amount <= 0) {
      _showError(kInvalidAmountMessage);
      return;
    }
    await ref.read(savingsRepositoryProvider).addContribution(
          goalId: widget.goal.id,
          amount: amount,
          date: DateTime.now(),
        );
    if (!mounted) return;
    _amountController.clear();
    _messenger.showSnackBar(
      SnackBar(
        content: Text('Aportado — ${currencyFmt.format(amount)}'),
        duration: const Duration(milliseconds: 900),
        backgroundColor: context.colors.ink,
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

  /// La meta viva desde la base (el widget solo trae una copia al abrir el
  /// sheet, que queda vieja tras editarla).
  SavingsGoal get _goal {
    final goals = ref.watch(savingsGoalsProvider).valueOrNull ?? const [];
    for (final g in goals) {
      if (g.id == widget.goal.id) return g;
    }
    return widget.goal;
  }

  @override
  Widget build(BuildContext context) {
    final goal = _goal;
    final contributionsAsync =
        ref.watch(goalContributionsProvider(widget.goal.id));
    final quickAddsAsync = ref.watch(goalQuickAddsProvider(widget.goal.id));
    final totals = ref.watch(savingsTotalsProvider).valueOrNull ?? const {};
    final contributed = totals[widget.goal.id] ?? 0;
    final ratio = goal.targetAmount > 0
        ? (contributed / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => ScaffoldMessenger(
        key: _messengerKey,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          body: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 36,
                height: 4,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.rule,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(goal.name,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: context.colors.ink)),
                  ),
                  IconButton(
                    tooltip: 'Editar meta',
                    icon: Icon(Icons.edit_outlined,
                        size: 20, color: context.colors.inkSoft),
                    onPressed: () => showGoalEditor(context, ref, goal: goal),
                  ),
                  IconButton(
                    tooltip: 'Eliminar meta',
                    icon: Icon(Icons.delete_outline,
                        size: 20, color: context.colors.inkSoft),
                    onPressed: _confirmDeleteGoal,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LedgerCuadreBar(
                ratio: ratio,
                color: context.colors.green,
                semanticsLabel: 'Avance de ${goal.name}',
                semanticsValue:
                    goalProgressSemantics(contributed, goal.targetAmount),
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  style: TextStyle(fontSize: 12, color: context.colors.inkSoft),
                  children: [
                    TextSpan(
                        text: currencyFmt.format(contributed),
                        style: appAmountTextStyle.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.colors.ink)),
                    TextSpan(
                        text: ' de ${currencyFmt.format(goal.targetAmount)}'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SectionLabel('Accesos rápidos'),
                  IconButton(
                    tooltip: 'Nuevo acceso rápido de aporte',
                    icon: Icon(Icons.add,
                        size: 18, color: context.colors.inkSoft),
                    onPressed: () => _showQuickAddEditor(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              quickAddsAsync.when(
                loading: () => const SizedBox(),
                error: (e, _) => LoadError(e, compact: true),
                data: (quickAdds) => quickAdds.isEmpty
                    ? Text('Sin accesos rápidos todavía.',
                        style: TextStyle(
                            fontSize: 12, color: context.colors.inkSoft))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: quickAdds
                            .map((qa) => _QuickAddChip(
                                  quickAdd: qa,
                                  onTap: () async {
                                    final amount =
                                        await _resolveQuickAddAmount(qa);
                                    if (amount <= 0 && qa.mode == 'percent') {
                                      _showError(
                                          'Define primero el presupuesto total del mes en Presupuestos.');
                                      return;
                                    }
                                    await _contribute(amount);
                                  },
                                  onLongPress: () => _showQuickAddEditor(
                                      context,
                                      quickAdd: qa),
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
                      inputFormatters: amountInputFormatters,
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
                    style: FilledButton.styleFrom(
                        backgroundColor: context.colors.ink),
                    onPressed: () => _contribute(
                        parseAmountText(_amountController.text) ?? 0),
                    child: const Text('Aportar'),
                  ),
                ],
              ),
              // RF52 (corrige I3): pagar un gasto con lo ahorrado.
              if (contributed > 0) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                    label: const Text('Usar ahorro'),
                    onPressed: () => _useSavings(contributed),
                  ),
                ),
              ],
              ..._goalSpending(),
              const SizedBox(height: 24),
              const SectionLabel('Historial'),
              const SizedBox(height: 8),
              contributionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => LoadError(e, compact: true),
                data: (contributions) => contributions.isEmpty
                    ? Text('Sin aportes todavía.',
                        style: TextStyle(
                            fontSize: 12, color: context.colors.inkSoft))
                    : Column(
                        children: contributions
                            .map((c) => _ContributionTile(
                                  contribution: c,
                                  onDelete: () => _deleteContribution(c),
                                ))
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// RF52: gastos ya pagados con el ahorro de esta meta.
  List<Widget> _goalSpending() {
    final spending =
        ref.watch(goalSpendingProvider(widget.goal.id)).valueOrNull ?? [];
    if (spending.isEmpty) return const [];
    final categories = {
      for (final c in ref.watch(categoriesProvider).valueOrNull ?? <Category>[])
        c.id: c.name
    };
    return [
      const SizedBox(height: 24),
      const SectionLabel('Usado del ahorro'),
      const SizedBox(height: 8),
      for (final t in spending)
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text('−${currencyFmt.format(t.amount)}',
              style: appAmountTextStyle.copyWith(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text(
            [
              categories[t.categoryId] ?? t.categoryId,
              if (t.note.isNotEmpty) t.note,
              _dateFmt.format(t.date),
            ].join(' · '),
            style: TextStyle(fontSize: 12, color: context.colors.inkSoft),
          ),
        ),
    ];
  }

  /// RF52: registra un gasto pagado con el ahorro de la meta. Descuenta del
  /// saldo de la meta y no del presupuesto del mes; no puede superar
  /// [balance].
  Future<void> _useSavings(int balance) async {
    final categories = selectableCategories(
        ref.read(categoriesProvider).valueOrNull ?? const <Category>[]);
    if (categories.isEmpty) return;
    final amountController = TextEditingController();
    final noteController = TextEditingController(text: _goal.name);
    var categoryId = categories.first.id;
    String? amountError;

    final amount = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: context.colors.paper,
          title: Text('Usar ahorro de "${_goal.name}"',
              style: TextStyle(fontSize: 16, color: context.colors.ink)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'El gasto se registra en su categoría, pero sale de esta '
                  'meta y no del presupuesto del mes. Saldo: '
                  '${currencyFmt.format(balance)}.',
                  style: TextStyle(fontSize: 13, color: context.colors.inkSoft),
                ),
                TextField(
                  controller: amountController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: amountInputFormatters,
                  decoration: InputDecoration(
                    labelText: 'Monto',
                    prefixText: '\$ ',
                    errorText: amountError,
                  ),
                ),
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
                  maxLength: kMaxNameLength,
                  decoration: const InputDecoration(labelText: 'Nota'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: TextStyle(color: context.colors.inkSoft)),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(backgroundColor: context.colors.ink),
              onPressed: () {
                final value = parseAmountText(amountController.text) ?? 0;
                if (value <= 0) {
                  setDialogState(() => amountError = kInvalidAmountMessage);
                } else if (value > balance) {
                  setDialogState(() => amountError =
                      'Solo hay ${currencyFmt.format(balance)} en esta meta');
                } else {
                  Navigator.pop(ctx, value);
                }
              },
              child: const Text('Registrar gasto'),
            ),
          ],
        ),
      ),
    );
    if (amount == null || !mounted) return;
    final txId = await ref.read(savingsRepositoryProvider).spendFromGoal(
          goalId: _goal.id,
          categoryId: categoryId,
          amount: amount,
          date: DateTime.now(),
          note: noteController.text.trim(),
        );
    if (!mounted) return;
    showUndoSnackBar(_messenger,
        message: 'Gasto de ${currencyFmt.format(amount)} pagado con ahorro',
        onUndo: () =>
            ref.read(transactionsRepositoryProvider).deleteTransaction(txId));
  }

  /// UX02: el aporte se borra al deslizar y el aviso permite deshacerlo.
  Future<void> _deleteContribution(SavingsContribution c) async {
    final undo = await ref
        .read(savingsRepositoryProvider)
        .deleteContributionUndoable(c.id);
    if (!mounted) return;
    showUndoSnackBar(_messenger,
        message: 'Aporte de ${currencyFmt.format(c.amount)} eliminado',
        onUndo: undo);
  }

  Future<void> _confirmDeleteGoal() async {
    // RF52: avisar que lo pagado con su ahorro vuelve al presupuesto del mes.
    final usedSavings =
        (ref.read(goalSpendingProvider(_goal.id)).valueOrNull ?? const [])
            .isNotEmpty;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.paper,
        title: Text('Eliminar meta',
            style: TextStyle(fontSize: 16, color: context.colors.ink)),
        content: Text(
          '¿Eliminar "${_goal.name}"? Se borrará también su historial de '
          'aportes.'
          '${usedSavings ? ' Los gastos pagados con su ahorro se conservan, '
              'pero pasan a contar en el presupuesto de su mes.' : ''}',
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
    if (confirmed == true) {
      await ref.read(savingsRepositoryProvider).deleteGoal(widget.goal.id);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _showQuickAddEditor(BuildContext context,
      {SavingsQuickAdd? quickAdd}) async {
    final labelController = TextEditingController(text: quickAdd?.label ?? '');
    final valueController = TextEditingController(
        text: quickAdd == null
            ? ''
            : (quickAdd.mode == 'fixed'
                ? formatAmountInput(quickAdd.value)
                : quickAdd.value.toString()));
    var mode = quickAdd?.mode ?? 'fixed';
    String? labelError;
    String? valueError;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: context.colors.paper,
          title: Text(
              quickAdd == null ? 'Nuevo acceso rápido' : 'Editar acceso rápido',
              style: TextStyle(fontSize: 16, color: context.colors.ink)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                autofocus: true,
                maxLength: kMaxNameLength,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                    labelText: 'Etiqueta',
                    errorText: labelError,
                    border: const UnderlineInputBorder()),
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
                inputFormatters: mode == 'percent'
                    ? percentInputFormatters
                    : amountInputFormatters,
                decoration: InputDecoration(
                  errorText: valueError,
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
                child: Text('Eliminar',
                    style: TextStyle(color: context.colors.rust)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text('Cancelar',
                  style: TextStyle(color: context.colors.inkSoft)),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(backgroundColor: context.colors.ink),
              onPressed: () {
                final value = parsePositiveAmount(valueController.text);
                final labelEmpty = labelController.text.trim().isEmpty;
                final percentTooHigh =
                    mode == 'percent' && value != null && value > 100;
                if (labelEmpty || value == null || percentTooHigh) {
                  setDialogState(() {
                    labelError = labelEmpty ? 'Escribe una etiqueta' : null;
                    valueError = value == null
                        ? 'Ingresa un valor mayor a 0'
                        : (percentTooHigh ? 'Máximo 100%' : null);
                  });
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
      final value = parseAmountText(valueController.text)!;
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
    // UX08: anuncia que mantener presionado edita el acceso rápido.
    return Semantics(
      onLongPressHint: 'editar',
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: context.colors.rule),
            borderRadius: BorderRadius.circular(10),
            color: context.colors.paperDeep,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(quickAdd.label,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(valueLabel,
                  style: appAmountTextStyle.copyWith(
                      fontSize: 11, color: context.colors.inkSoft)),
            ],
          ),
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
    return Semantics(
      // UX08: deslizar no está disponible con lector de pantalla; la misma
      // acción se ofrece en el menú de acciones de TalkBack / VoiceOver.
      customSemanticsActions: {
        const CustomSemanticsAction(label: 'Eliminar'): onDelete,
      },
      child: Dismissible(
        key: ValueKey(contribution.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 12),
          color: context.colors.rust,
          child: Icon(Icons.delete_outline, color: context.colors.paper),
        ),
        onDismissed: (_) => onDelete(),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(currencyFmt.format(contribution.amount),
              style: appAmountTextStyle.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(_dateFmt.format(contribution.date),
              style: TextStyle(fontSize: 11, color: context.colors.inkSoft)),
        ),
      ),
    );
  }
}
