import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatting.dart';
import '../../core/utils/wishlist.dart';
import '../../core/widgets/section_label.dart';

/// RF63: qué pasó con la lista de espera en el mes que se está viendo.
/// No aparece hasta que el usuario haya dejado algo en espera.
class WishlistStatsSection extends ConsumerWidget {
  const WishlistStatsSection({super.key, required this.month});
  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishes = ref.watch(wishlistProvider).valueOrNull;
    if (wishes == null) return const SizedBox.shrink();
    final end = DateTime(month.year, month.month + 1);
    if (!wishes.any((w) => w.createdAt.isBefore(end))) {
      return const SizedBox.shrink();
    }
    final s = wishlistMonthStats(wishes, month);
    final soft = TextStyle(fontSize: 13, color: context.colors.inkSoft);
    final big = appAmountTextStyle.copyWith(
        fontSize: 15, fontWeight: FontWeight.w700, color: context.colors.green);

    String plural(int n, String one, String many) => n == 1 ? one : many;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        const SectionLabel(
          'Lista de espera',
          info: 'Las compras que dejaste en espera este mes y qué decidiste. '
              'Lo que no compraste se suma desde que usas la lista.',
        ),
        const SizedBox(height: 12),
        Text.rich(TextSpan(
          style: TextStyle(fontSize: 13, color: context.colors.ink),
          children: [
            TextSpan(
                text: currencyFmt.format(s.discardedAmountToDate), style: big),
            const TextSpan(text: ' que decidiste no gastar, en total'),
          ],
        )),
        const SizedBox(height: 8),
        if (s.total == 0)
          Text('Este mes no dejaste nada en espera.', style: soft)
        else ...[
          Text(
            '${s.total} ${plural(s.total, 'deseo', 'deseos')} este mes: '
            '${s.bought} ${plural(s.bought, 'comprado', 'comprados')}, '
            '${s.discarded} ${plural(s.discarded, 'descartado', 'descartados')}'
            ' y ${s.waiting} esperando.',
            style: const TextStyle(fontSize: 13),
          ),
          if (s.boughtPercent != null) ...[
            const SizedBox(height: 4),
            Text(
                'Compraste el ${s.boughtPercent}% de los que ya '
                'decidiste.',
                style: soft),
          ],
          if (s.savedAmount > 0) ...[
            const SizedBox(height: 4),
            Text('${currencyFmt.format(s.savedAmount)} pasaron a tus metas.',
                style: soft),
          ],
        ],
      ],
    );
  }
}
