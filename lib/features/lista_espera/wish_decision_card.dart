import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatting.dart';
import '../../core/utils/projection.dart';
import '../../core/utils/purchase_simulation.dart';
import '../../core/utils/wishlist.dart';
import '../../core/widgets/undo_snack_bar.dart';
import '../../data/local/app_database.dart';
import '../revision/category_worth_hint.dart';
import '../simulador/simulador_screen.dart';
import '../simulador/simulation_inputs.dart';

/// RF62: tarjetas de los deseos cuyo plazo venció, para Resumen. Cada deseo
/// tiene una sola tarjeta, que sigue ahí hasta que el usuario decide.
class DueWishesCards extends ConsumerWidget {
  const DueWishesCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishes = ref.watch(wishlistProvider).valueOrNull;
    if (wishes == null) return const SizedBox.shrink();
    final due = dueWishes(wishes, DateTime.now());
    return Column(
      children: [
        for (final w in due)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: WishDecisionCard(wish: w),
          ),
      ],
    );
  }
}

/// "Hace 7 días", "hace 2 días", "hoy".
String waitedLabel(DateTime createdAt, DateTime now) {
  final days = DateTime(now.year, now.month, now.day)
      .difference(DateTime(createdAt.year, createdAt.month, createdAt.day))
      .inDays;
  if (days <= 0) return 'hoy';
  if (days == 1) return 'ayer';
  return 'hace $days días';
}

/// RF62: un deseo vencido con la simulación recalculada con los datos de hoy
/// y las tres decisiones: comprar, descartar o ahorrar el monto en una meta.
class WishDecisionCard extends ConsumerWidget {
  const WishDecisionCard({super.key, required this.wish});
  final WishlistItem wish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final option = PurchaseOption(wish.amount, wish.installmentCount,
        ratePercent: wish.monthlyRate);
    final projection = simulateWithCurrentData(ref, option, now);
    final goals = ref.watch(savingsGoalsProvider).valueOrNull ?? const [];
    final belowZero =
        projection != null && projectionOutcome(projection).monthsBelowZero > 0;
    final how = option.isCash
        ? 'al contado'
        : 'en ${option.count} cuotas de '
            '${currencyFmt.format(option.installment)}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.paperDeep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.colors.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Todavía quieres "${wish.name}"?',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: context.colors.ink)),
          const SizedBox(height: 4),
          Text(
            'Lo dejaste en espera ${waitedLabel(wish.createdAt, now)} · '
            '${currencyFmt.format(wish.amount)} $how',
            style: TextStyle(fontSize: 13, color: context.colors.inkSoft),
          ),
          // RF68: cómo le ha ido con gastos de esta categoría.
          CategoryWorthHint(categoryId: wish.categoryId),
          if (projection != null) ...[
            const SizedBox(height: 4),
            Text(
              'Con tus datos de hoy: ${outcomeLabel(projection)}',
              style: TextStyle(
                fontSize: 13,
                color: belowZero ? context.colors.rust : context.colors.green,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilledButton(
                style:
                    FilledButton.styleFrom(backgroundColor: context.colors.ink),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => SimuladorScreen(wish: wish))),
                child: const Text('Comprar'),
              ),
              TextButton(
                onPressed: () => discardWish(context, ref, wish),
                child: const Text('Descartar'),
              ),
              if (goals.isNotEmpty)
                TextButton(
                  onPressed: () => saveWishToGoal(context, ref, wish, goals),
                  child: const Text('Ahorrarlo en una meta'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// RF62: descarta el deseo, con aviso para deshacer.
Future<void> discardWish(
    BuildContext context, WidgetRef ref, WishlistItem wish) async {
  final repo = ref.read(wishlistRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);
  await repo.discard(wish.id);
  showUndoSnackBar(messenger,
      message: 'Descartaste "${wish.name}"', onUndo: () => repo.reset(wish.id));
}

/// RF62: descarta el deseo y aporta su monto a la meta que elija el usuario.
Future<void> saveWishToGoal(BuildContext context, WidgetRef ref,
    WishlistItem wish, List<SavingsGoal> goals) async {
  final goal = goals.length == 1
      ? goals.single
      : await showDialog<SavingsGoal>(
          context: context,
          builder: (dialogContext) => SimpleDialog(
            title: Text('¿A qué meta aportas '
                '${currencyFmt.format(wish.amount)}?'),
            children: [
              for (final g in goals)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialogContext, g),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(g.name),
                  ),
                ),
            ],
          ),
        );
  if (goal == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final undo = await ref
      .read(wishlistRepositoryProvider)
      .saveToGoal(wish.id, goalId: goal.id);
  showUndoSnackBar(messenger,
      message: '${currencyFmt.format(wish.amount)} aportados a "${goal.name}"',
      onUndo: undo);
}
