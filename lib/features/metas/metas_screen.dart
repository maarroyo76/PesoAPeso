import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/amount_input.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/ledger_paper.dart';
import '../../core/widgets/load_error.dart';
import '../../data/local/app_database.dart';
import 'goal_detail_sheet.dart';

/// RF13/RF14: metas de ahorro — verlas y aportar manualmente.
class MetasScreen extends ConsumerWidget {
  const MetasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalsProvider);
    final totalsAsync = ref.watch(savingsTotalsProvider);

    return Scaffold(
      backgroundColor: context.colors.paper,
      body: SafeArea(
        child: goalsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => LoadError(e),
          data: (goals) {
            final totals = totalsAsync.valueOrNull ?? const {};
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('Metas de ahorro',
                          style: Theme.of(context).textTheme.headlineMedium),
                    ),
                    IconButton(
                      tooltip: 'Nueva meta',
                      icon: const Icon(Icons.add_circle_outline),
                      color: context.colors.ink,
                      onPressed: () => showGoalEditor(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (goals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Todavía no tienes metas de ahorro. Toca "+" para crear una.',
                      style: TextStyle(
                          color: context.colors.inkSoft, fontSize: 13),
                    ),
                  )
                else
                  ...goals.map((g) => _GoalCard(
                        goal: g,
                        contributed: totals[g.id] ?? 0,
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: context.colors.paper,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (_) => GoalDetailSheet(goal: g),
                        ),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }
}

Future<void> showGoalEditor(BuildContext context, WidgetRef ref,
    {SavingsGoal? goal}) async {
  final nameController = TextEditingController(text: goal?.name ?? '');
  final targetController = TextEditingController(
      text: goal == null ? '' : formatAmountInput(goal.targetAmount));

  String? nameError;
  String? targetError;

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: context.colors.paper,
        title: Text(goal == null ? 'Nueva meta' : 'Editar meta',
            style: TextStyle(fontSize: 16, color: context.colors.ink)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              maxLength: kMaxGoalNameLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                  labelText: 'Nombre',
                  errorText: nameError,
                  border: const UnderlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              inputFormatters: amountInputFormatters,
              decoration: InputDecoration(
                  labelText: 'Monto objetivo',
                  prefixText: '\$ ',
                  errorText: targetError,
                  border: const UnderlineInputBorder()),
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
            style: FilledButton.styleFrom(backgroundColor: context.colors.ink),
            onPressed: () {
              final target = parsePositiveAmount(targetController.text);
              final nameEmpty = nameController.text.trim().isEmpty;
              if (nameEmpty || target == null) {
                setDialogState(() {
                  nameError = nameEmpty ? 'Escribe un nombre' : null;
                  targetError = target == null ? kInvalidAmountMessage : null;
                });
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );

  if (result != true) return;
  final name = nameController.text.trim();
  final target = parseAmountText(targetController.text)!;
  final repo = ref.read(savingsRepositoryProvider);
  if (goal == null) {
    await repo.createGoal(name: name, targetAmount: target);
  } else {
    await repo.updateGoal(goal.id, name: name, targetAmount: target);
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard(
      {required this.goal, required this.contributed, required this.onTap});
  final SavingsGoal goal;
  final int contributed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = goal.targetAmount > 0
        ? (contributed / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final complete = contributed >= goal.targetAmount && goal.targetAmount > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.paperDeep,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colors.rule),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(goal.name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                  if (complete)
                    Icon(Icons.emoji_events_outlined,
                        size: 18, color: context.colors.green),
                ],
              ),
              const SizedBox(height: 10),
              LedgerCuadreBar(
                ratio: ratio,
                color: complete ? context.colors.green : context.colors.ink,
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
            ],
          ),
        ),
      ),
    );
  }
}
