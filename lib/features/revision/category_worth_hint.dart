import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/weekly_review.dart';

/// RF68: cuántos de los gastos revisados de la categoría de una compra no
/// valieron tanto en los últimos 3 meses. No muestra nada sin categoría o con
/// menos de 5 gastos revisados en ella.
class CategoryWorthHint extends ConsumerWidget {
  const CategoryWorthHint({super.key, required this.categoryId, this.today});

  final String? categoryId;

  /// Fecha de referencia; solo para tests. Por defecto, ahora.
  final DateTime? today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = categoryId;
    if (id == null) return const SizedBox.shrink();
    final transactions = ref.watch(allTransactionsProvider).valueOrNull;
    final essential = ref.watch(essentialResolverProvider);
    if (transactions == null || essential == null) {
      return const SizedBox.shrink();
    }
    final rate = categoryNotWorthRate(transactions, id, today ?? DateTime.now(),
        essential: essential);
    if (rate == null) return const SizedBox.shrink();
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final name = categories.where((c) => c.id == id).firstOrNull?.name ?? id;
    final color =
        rate.notWorth == 0 ? context.colors.inkSoft : context.colors.rust;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.history, size: 16, color: color),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'En los últimos $kCategoryRateMonths meses, ${rate.notWorth} de '
              'tus ${rate.reviewed} gastos revisados en $name no valieron '
              'tanto (${rate.percent}%).',
              style: TextStyle(fontSize: 13, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
