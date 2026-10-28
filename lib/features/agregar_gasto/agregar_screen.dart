import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/amount_input.dart';
import '../../core/utils/budget_alert.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/section_label.dart';
import '../../core/widgets/undo_snack_bar.dart';
import '../../core/widgets/load_error.dart';
import '../../data/local/app_database.dart';
import 'expense_form.dart';

class AgregarScreen extends ConsumerWidget {
  const AgregarScreen({super.key, this.active = false});

  /// true mientras esta pestaña es la visible (UX03: foco en el monto).
  final bool active;

  /// UX01: un toque registra el gasto de inmediato; el aviso posterior
  /// permite deshacerlo. Devuelve true para que el chip muestre "✓ Listo".
  ///
  /// RF46: el mismo aviso ofrece ×2, ×3 o más, que corrigen ese gasto (sigue
  /// siendo uno solo, por el monto multiplicado). Así ×1 toma un toque y ×2,
  /// dos, sin preguntar la cantidad antes de cada registro.
  Future<bool> _handleQuickAdd(
      BuildContext context, WidgetRef ref, QuickExpenseTemplate qa) async {
    final date = DateTime.now();
    final txRepo = ref.read(transactionsRepositoryProvider);
    final int id;
    final int? paymentMethodId;
    try {
      // RF32: el acceso rápido sigue siendo de un toque; usa el último método
      // de pago y se puede cambiar desde el detalle del gasto.
      paymentMethodId = await ref
          .read(paymentMethodsRepositoryProvider)
          .lastUsedPaymentMethodId();
      id = await txRepo.addTransaction(
        categoryId: qa.categoryId,
        amount: qa.amount,
        date: date,
        note: qa.label,
        paymentMethodId: paymentMethodId,
      );
    } catch (e) {
      // UX09: mensaje para el usuario en vez del error técnico.
      debugPrint('Acceso rápido: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              const Text('No se pudo registrar el gasto. Inténtalo de nuevo.'),
          backgroundColor: context.colors.rust,
        ));
      }
      return false;
    }
    HapticFeedback.lightImpact();
    if (!context.mounted) return true;
    // El aviso se actualiza en su lugar al cambiar la cantidad, sin cerrarse.
    final quantity = ValueNotifier(1);
    Future<void> setQuantity(int n) async {
      if (n == quantity.value) return;
      quantity.value = n;
      await txRepo.updateTransaction(
        id: id,
        categoryId: qa.categoryId,
        amount: qa.amount * n,
        date: date,
        note: quickAddNote(qa.label, n),
        paymentMethodId: paymentMethodId,
      );
      HapticFeedback.selectionClick();
      final alerts =
          await checkBudgetAlerts(ref, categoryId: qa.categoryId, date: date);
      if (context.mounted) showBudgetAlertBanner(context, alerts);
    }

    showUndoSnackBar(
      ScaffoldMessenger.of(context),
      onUndo: () => txRepo.deleteTransaction(id),
      // Un poco más que el aviso normal: da tiempo de elegir la cantidad.
      duration: const Duration(seconds: 6),
      content: ValueListenableBuilder<int>(
        valueListenable: quantity,
        builder: (_, n, __) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registrado · ${quickAddNote(qa.label, n)} '
                '${currencyFmt.format(qa.amount * n)}'),
            _QuantityPicker(
              selected: n,
              onSelected: setQuantity,
              onMore: () async {
                final more = await _askQuantity(context, qa);
                if (more != null) await setQuantity(more);
              },
            ),
          ],
        ),
      ),
    );
    // RF18/RF55: aviso inmediato en pantalla si este gasto deja la categoría
    // o el presupuesto total en 80% o más.
    final alerts =
        await checkBudgetAlerts(ref, categoryId: qa.categoryId, date: date);
    if (context.mounted) showBudgetAlertBanner(context, alerts);
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickTemplatesAsync = ref.watch(quickExpenseTemplatesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Flexible(child: SectionLabel('Registro rápido')),
            // IconButton y no un InkWell sobre el ícono: área táctil de 48 px.
            IconButton(
              tooltip: 'Nuevo acceso rápido',
              iconSize: 18,
              color: context.colors.inkSoft,
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                final categories = categoriesAsync.valueOrNull ?? const [];
                if (categories.isEmpty) return;
                _showQuickTemplateEditor(context, ref, categories);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        quickTemplatesAsync.when(
          loading: () => const SizedBox(
              height: 64, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => LoadError(e, compact: true),
          data: (templates) {
            if (templates.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Sin accesos rápidos todavía. Toca "+" para crear uno.',
                  style: TextStyle(color: context.colors.inkSoft, fontSize: 12),
                ),
              );
            }
            // UX07: la fila crece con la letra del sistema (64 px al 100%).
            final textScale =
                MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 3.0);
            final chips = SizedBox(
              height: 20 + 44 * textScale,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: templates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final qa = templates[i];
                  return _QuickAddChip(
                    template: qa,
                    onTap: () => _handleQuickAdd(context, ref, qa),
                    onLongPress: () {
                      final categories =
                          categoriesAsync.valueOrNull ?? const [];
                      if (categories.isEmpty) return;
                      _showQuickTemplateEditor(context, ref, categories,
                          template: qa);
                    },
                  );
                },
              ),
            );
            // RF45: con un acceso de bip!, recordar que conviene anotar las
            // cargas de la tarjeta y no cada viaje.
            final hasBip =
                templates.any((t) => t.label.toLowerCase().contains('bip'));
            if (!hasBip) return chips;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                chips,
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline,
                        size: 14, color: context.colors.inkSoft),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Con la tarjeta bip!, registra cada carga y no cada '
                        'viaje: el gasto ya ocurrió al cargarla.',
                        style: TextStyle(
                            fontSize: 12, color: context.colors.inkSoft),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const Divider(height: 32),
        const SectionLabel('Gasto manual'),
        const SizedBox(height: 12),
        ExpenseForm(
          focusAmount: active,
          onSubmit: ({
            required categoryId,
            required amount,
            required date,
            required note,
            required recurring,
            required paymentMethodId,
            required installments,
          }) async {
            // RF34: una compra en cuotas genera todas sus cuotas de una vez;
            // deshacer la elimina completa.
            if (installments != null && paymentMethodId != null) {
              final repo = ref.read(installmentsRepositoryProvider);
              final planId = await repo.createPlan(
                paymentMethodId: paymentMethodId,
                categoryId: categoryId,
                note: note,
                totalAmount: installments.totalFor(amount),
                count: installments.count,
                purchaseDate: date,
              );
              if (context.mounted) {
                final alerts = await checkBudgetAlerts(ref,
                    categoryId: categoryId, date: date);
                if (context.mounted) showBudgetAlertBanner(context, alerts);
              }
              return () => repo.deletePlan(planId);
            }
            final txRepo = ref.read(transactionsRepositoryProvider);
            final templatesRepo =
                ref.read(recurringTemplatesRepositoryProvider);
            // RF12: además de registrar el gasto de hoy, crea la plantilla
            // que el catch-up usará los meses siguientes. Se crea primero
            // para que este gasto también quede enlazado a ella (I4).
            final templateId = recurring
                ? await templatesRepo.createTemplate(
                    categoryId: categoryId,
                    amount: amount,
                    note: note,
                    dayOfMonth: date.day,
                    initialYearMonth: date.year * 100 + date.month,
                  )
                : null;
            final id = await txRepo.addTransaction(
              categoryId: categoryId,
              amount: amount,
              date: date,
              note: note,
              isRecurring: recurring,
              recurringTemplateId: templateId,
              paymentMethodId: paymentMethodId,
            );
            Future<void> undo() async {
              await txRepo.deleteTransaction(id);
              if (templateId != null) {
                await templatesRepo.deleteTemplate(templateId);
              }
            }

            if (!context.mounted) return undo;
            // RF18/RF55: aviso inmediato en pantalla si este gasto deja la
            // categoría o el presupuesto total en 80% o más.
            final alerts = await checkBudgetAlerts(ref,
                categoryId: categoryId, date: date);
            if (context.mounted) showBudgetAlertBanner(context, alerts);
            return undo;
          },
        ),
      ],
    );
  }
}

