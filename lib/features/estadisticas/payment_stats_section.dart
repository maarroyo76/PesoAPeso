import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatting.dart';
import '../../core/utils/payment_stats.dart';
import '../../core/widgets/section_label.dart';
import '../../data/local/app_database.dart';
import '../metodos_pago/payment_method_labels.dart';

final _dayFmt = DateFormat("d 'de' MMMM", 'es_CL');

/// RF40–RF43: estadísticas por método de pago. No se muestra nada mientras
/// el usuario no tenga métodos de pago.
class PaymentStatsSection extends ConsumerWidget {
  const PaymentStatsSection({
    super.key,
    required this.months,
    required this.transactions,
  });

  /// Los 6 meses de la tendencia; el último es el mes que se está viendo.
  final List<DateTime> months;

  /// Gastos del mes que se está viendo.
  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methods = ref.watch(paymentMethodsProvider).valueOrNull ?? const [];
    if (methods.isEmpty) return const SizedBox.shrink();
    final methodsById = paymentMethodsById(methods);
    final cards = methods.where((m) => m.kind == kPaymentKindCredit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        const SectionLabel(
          'Gasto por método de pago',
          info: 'Cuánto pagaste este mes con cada tarjeta, cuenta o '
              'efectivo. Los gastos sin método quedan en "Sin especificar".',
        ),
        const SizedBox(height: 12),
        _ByMethod(transactions: transactions, methodsById: methodsById),
        const SizedBox(height: 32),
        const SectionLabel(
          'Crédito, débito y efectivo',
          info: 'Qué parte de tu gasto de cada mes fue con crédito, con '
              'débito o en efectivo, en los últimos 6 meses.',
        ),
        const SizedBox(height: 12),
        _KindTrend(months: months, methodsById: methodsById),
        if (cards.isNotEmpty) ...[
          const SizedBox(height: 32),
          const SectionLabel(
            'Tarjetas de crédito',
            info: 'Deuda en cuotas: lo que falta pagar desde el próximo mes. '
                'Próximo estado de cuenta: una estimación con las compras y '
                'cuotas del período de facturación en curso.',
          ),
          const SizedBox(height: 12),
          for (final card in cards) _CardSummary(card: card),
        ],
      ],
    );
  }
}

/// RF40: gasto del mes por método, de mayor a menor.
class _ByMethod extends StatelessWidget {
  const _ByMethod({required this.transactions, required this.methodsById});
  final List<Transaction> transactions;
  final Map<int, PaymentMethod> methodsById;

  @override
  Widget build(BuildContext context) {
    // Un método eliminado no puede tener gastos (RF31), pero un respaldo
    // podría traerlos: se juntan con "Sin especificar".
    final byMethod = <int?, int>{};
    for (final e in spentByPaymentMethod(transactions).entries) {
      final key = methodsById.containsKey(e.key) ? e.key : null;
      byMethod[key] = (byMethod[key] ?? 0) + e.value;
    }
    if (byMethod.isEmpty) {
      return Text('Sin gastos este mes.',
          style: TextStyle(fontSize: 13, color: context.colors.inkSoft));
    }
    final pct = percentagesOf(byMethod);
    final entries = byMethod.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      children: [
        for (final e in entries)
          _AmountRow(
            icon: e.key == null
                ? Icons.help_outline
                : paymentKindIcon(methodsById[e.key]!.kind),
            label: e.key == null
                ? kNoPaymentMethodLabel
                : paymentMethodLabel(methodsById[e.key]!),
            percent: pct[e.key],
            amount: e.value,
          ),
      ],
    );
  }
}

/// RF41: proporción por tipo de método en cada uno de los 6 meses.
class _KindTrend extends ConsumerWidget {
  const _KindTrend({required this.months, required this.methodsById});
  final List<DateTime> months;
  final Map<int, PaymentMethod> methodsById;

  static const _kinds = [
    kPaymentKindCredit,
    kPaymentKindDebit,
    kPaymentKindCash,
    kNoPaymentKind,
  ];

  static String _label(String kind) =>
      kind == kNoPaymentKind ? kNoPaymentMethodLabel : paymentKindLabel(kind);

