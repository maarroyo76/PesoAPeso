import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatting.dart';
import '../../core/utils/weekly_review.dart';
import '../../core/widgets/section_label.dart';
import '../../data/local/app_database.dart';

/// RF44: cuánto del mes se marcó "no tanto" en la revisión semanal (RF37),
/// por categoría. Solo aparece si el mes tiene algún gasto revisado.
class WorthItSection extends StatelessWidget {
  const WorthItSection({
    super.key,
    required this.transactions,
    required this.categoriesById,
  });

  final List<Transaction> transactions;
  final Map<String, Category> categoriesById;

  @override
  Widget build(BuildContext context) {
    final summary = worthItSummary(transactions);
    if (summary.reviewedCount == 0) return const SizedBox.shrink();
    final entries = summary.notWorthByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final soft = TextStyle(fontSize: 12, color: context.colors.inkSoft);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        const SectionLabel(
          '¿Valió la pena?',
          info: 'Lo que marcaste como "no tanto" en la revisión semanal, por '
              'categoría. Los gastos que no has revisado se muestran aparte.',
        ),
        const SizedBox(height: 12),
        Text.rich(TextSpan(
          style: TextStyle(fontSize: 13, color: context.colors.ink),
          children: [
            TextSpan(
                text: currencyFmt.format(summary.notWorthTotal),
                style: appAmountTextStyle.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.colors.rust)),
            const TextSpan(text: ' en gastos que no valieron tanto'),
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
        if (summary.unreviewedCount > 0) ...[
          const SizedBox(height: 6),
          Text(
            summary.unreviewedCount == 1
                ? 'Sin revisar: 1 gasto por '
                    '${currencyFmt.format(summary.unreviewedAmount)}.'
                : 'Sin revisar: ${summary.unreviewedCount} gastos por '
                    '${currencyFmt.format(summary.unreviewedAmount)}.',
            style: soft,
          ),
        ],
      ],
    );
  }
}
