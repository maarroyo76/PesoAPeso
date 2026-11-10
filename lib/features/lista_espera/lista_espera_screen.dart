import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/amount_input.dart';
import '../../core/utils/formatting.dart';
import '../../core/utils/installments.dart';
import '../../core/utils/wishlist.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/section_label.dart';
import '../../core/widgets/undo_snack_bar.dart';
import '../../data/local/app_database.dart';
import '../simulador/simulador_screen.dart';
import 'wish_decision_card.dart';

/// Largo máximo del nombre de un deseo.
const kMaxWishNameLength = 40;

final _dueFmt = DateFormat("EEEE d 'de' MMMM", 'es_CL');
final _dueTimeFmt = DateFormat('HH:mm', 'es_CL');

/// "martes 17 de noviembre a las 15:30".
String wishDueLabel(DateTime dueAt) =>
    '${_dueFmt.format(dueAt)} a las ${_dueTimeFmt.format(dueAt)}';

/// RF61: nombre y plazo con que se deja una compra en espera.
typedef WaitChoice = ({String name, WaitPeriod period});

/// RF61: pide el nombre y el plazo para dejar una compra en espera.
Future<WaitChoice?> showWaitSheet(BuildContext context,
    {required String initialName}) {
  final nameController = TextEditingController(text: initialName);
  var period = WaitPeriod.days7;
  return showModalBottomSheet<WaitChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.colors.paper,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 20 + MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Dejarlo en espera',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Cuando se cumpla el plazo, Resumen te preguntará si todavía '
              'lo quieres, con tus números de ese día.',
              style: TextStyle(fontSize: 13, color: context.colors.inkSoft),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              maxLength: kMaxWishNameLength,
              decoration: const InputDecoration(
                labelText: 'Qué es',
                border: UnderlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            _PeriodPicker(
                value: period, onChanged: (p) => setState(() => period = p)),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.ink,
                foregroundColor: context.colors.paper,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () {
                final name = nameController.text.trim();
                Navigator.pop(sheetContext,
                    (name: name.isEmpty ? initialName : name, period: period));
              },
              child: const Text('Guardar en la lista de espera'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PeriodPicker extends StatelessWidget {
  const _PeriodPicker({required this.value, required this.onChanged});
  final WaitPeriod value;
  final ValueChanged<WaitPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Esperar',
            style: TextStyle(fontSize: 12, color: context.colors.inkSoft)),
        const SizedBox(height: 8),
        SegmentedButton<WaitPeriod>(
          showSelectedIcon: false,
          segments: [
            for (final p in WaitPeriod.values)
              ButtonSegment(value: p, label: Text(p.label)),
          ],
          selected: {value},
          onSelectionChanged: (v) => onChanged(v.single),
        ),
      ],
    );
  }
}

/// RF61: la lista de espera. Arriba los deseos con el plazo cumplido (para
/// decidir), luego los que siguen esperando y al final los ya decididos.
class ListaEsperaScreen extends ConsumerWidget {
  const ListaEsperaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishesAsync = ref.watch(wishlistProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de espera')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: context.colors.ink,
        foregroundColor: context.colors.paper,
        onPressed: () => showWishEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: SafeArea(
        child: wishesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => LoadError(e),
          data: (wishes) => _list(context, ref, wishes),
        ),
      ),
    );
  }

  Widget _list(BuildContext context, WidgetRef ref, List<WishlistItem> all) {
    final now = DateTime.now();
    final due = dueWishes(all, now);
    final waiting =
        all.where((w) => isWaiting(w) && !isWishDue(w, now)).toList();
    final decided = all.where((w) => !isWaiting(w)).toList()
      ..sort((a, b) => b.decidedAt!.compareTo(a.decidedAt!));

    if (all.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cuando una compra no sea urgente, déjala en espera unos días '
              'y decide después, con calma y con tus números a la vista.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: context.colors.inkSoft),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                style:
                    TextButton.styleFrom(foregroundColor: context.colors.ink),
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SimuladorScreen())),
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('Simular una compra'),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
      children: [
        if (due.isNotEmpty) ...[
          const SectionLabel('Para decidir'),
          for (final w in due)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: WishDecisionCard(wish: w),
            ),
          const SizedBox(height: 24),
        ],
        if (waiting.isNotEmpty) ...[
          const SectionLabel('En espera'),
          const SizedBox(height: 4),
          for (final w in waiting)
            _WishRow(
              wish: w,
              trailing: timeLeftLabel(w.dueAt, now),
              onTap: () => showWishEditor(context, ref, wish: w),
            ),
          const SizedBox(height: 24),
        ],
        if (decided.isNotEmpty) ...[
          const SectionLabel('Decididos'),
          const SizedBox(height: 4),
          for (final w in decided)
            _WishRow(wish: w, trailing: _decisionLabel(w), muted: true),
        ],
      ],
    );
  }

  static String _decisionLabel(WishlistItem w) => switch (w.status) {
        kWishBought => 'Comprado',
        kWishSaved => 'Ahorrado',
        _ => 'Descartado',
      };
}

