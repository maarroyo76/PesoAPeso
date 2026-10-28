import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatting.dart';
import '../../core/utils/weekly_review.dart';
import '../../data/local/app_database.dart';

final _dayFmt = DateFormat('EEEE d', 'es_CL');

/// RF37: guarda la revisión de hoy (hecha u omitida); la próxima se propone
/// en una semana.
Future<void> markWeeklyReviewDone(WidgetRef ref) => ref
    .read(settingsRepositoryProvider)
    .set(kWeeklyReviewSettingKey, reviewDateKey(DateTime.now()));

/// RF37: revisar los gastos de los últimos 7 días y marcar cada uno como
/// "valió la pena" o "no tanto". Cada marca se guarda al tocarla.
class WeeklyReviewScreen extends ConsumerWidget {
  const WeeklyReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final prevMonth = DateTime(now.year, now.month - 1);
    final transactions = [
      ...ref.watch(monthTransactionsProvider(prevMonth)).valueOrNull ??
          const <Transaction>[],
      ...ref.watch(monthTransactionsProvider(thisMonth)).valueOrNull ??
          const <Transaction>[],
    ];
    final candidates = weeklyReviewCandidates(transactions, now);
    final categories = {
      for (final c
          in ref.watch(categoriesProvider).valueOrNull ?? const <Category>[])
        c.id: c.name
    };

    return Scaffold(
      backgroundColor: context.colors.paper,
      appBar: AppBar(title: const Text('¿Valió la pena?')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Tus gastos de los últimos 7 días. Marca los que no valieron '
                'tanto: no es para culparte, sino para ver dónde se va la '
                'plata que no disfrutas.',
                style: TextStyle(fontSize: 13, color: context.colors.inkSoft),
              ),
            ),
            Expanded(
              child: candidates.isEmpty
                  ? Center(
                      child: Text('No hay gastos para revisar esta semana.',
                          style: TextStyle(color: context.colors.inkSoft)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: candidates.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final t = candidates[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      t.note.isNotEmpty
                                          ? t.note
                                          : categories[t.categoryId] ??
                                              t.categoryId,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Text(currencyFmt.format(t.amount),
                                      style: appAmountTextStyle.copyWith(
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                              Text(
                                '${categories[t.categoryId] ?? t.categoryId}'
                                ' · ${_dayFmt.format(t.date)}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: context.colors.inkSoft),
                              ),
                              const SizedBox(height: 6),
                              WorthItChoice(transaction: t),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: FilledButton(
                style:
                    FilledButton.styleFrom(backgroundColor: context.colors.ink),
                onPressed: () async {
                  await markWeeklyReviewDone(ref);
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('Listo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// RF37: "Valió la pena" / "No tanto" de un gasto. Tocar la opción ya
/// elegida la quita (vuelve a "sin revisar"). Se usa en la revisión y al
/// editar el gasto, para cambiar la marca después.
class WorthItChoice extends ConsumerStatefulWidget {
  const WorthItChoice({super.key, required this.transaction});
  final Transaction transaction;

  @override
  ConsumerState<WorthItChoice> createState() => _WorthItChoiceState();
}

class _WorthItChoiceState extends ConsumerState<WorthItChoice> {
  late bool? _value = widget.transaction.worthIt;

  Future<void> _set(bool? value) async {
    setState(() => _value = value);
    await ref
        .read(transactionsRepositoryProvider)
        .setWorthIt(widget.transaction.id, value);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        ChoiceChip(
          label: const Text('Valió la pena'),
          selected: _value == true,
          onSelected: (on) => _set(on ? true : null),
        ),
        ChoiceChip(
          label: const Text('No tanto'),
          selected: _value == false,
          onSelected: (on) => _set(on ? false : null),
        ),
      ],
    );
  }
}
