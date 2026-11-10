import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatting.dart';
import '../../core/utils/weekly_review.dart';
import '../../core/widgets/section_label.dart';
import '../../data/local/app_database.dart';

/// RF67 (amplía RF44): el gasto no esencial que no valió la pena. Monto y
/// porcentaje de lo revisado, por categoría, su evolución en 6 meses y qué
/// parte se revisó. Los gastos sin revisar se informan aparte. Solo aparece
/// si en esos 6 meses hay algún gasto revisado.
class WorthItSection extends ConsumerWidget {
  const WorthItSection({
    super.key,
    required this.months,
    required this.categoriesById,
  });

  /// Los 6 meses de la tendencia; el último es el mes que se está viendo.
  final List<DateTime> months;
  final Map<String, Category> categoriesById;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(allTransactionsProvider).valueOrNull;
    final essential = ref.watch(essentialResolverProvider);
    if (transactions == null || essential == null) {
      return const SizedBox.shrink();
    }
    final trend = [
      for (final m in months)
        worthItSummary(transactions, m, essential: essential),
    ];
    if (trend.every((s) => s.reviewedCount == 0)) {
      return const SizedBox.shrink();
    }
    final summary = trend.last;
    final entries = summary.notWorthByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final soft = TextStyle(fontSize: 12, color: context.colors.inkSoft);
    final maxNotWorth =
        trend.fold(0, (m, s) => s.notWorthTotal > m ? s.notWorthTotal : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        const SectionLabel(
          '¿Valió la pena?',
          info: 'De tus gastos no esenciales revisados, lo que marcaste como '
              '"no tanto". Lo esencial no se revisa, y los gastos sin revisar '
              'se muestran aparte y no cuentan en el porcentaje.',
        ),
        const SizedBox(height: 12),
        if (summary.reviewedCount == 0)
          Text('Este mes todavía no revisas gastos no esenciales.',
              style: soft.copyWith(fontSize: 13))
        else
          Text.rich(TextSpan(
            style: TextStyle(fontSize: 13, color: context.colors.ink),
            children: [
              TextSpan(
                  text: currencyFmt.format(summary.notWorthTotal),
                  style: appAmountTextStyle.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.colors.rust)),
              TextSpan(
                  text: ' no valieron tanto: el '
                      '${summary.notWorthPercent}% de tu gasto no esencial '
                      'revisado'),
            ],
          )),
        const SizedBox(height: 8),
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(categoriesById[e.key]?.name ?? e.key,
                      style: const TextStyle(fontSize: 13)),
                ),
                Text(currencyFmt.format(e.value),
                    style: appAmountTextStyle.copyWith(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        if (summary.reviewedPercent != null) ...[
          const SizedBox(height: 6),
          Text(
            'Revisaste el ${summary.reviewedPercent}% de tus gastos no '
            'esenciales del mes.'
            '${summary.unreviewedCount == 0 ? '' : ' Sin revisar: ${summary.unreviewedCount == 1 ? '1 gasto' : '${summary.unreviewedCount} gastos'} por ${currencyFmt.format(summary.unreviewedAmount)}.'}',
            style: soft,
          ),
        ],
        const SizedBox(height: 16),
        Text('Últimos 6 meses', style: soft),
        const SizedBox(height: 6),
        for (final s in trend) _TrendRow(summary: s, maxAmount: maxNotWorth),
      ],
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.summary, required this.maxAmount});
  final WorthItSummary summary;
  final int maxAmount;

  @override
  Widget build(BuildContext context) {
    final label = capitalizeMonth(summary.month, monthShortFmt);
    final percent = summary.notWorthPercent;
    final value = percent == null
        ? 'sin revisar'
        : '${currencyFmt.format(summary.notWorthTotal)} · $percent%';
    return Semantics(
      label: '$label: $value',
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
                        : constraints.maxWidth *
                            summary.notWorthTotal /
                            maxAmount,
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
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: appAmountTextStyle.copyWith(
                      fontSize: 12, color: context.colors.ink)),
            ),
          ],
        ),
      ),
    );
  }
}