/// RF24: crear/editar (o eliminar, si [template] no es null) un acceso
/// rápido de gasto.
Future<void> _showQuickTemplateEditor(
  BuildContext context,
  WidgetRef ref,
  List<Category> categories, {
  QuickExpenseTemplate? template,
}) async {
  final labelController = TextEditingController(text: template?.label ?? '');
  final amountController = TextEditingController(
      text: template == null ? '' : formatAmountInput(template.amount));
  var selectedCategoryId = template?.categoryId ?? categories.first.id;
  String? labelError;
  String? amountError;

  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: context.colors.paper,
        title: Text(
          template == null ? 'Nuevo acceso rápido' : 'Editar acceso rápido',
          style: TextStyle(fontSize: 16, color: context.colors.ink),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: labelController,
                autofocus: true,
                maxLength: kMaxNameLength,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                    labelText: 'Etiqueta',
                    errorText: labelError,
                    border: const UnderlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: amountInputFormatters,
                decoration: InputDecoration(
                  labelText: 'Monto',
                  prefixText: '\$ ',
                  errorText: amountError,
                  border: const UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text('Categoría',
                  style:
                      TextStyle(fontSize: 12, color: context.colors.inkSoft)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories
                    .map((c) => ExpenseCategoryChip(
                          category: c,
                          selected: c.id == selectedCategoryId,
                          onTap: () =>
                              setDialogState(() => selectedCategoryId = c.id),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        actions: [
          if (template != null)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'delete'),
              child: Text('Eliminar',
                  style: TextStyle(color: context.colors.rust)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text('Cancelar',
                style: TextStyle(color: context.colors.inkSoft)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.colors.ink),
            onPressed: () {
              final amount = parsePositiveAmount(amountController.text);
              final labelEmpty = labelController.text.trim().isEmpty;
              if (labelEmpty || amount == null) {
                setDialogState(() {
                  labelError = labelEmpty ? 'Escribe una etiqueta' : null;
                  amountError = amount == null ? kInvalidAmountMessage : null;
                });
                return;
              }
              Navigator.pop(ctx, 'save');
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );

  final repo = ref.read(quickExpenseTemplatesRepositoryProvider);
  if (result == 'delete' && template != null) {
    await repo.delete(template.id);
  } else if (result == 'save') {
    final label = labelController.text.trim();
    final amount = parseAmountText(amountController.text)!;
    if (template == null) {
      await repo.create(
          label: label, amount: amount, categoryId: selectedCategoryId);
    } else {
      await repo.update(template.id,
          label: label, amount: amount, categoryId: selectedCategoryId);
    }
  }
}

/// RF46: nota de un acceso rápido registrado [quantity] veces de una vez
/// (p. ej. "Micro/Metro ×2").
String quickAddNote(String label, int quantity) =>
    quantity == 1 ? label : '$label ×$quantity';

/// Cantidad para "Más" (RF46): de 2 a 99.
Future<int?> _askQuantity(BuildContext context, QuickExpenseTemplate qa) {
  final controller = TextEditingController();
  String? error;
  return showDialog<int>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        void submit() {
          final n = int.tryParse(controller.text);
          if (n == null || n < 2 || n > 99) {
            setDialogState(() => error = 'Ingresa un número entre 2 y 99');
            return;
          }
          Navigator.pop(ctx, n);
        }

        return AlertDialog(
          title: Text('¿Cuántas veces ${qa.label}?'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            onSubmitted: (_) => submit(),
            decoration: InputDecoration(
              labelText: 'Cantidad',
              helperText: 'Se registra un solo gasto por el total',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(onPressed: submit, child: const Text('Listo')),
          ],
        );
      },
    ),
  );
}

/// Botones ×1, ×2, ×3 y "Más" dentro del aviso de registro (RF46).
class _QuantityPicker extends StatelessWidget {
  const _QuantityPicker({
    required this.selected,
    required this.onSelected,
    required this.onMore,
  });
  final int selected;
  final ValueChanged<int> onSelected;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final paper = context.colors.paper;
    Widget option(String label, VoidCallback onTap, {bool active = false}) =>
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: paper,
            backgroundColor: active ? paper.withValues(alpha: 0.18) : null,
            minimumSize: const Size(48, 40),
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          onPressed: onTap,
          child: Text(label,
              style: TextStyle(
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
        );
    final isOther = selected > 3;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: [
          for (final n in [1, 2, 3])
            Semantics(
              selected: n == selected,
              child: option('×$n', () => onSelected(n), active: n == selected),
            ),
          Semantics(
            selected: isOther,
            child:
                option(isOther ? '×$selected' : 'Más', onMore, active: isOther),
          ),
        ],
      ),
    );
  }
}

class _QuickAddChip extends StatefulWidget {
  const _QuickAddChip(
      {required this.template, required this.onTap, required this.onLongPress});
  final QuickExpenseTemplate template;
  final Future<bool> Function() onTap;
  final VoidCallback onLongPress;

  @override
  State<_QuickAddChip> createState() => _QuickAddChipState();
}

class _QuickAddChipState extends State<_QuickAddChip> {
  bool _pressed = false;
  bool _justAdded = false;

  Future<void> _handleTap() async {
    final added = await widget.onTap();
    if (!mounted || !added) return;
    setState(() => _justAdded = true);
    await Future.delayed(const Duration(milliseconds: 650));
    if (mounted) setState(() => _justAdded = false);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Material(
          color: Colors.transparent,
          // UX08: anuncia que mantener presionado edita el acceso rápido.
          child: Semantics(
            onLongPressHint: 'editar',
            child: InkWell(
              onTap: _handleTap,
              onLongPress: widget.onLongPress,
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color:
                        _justAdded ? context.colors.green : context.colors.rule,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  color: _justAdded
                      ? context.colors.green.withValues(alpha: 0.15)
                      : context.colors.paperDeep,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _justAdded
                      ? Row(
                          key: const ValueKey('done'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                size: 16, color: context.colors.green),
                            const SizedBox(width: 6),
                            Text('Listo',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: context.colors.green)),
                          ],
                        )
                      : Column(
                          key: const ValueKey('label'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(widget.template.label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                            Text(currencyFmt.format(widget.template.amount),
                                style: appAmountTextStyle.copyWith(
                                    fontSize: 11,
                                    color: context.colors.inkSoft)),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