class _WishRow extends StatelessWidget {
  const _WishRow({
    required this.wish,
    required this.trailing,
    this.onTap,
    this.muted = false,
  });
  final WishlistItem wish;
  final String trailing;
  final VoidCallback? onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final how = wish.installmentCount == 1
        ? 'al contado'
        : 'en ${wish.installmentCount} cuotas';
    return MergeSemantics(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: onTap,
        title: Text(wish.name,
            style: TextStyle(
                color: muted ? context.colors.inkSoft : context.colors.ink)),
        subtitle: Text(
          '${currencyFmt.format(wish.amount)} $how',
          style: appAmountTextStyle.copyWith(
              fontSize: 12, color: context.colors.inkSoft),
        ),
        trailing: Text(trailing,
            style: TextStyle(fontSize: 13, color: context.colors.inkSoft)),
      ),
    );
  }
}

/// RF61: crea un deseo o edita uno que sigue esperando (nombre, monto,
/// cuotas y plazo). Al editar, el plazo se cuenta desde que se creó.
Future<void> showWishEditor(BuildContext context, WidgetRef ref,
    {WishlistItem? wish}) {
  final nameController = TextEditingController(text: wish?.name ?? '');
  final amountController = TextEditingController(
      text: wish == null ? '' : formatAmountInput(wish.amount));
  final countController = TextEditingController(
      text: wish == null || wish.installmentCount == 1
          ? ''
          : '${wish.installmentCount}');
  var period = wish == null ? WaitPeriod.days7 : WaitPeriod.of(wish);
  final repo = ref.read(wishlistRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.colors.paper,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 20 + MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: StatefulBuilder(builder: (context, setState) {
        final name = nameController.text.trim();
        final amount = parsePositiveAmount(amountController.text);
        final countText = countController.text.trim();
        final count = countText.isEmpty ? 1 : int.tryParse(countText);
        final countOk =
            count != null && count >= 1 && count <= kMaxInstallments;
        final valid = name.isNotEmpty && amount != null && countOk;

        Future<void> save() async {
          final now = DateTime.now();
          if (wish == null) {
            await repo.create(
              name: name,
              amount: amount!,
              installmentCount: count!,
              createdAt: now,
              dueAt: wishDueAt(now, period),
            );
          } else {
            await repo.update(
              wish.id,
              name: name,
              amount: amount!,
              installmentCount: count!,
              dueAt: wishDueAt(wish.createdAt, period),
            );
          }
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        }

        Future<void> delete() async {
          final restore = await repo.deleteUndoable(wish!.id);
          if (sheetContext.mounted) Navigator.pop(sheetContext);
          showUndoSnackBar(messenger,
              message: 'Eliminaste "${wish.name}"', onUndo: restore);
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(wish == null ? 'Nuevo deseo' : 'Editar deseo',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              autofocus: wish == null,
              maxLength: kMaxWishNameLength,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Qué es',
                border: UnderlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: amountInputFormatters,
                    onChanged: (_) => setState(() {}),
                    style: appAmountTextStyle,
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      prefixText: '\$ ',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: countController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Cuotas',
                      hintText: 'Al contado',
                      border: const UnderlineInputBorder(),
                      errorText: countOk ? null : 'De 1 a $kMaxInstallments',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _PeriodPicker(
                value: period, onChanged: (p) => setState(() => period = p)),
            if (wish != null) ...[
              const SizedBox(height: 8),
              Text(
                'Vence el ${wishDueLabel(wishDueAt(wish.createdAt, period))}',
                style: TextStyle(fontSize: 13, color: context.colors.inkSoft),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.ink,
                foregroundColor: context.colors.paper,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: valid ? save : null,
              child: const Text('Guardar'),
            ),
            if (wish != null) ...[
              const SizedBox(height: 8),
              TextButton(
                style:
                    TextButton.styleFrom(foregroundColor: context.colors.rust),
                onPressed: delete,
                child: const Text('Eliminar'),
              ),
            ],
          ],
        );
      }),
    ),
  );
}
