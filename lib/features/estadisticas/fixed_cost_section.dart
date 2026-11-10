import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/fixed_costs.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/section_label.dart';

/// RF64: costo de vida fijo del mes (pagos fijos, cuotas y gastos
/// habituales), su peso en el presupuesto total, su evolución en 6 meses y
/// las cuotas ya comprometidas para los 6 siguientes.
class FixedCostSection extends ConsumerWidget {
  const FixedCostSection({super.key, required this.months});

  /// Los 6 meses de la tendencia; el último es el mes que se está viendo.
  final List<DateTime> months;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(allTransactionsProvider).valueOrNull;
    final templates = ref.watch(recurringTemplatesProvider).valueOrNull;
    final habitualIds = ref.watch(habitualTransactionIdsProvider).valueOrNull;
    if (transactions == null || templates == null || habitualIds == null) {
      return const SizedBox.shrink();
    }
    final today = DateTime.now();
    final trend = fixedCostTrend(
      months: months,
      today: today,
      transactions: transactions,
      templates: templates,
      habitualTransactionIds: habitualIds,
    );
    final upcoming = committedInstallments(transactions, months.last);
    if (trend.every((c) => c.total == 0) &&
        upcoming.every((u) => u.amount == 0)) {
      return const SizedBox.shrink();
    }
    final viewed = trend.last;
    final budget = ref.watch(monthTotalBudgetProvider(viewed.month));
    final percent = viewed.percentOf(budget);
    final soft = TextStyle(fontSize: 12, color: context.colors.inkSoft);
    final maxTotal = trend.fold(0, (m, c) => c.total > m ? c.total : m);
    final maxUpcoming = upcoming.fold(0, (m, u) => u.amount > m ? u.amount : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        const SectionLabel(
          'Costo de vida fijo',
          info: 'Lo que el mes ya trae comprometido: pagos fijos, cuotas y '
              'gastos habituales. En el mes en curso, los habituales son los '
              'esperados según sus días; en los meses pasados, lo que '
              'registraste.',
        ),
        const SizedBox(height: 12),
        Semantics(
          label: 'Costo fijo de ${capitalizeMonth(viewed.month, monthFmt)}: '
              '${currencyFmt.format(viewed.total)}'
              '${percent == null ? '' : ', $percent% de tu presupuesto total'}',
          excludeSemantics: true,
          child: Text.rich(TextSpan(
            style: TextStyle(fontSize: 13, color: context.colors.ink),
            children: [
              TextSpan(
                  text: currencyFmt.format(viewed.total),
                  style: appAmountTextStyle.copyWith(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              TextSpan(
                  text: percent == null
                      ? ' al mes'
                      : ' al mes · $percent% de tu presupuesto total'),
              if (viewed.expected) const TextSpan(text: ' (estimado)'),
            ],
          )),
        ),
        const SizedBox(height: 8),
        _ComponentRow(
            label: 'Pagos fijos',
            amount: viewed.recurring,
            color: context.colors.ink),
        _ComponentRow(
            label: 'Cuotas',
            amount: viewed.installments,
            color: context.colors.rust),
        _ComponentRow(
            label: 'Gastos habituales',
            amount: viewed.habitual,
            color: context.colors.green),
        const SizedBox(height: 16),
        Text('Últimos 6 meses', style: soft),
        const SizedBox(height: 6),
        for (final c in trend)
          _TrendBar(
              cost: c,
              maxTotal: maxTotal,
              budget: ref.watch(monthTotalBudgetProvider(c.month))),
        const SizedBox(height: 16),
        Text('Cuotas ya comprometidas', style: soft),
        const SizedBox(height: 6),
        if (upcoming.every((u) => u.amount == 0))
          Text('No tienes cuotas en los próximos 6 meses.', style: soft)
        else
          for (final u in upcoming)
            _UpcomingRow(
                month: u.month, amount: u.amount, maxAmount: maxUpcoming),
      ],
    );
  }
}

class _ComponentRow extends StatelessWidget {
  const _ComponentRow(
      {required this.label, required this.amount, required this.color});
  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
            Text(currencyFmt.format(amount),
                style: appAmountTextStyle.copyWith(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

/// Una barra apilada por mes: pagos fijos, cuotas y habituales, con el
/// total (y su porcentaje del presupuesto, si hay) a la derecha.
class _TrendBar extends StatelessWidget {
  const _TrendBar(
      {required this.cost, required this.maxTotal, required this.budget});
  final FixedCost cost;
  final int maxTotal;
  final int budget;

  @override
  Widget build(BuildContext context) {
    final label = capitalizeMonth(cost.month, monthShortFmt);
    final percent = cost.percentOf(budget);
    final value = '${currencyFmt.format(cost.total)}'
        '${percent == null ? '' : ' · $percent%'}';
    final parts = [
      (cost.recurring, context.colors.ink),
      (cost.installments, context.colors.rust),
      (cost.habitual, context.colors.green),
    ];
    return Semantics(
      label: '$label: $value. Pagos fijos '
          '${currencyFmt.format(cost.recurring)}, cuotas '
          '${currencyFmt.format(cost.installments)}, habituales '
          '${currencyFmt.format(cost.habitual)}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(label,
                  style:
                      TextStyle(fontSize: 12, color: context.colors.inkSoft)),
            ),
            Expanded(
              child: LayoutBuilder(builder: (context, constraints) {
                final width = maxTotal == 0
                    ? 0.0
                    : constraints.maxWidth * cost.total / maxTotal;
                return Align(
                  alignment: Alignment.centerLeft,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      width: width,
                      height: 14,
                      child: Row(
                        children: [
                          for (final (amount, color) in parts)
                            if (amount > 0)
                              Expanded(
                                flex: amount,
                                child: ColoredBox(color: color),
                              ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: appAmountTextStyle.copyWith(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow(
      {required this.month, required this.amount, required this.maxAmount});
  final DateTime month;
  final int amount;
  final int maxAmount;

  @override
  Widget build(BuildContext context) {
    final label = capitalizeMonth(month, monthShortFmt);
    return Semantics(
      label: '$label: ${currencyFmt.format(amount)} en cuotas',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(label,
                  style:
                      TextStyle(fontSize: 12, color: context.colors.inkSoft)),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: maxAmount == 0
                        ? 0
                        : constraints.maxWidth * amount / maxAmount,
                    height: 14,
                    decoration: BoxDecoration(
                      color: context.colors.rust,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: Text(currencyFmt.format(amount),
                  textAlign: TextAlign.right,
                  style: appAmountTextStyle.copyWith(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