  Color _color(BuildContext context, String kind) => switch (kind) {
        kPaymentKindCredit => context.colors.rust,
        kPaymentKindDebit => context.colors.ink,
        kPaymentKindCash => context.colors.green,
        _ => context.colors.rule,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            for (final kind in _kinds)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: _color(context, kind),
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 6),
                  Text(_label(kind),
                      style: TextStyle(
                          fontSize: 12, color: context.colors.inkSoft)),
                ],
              ),
          ],
        ),
        const SizedBox(height: 10),
        for (final month in months)
          _monthBar(
            context,
            month,
            ref.watch(monthTransactionsProvider(month)).valueOrNull ?? const [],
          ),
      ],
    );
  }

  Widget _monthBar(
      BuildContext context, DateTime month, List<Transaction> transactions) {
    final pct = percentagesOf(spentByKind(transactions, methodsById));
    final label = capitalizeMonth(month, monthShortFmt);
    final description = pct.isEmpty
        ? 'sin gastos'
        : [
            for (final kind in _kinds)
              if ((pct[kind] ?? 0) > 0) '${_label(kind)} ${pct[kind]}%',
          ].join(', ');
    return Semantics(
      label: '$label: $description',
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 14,
                  child: pct.isEmpty
                      ? ColoredBox(color: context.colors.paperDeep)
                      : Row(
                          children: [
                            for (final kind in _kinds)
                              if ((pct[kind] ?? 0) > 0)
                                Expanded(
                                  flex: pct[kind]!,
                                  child:
                                      ColoredBox(color: _color(context, kind)),
                                ),
                          ],
                        ),
                ),
              ),
            ),
            SizedBox(
              width: 48,
              child: Text(
                pct.isEmpty ? '—' : '${pct[kPaymentKindCredit] ?? 0}%',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 12, color: context.colors.inkSoft),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// RF42 y RF43: deuda en cuotas y próximo estado de cuenta de una tarjeta.
class _CardSummary extends ConsumerWidget {
  const _CardSummary({required this.card});
  final PaymentMethod card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final debt = installmentDebtByCard(
            ref.watch(installmentTransactionsProvider).valueOrNull ?? const [],
            thisMonth)[card.id] ??
        0;
    // El período en curso abarca a lo más el mes anterior, este y el
    // siguiente.
    final nearby = [
      for (final offset in [-1, 0, 1])
        ...ref
                .watch(monthTransactionsProvider(
                    DateTime(now.year, now.month + offset)))
                .valueOrNull ??
            const <Transaction>[],
    ];
    final statement = estimatedStatement(card, nearby, now);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.paperDeep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.colors.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.credit_card, size: 18, color: context.colors.inkSoft),
              const SizedBox(width: 8),
              Expanded(
                child: Text(paymentMethodLabel(card),
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: context.colors.ink)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _AmountRow(label: 'Deuda en cuotas', amount: debt),
          if (statement == null)
            Text(
              'Agrega su día de facturación en Métodos de pago para estimar '
              'el próximo estado de cuenta.',
              style: TextStyle(fontSize: 12, color: context.colors.inkSoft),
            )
          else ...[
            _AmountRow(
                label: 'Próximo estado de cuenta', amount: statement.amount),
            Text(
              'Cierra el ${_dayFmt.format(statement.period.closing)}'
              '${statement.period.due == null ? '' : ' · se paga el '
                  '${_dayFmt.format(statement.period.due!)}'}',
              style: TextStyle(fontSize: 12, color: context.colors.inkSoft),
            ),
          ],
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    this.icon,
    this.percent,
  });
  final String label;
  final int amount;
  final IconData? icon;
  final int? percent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: context.colors.inkSoft),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 13, color: context.colors.ink)),
          ),
          if (percent != null) ...[
            Text('$percent%',
                style: TextStyle(fontSize: 12, color: context.colors.inkSoft)),
            const SizedBox(width: 12),
          ],
          Text(
            currencyFmt.format(amount),
            style: appAmountTextStyle.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.colors.ink),
          ),
        ],
      ),
    );
  }
}
