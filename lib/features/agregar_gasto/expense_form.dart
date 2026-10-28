import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/category_icons.dart';
import '../../core/utils/amount_input.dart';
import '../../core/utils/billing_period.dart';
import '../../core/utils/formatting.dart';
import '../../core/utils/installments.dart';
import '../../core/widgets/undo_snack_bar.dart';
import '../../core/widgets/info_hint.dart';
import '../../core/widgets/load_error.dart';
import '../../data/local/app_database.dart';
import '../metodos_pago/payment_method_labels.dart';
import '../metodos_pago/payment_methods_screen.dart';
import '../categorias/category_filters.dart';

/// Guarda el gasto. Al registrar uno nuevo devuelve cómo deshacerlo (UX01);
/// al editar devuelve null.
typedef ExpenseFormSubmit = Future<UndoAction?> Function({
  required String categoryId,
  required int amount,
  required DateTime date,
  required String note,
  required bool recurring,
  required int? paymentMethodId,
  required InstallmentChoice? installments,
});

/// RF34: compra en cuotas: cuántas, y si el monto ingresado es el total de
/// la compra o el valor de cada cuota.
class InstallmentChoice {
  const InstallmentChoice(
      {required this.count, required this.amountIsPerInstallment});
  final int count;
  final bool amountIsPerInstallment;

  /// Total de la compra a partir del monto ingresado en el formulario.
  int totalFor(int amount) => amountIsPerInstallment ? amount * count : amount;
}

/// Formulario de monto/categoría/fecha/nota/recurrente, usado tanto para
/// registrar un gasto manual (AgregarScreen) como para editar uno existente
/// (EditTransactionScreen) — mismo formulario, mismo feedback visual.
class ExpenseForm extends ConsumerStatefulWidget {
  const ExpenseForm({
    super.key,
    this.initialAmount,
    this.initialCategoryId,
    this.initialDate,
    this.initialNote = '',
    this.initialRecurring = false,
    this.initialPaymentMethodId,
    this.isEditing = false,
    this.focusAmount = false,
    required this.onSubmit,
    this.onSaved,
    this.onRegistered,
  });

  final int? initialAmount;
  final String? initialCategoryId;
  final DateTime? initialDate;
  final String initialNote;
  final bool initialRecurring;
  final int? initialPaymentMethodId;

  /// true al editar un movimiento existente: cambia textos, no resetea el
  /// formulario tras guardar (llama a [onSaved] en su lugar).
  final bool isEditing;

  /// UX03: con true, el campo de monto toma el foco (y abre el teclado).
  /// AgregarScreen lo activa al entrar a su pestaña y lo desactiva al salir,
  /// porque vive en un IndexedStack y se construye aunque no esté visible.
  final bool focusAmount;

  final ExpenseFormSubmit onSubmit;

  /// Se llama después de un guardado exitoso, solo relevante en modo edición
  /// (para que la pantalla que aloja el formulario pueda cerrarse).
  final VoidCallback? onSaved;

  /// UX04: se llama después de registrar un gasto nuevo y mostrar su aviso
  /// "Deshacer", para que la hoja de registro se cierre.
  final VoidCallback? onRegistered;

  @override
  ConsumerState<ExpenseForm> createState() => _ExpenseFormState();
}

/// Reglas para elegir categoría, junto al catálogo por defecto.
const kCategoryUsageRules =
    'Elige la categoría según para qué fue el gasto, no dónde compraste. '
    'El pago del estado de cuenta de la tarjeta no es un gasto: cada compra '
    'ya se anotó con su método y sus cuotas. El ahorro tampoco: regístralo '
    'como aporte a una meta. Una boleta con varias cosas va en la categoría '
    'de mayor monto.';

class _ExpenseFormState extends ConsumerState<ExpenseForm> {
  late final _amountController = TextEditingController(
      text: widget.initialAmount == null
          ? ''
          : formatAmountInput(widget.initialAmount!));
  late final _noteController = TextEditingController(text: widget.initialNote);
  final _installmentsController = TextEditingController();
  bool _amountIsPerInstallment = false;
  final _amountFocus = FocusNode();
  String? _selectedCategoryId;
  late DateTime _selectedDate = widget.initialDate ?? DateTime.now();
  late bool _isRecurring = widget.initialRecurring;
  late int? _selectedPaymentMethodId = widget.initialPaymentMethodId;
  bool _userPickedPaymentMethod = false;
  bool _justSubmitted = false;
  bool _submitPressed = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    if (!widget.isEditing && _selectedCategoryId == null) {
      _preselectLastUsedCategory();
    }
    if (!widget.isEditing && _selectedPaymentMethodId == null) {
      _preselectLastUsedPaymentMethod();
    }
    if (widget.focusAmount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.focusAmount) _amountFocus.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(ExpenseForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusAmount == oldWidget.focusAmount) return;
    if (widget.focusAmount) {
      _amountFocus.requestFocus();
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  /// UX03: la categoría del último gasto registrado, si sigue existiendo y
  /// el usuario no eligió otra mientras tanto.
  Future<void> _preselectLastUsedCategory() async {
    final lastId =
        await ref.read(transactionsRepositoryProvider).lastUsedCategoryId();
    if (!mounted || lastId == null) return;
    final categories = ref.read(categoriesProvider).valueOrNull;
    if (categories != null &&
        !selectableCategories(categories).any((c) => c.id == lastId)) {
      return;
    }
    if (_userPickedCategory) return;
    setState(() => _selectedCategoryId = lastId);
  }

  bool _userPickedCategory = false;

  /// RF32: el método del último gasto que tenía uno, salvo que el usuario ya
  /// haya elegido otro.
  Future<void> _preselectLastUsedPaymentMethod() async {
    final lastId = await ref
        .read(paymentMethodsRepositoryProvider)
        .lastUsedPaymentMethodId();
    if (!mounted || lastId == null || _userPickedPaymentMethod) return;
    setState(() => _selectedPaymentMethodId = lastId);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _installmentsController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_submitting) return;
    final amount = parsePositiveAmount(_amountController.text);
    final categoryId = _selectedCategoryId;
    if (_installmentsEnabled &&
        _installmentsController.text.isNotEmpty &&
        _installmentChoice() == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Las cuotas van de $kMinInstallments a $kMaxInstallments. '
              'Déjalo vacío si es en una sola cuota.'),
          backgroundColor: context.colors.rust,
        ),
      );
      return;
    }
    if (amount == null || categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(kInvalidAmountMessage),
          duration: const Duration(milliseconds: 1500),
          backgroundColor: context.colors.rust,
        ),
      );
      return;
    }
    // Guarda de reentrada: un doble toque rápido no debe guardar ni cerrar
    // la pantalla dos veces.
    _submitting = true;
    try {
      await _submit(amount, categoryId);
    } catch (e) {
      // UX09: mensaje para el usuario; el formulario conserva lo ingresado.
      debugPrint('ExpenseForm: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? 'No se pudieron guardar los cambios. Inténtalo de nuevo.'
                : 'No se pudo registrar el gasto. Inténtalo de nuevo.'),
            backgroundColor: context.colors.rust,
          ),
        );
      }
    } finally {
      _submitting = false;
    }
  }

  /// UX01: un gasto nuevo se guarda sin diálogo de confirmación; el aviso
  /// posterior permite deshacerlo.
  Future<void> _submit(int amount, String categoryId) async {
    final undo = await widget.onSubmit(
      categoryId: categoryId,
      amount: amount,
      date: _selectedDate,
      note: _noteController.text,
      recurring: _isRecurring,
      paymentMethodId: _validPaymentMethodId(),
      installments: _installmentChoice(),
    );
    if (!mounted) return;

    if (widget.isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cambios guardados'),
          duration: const Duration(milliseconds: 900),
          backgroundColor: context.colors.ink,
        ),
      );
      widget.onSaved?.call();
      return;
    }

    HapticFeedback.lightImpact();
    _amountController.clear();
    _noteController.clear();
    _installmentsController.clear();
    setState(() {
      _isRecurring = false;
      _selectedDate = DateTime.now();
      _justSubmitted = true;
    });
    final message = 'Registrado · ${currencyFmt.format(amount)}';
    if (undo != null) {
      showUndoSnackBar(ScaffoldMessenger.of(context),
          message: message, onUndo: undo);
    }
    widget.onRegistered?.call();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _justSubmitted = false);
    });
  }

  /// RF34: las cuotas solo se ofrecen al registrar un gasto nuevo con un
  /// método de crédito.
  bool get _installmentsEnabled {
    if (widget.isEditing) return false;
    final id = _validPaymentMethodId();
    final methods = ref.read(paymentMethodsProvider).valueOrNull ?? const [];
    return methods.any((m) => m.id == id && m.kind == kPaymentKindCredit);
  }

  /// Las cuotas ingresadas, o null si no hay (o el número no es válido).
  InstallmentChoice? _installmentChoice() {
    if (!_installmentsEnabled) return null;
    final n = int.tryParse(_installmentsController.text);
    if (n == null || n < kMinInstallments || n > kMaxInstallments) return null;
    return InstallmentChoice(
        count: n, amountIsPerInstallment: _amountIsPerInstallment);
  }

  /// RF33: con una tarjeta de crédito que tiene día de facturación, en qué
  /// estado de cuenta cae la compra de la fecha elegida.
  List<Widget> _billingPeriodHint() {
    final methods = ref.watch(paymentMethodsProvider).valueOrNull ?? const [];
    final card =
        methods.where((m) => m.id == _selectedPaymentMethodId).firstOrNull;
    final billingDay = card?.billingDay;
    if (card == null || card.kind != kPaymentKindCredit || billingDay == null) {
      return const [];
    }
    final period = billingPeriodFor(_selectedDate,
        billingDay: billingDay, dueDay: card.dueDay);
    final fmt = DateFormat("d 'de' MMMM", 'es_CL');
    return [
      const SizedBox(height: 8),
      Text(
        'Entra en el estado de cuenta que cierra el '
        '${fmt.format(period.closing)}'
        '${period.due == null ? '' : ', con pago el ${fmt.format(period.due!)}'}.',
        style: TextStyle(fontSize: 12, color: context.colors.inkSoft),
      ),
    ];
  }

  /// El método elegido, o null si ya no existe (se borró mientras tanto).
  int? _validPaymentMethodId() {
    final methods = ref.read(paymentMethodsProvider).valueOrNull ?? const [];
    final id = _selectedPaymentMethodId;
    return methods.any((m) => m.id == id) ? id : null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    // initialDate debe caer dentro de [firstDate, lastDate]: al editar un
    // gasto antiguo (o uno restaurado de un respaldo) el rango se amplía en
    // vez de reventar el assert del picker.
    final defaultFirst = DateTime(now.year - 2);
    final firstDate =
        _selectedDate.isBefore(defaultFirst) ? _selectedDate : defaultFirst;
    final lastDate = _selectedDate.isAfter(now) ? _selectedDate : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null) return;
    setState(() {
      _selectedDate =
          DateTime(picked.year, picked.month, picked.day, now.hour, now.minute);
    });
  }

  String _formatSelectedDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    if (day == today) return 'Hoy';
    if (day == today.subtract(const Duration(days: 1))) return 'Ayer';
    return DateFormat('d MMM yyyy', 'es_CL').format(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => LoadError(err),
      data: (all) {
        final categories =
            selectableCategories(all, keep: widget.initialCategoryId);
        if (categories.isEmpty) {
          return const Center(
              child: Text('No hay categorías configuradas todavía.'));
        }
        _selectedCategoryId ??= categories.first.id;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monto', style: _labelStyle),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              margin: const EdgeInsets.only(top: 4, bottom: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: _justSubmitted
                        ? context.colors.green
                        : context.colors.ink,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text('\$', style: appAmountTextStyle.copyWith(fontSize: 22)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      focusNode: _amountFocus,
                      // Actualiza el resumen de cuotas (RF34) al escribir.
                      onChanged: (_) {
                        if (_installmentsController.text.isNotEmpty) {
                          setState(() {});
                        }
                      },
                      keyboardType: TextInputType.number,
                      inputFormatters: amountInputFormatters,
                      textInputAction: TextInputAction.next,
                      style: appAmountTextStyle.copyWith(fontSize: 22),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '0',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Reglas de uso del catálogo, como ayuda al elegir categoría.
            InfoTooltip(
              message: kCategoryUsageRules,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Categoría', style: _labelStyle),
                  const SizedBox(width: 4),
                  const InfoIcon(),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories
                  .map((c) => ExpenseCategoryChip(
                        category: c,
                        selected: c.id == _selectedCategoryId,
                        onTap: () => setState(() {
                          _selectedCategoryId = c.id;
                          _userPickedCategory = true;
                        }),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text('Fecha', style: _labelStyle),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                // Al menos 48 px de alto: área táctil mínima de Android.
                constraints: const BoxConstraints(minHeight: 48),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: context.colors.rule),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 16, color: context.colors.inkSoft),
                    const SizedBox(width: 10),
                    Text(
                      _formatSelectedDate(),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right,
                        size: 16, color: context.colors.inkSoft),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Pagado con', style: _labelStyle),
            const SizedBox(height: 8),
            PaymentMethodPicker(
              selectedId: _selectedPaymentMethodId,
              onSelected: (id) => setState(() {
                _selectedPaymentMethodId = id;
                _userPickedPaymentMethod = true;
              }),
            ),
            ..._billingPeriodHint(),
            if (_installmentsEnabled) ...[
              const SizedBox(height: 12),
              _installmentsField(),
            ],
            const SizedBox(height: 16),
            Text('Nota (opcional)', style: _labelStyle),
            TextField(
              controller: _noteController,
              maxLength: kMaxNoteLength,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                hintText: 'ej. almuerzo con equipo',
              ),
            ),
            const SizedBox(height: 16),
            // Al editar no se ofrece el switch: cambiar el flag no crea ni
            // borra la plantilla recurrente, solo desincronizaría ambos. Las
            // plantillas se administran en "Gastos recurrentes".
            // Una compra en cuotas ya genera sus gastos de los meses
            // siguientes; no puede ser además recurrente.
            if (!widget.isEditing && _installmentChoice() == null) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Gasto recurrente',
                    style: TextStyle(fontSize: 13)),
                subtitle: Text('Se repite cada mes',
                    style:
                        TextStyle(fontSize: 11, color: context.colors.inkSoft)),
                value: _isRecurring,
                activeThumbColor: context.colors.green,
                onChanged: (v) => setState(() => _isRecurring = v),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: Listener(
                onPointerDown: (_) => setState(() => _submitPressed = true),
                onPointerUp: (_) => setState(() => _submitPressed = false),
                onPointerCancel: (_) => setState(() => _submitPressed = false),
                child: AnimatedScale(
                  scale: _submitPressed ? 0.97 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _justSubmitted
                          ? context.colors.green
                          : context.colors.ink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _handleSubmit,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _justSubmitted
                          ? const Row(
                              key: ValueKey('done'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check, size: 18),
                                SizedBox(width: 8),
                                Text('¡Registrado!'),
                              ],
                            )
                          : Text(
                              widget.isEditing
                                  ? 'Guardar cambios'
                                  : 'Registrar gasto',
                              key: const ValueKey('label'),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// RF34: número de cuotas y si el monto es el total o el valor cuota.
  Widget _installmentsField() {
    final choice = _installmentChoice();
    final amount = parsePositiveAmount(_amountController.text);
    String? summary;
    if (choice != null && amount != null) {
      final total = choice.totalFor(amount);
      final amounts = installmentAmounts(total, choice.count);
      summary = '${choice.count} cuotas de ${currencyFmt.format(amounts.first)}'
          '${amounts.last != amounts.first ? ' (la última de ${currencyFmt.format(amounts.last)})' : ''}'
          ' · total ${currencyFmt.format(total)}';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 140,
              child: TextField(
                controller: _installmentsController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Cuotas',
                  hintText: 'Sin cuotas',
                  border: UnderlineInputBorder(),
                ),
              ),
            ),
            if (choice != null)
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: false, label: Text('Monto total')),
                  ButtonSegment(value: true, label: Text('Valor cuota')),
                ],
                selected: {_amountIsPerInstallment},
                onSelectionChanged: (v) =>
                    setState(() => _amountIsPerInstallment = v.single),
              ),
          ],
        ),
        if (summary != null) ...[
          const SizedBox(height: 6),
          Text(summary,
              style: TextStyle(fontSize: 12, color: context.colors.inkSoft)),
        ],
      ],
    );
  }

  TextStyle get _labelStyle =>
      TextStyle(fontSize: 12, color: context.colors.inkSoft);
}

class ExpenseCategoryChip extends StatelessWidget {
  const ExpenseCategoryChip({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });
  final Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.category(category.colorValue);
    return AnimatedScale(
      scale: selected ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? color : context.colors.rule,
                width: selected ? 2 : 1.5,
              ),
              borderRadius: BorderRadius.circular(10),
              color:
                  selected ? color.withValues(alpha: 0.14) : Colors.transparent,
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: selected ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: Icon(
                    iconForCategory(category),
                    size: 18,
                    color: selected ? color : context.colors.inkSoft,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  // UX07: el texto va en tinta y no en el color de la
                  // categoría, que puede no llegar a 4,5:1 sobre el papel (el
                  // usuario elige el color). El color queda en borde e ícono.
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color:
                        selected ? context.colors.ink : context.colors.inkSoft,
                  ),
                  child: Text(category.name),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// RF32: selector de método de pago. "Sin especificar" siempre está, para
/// no obligar a elegir; sin métodos creados, ofrece crear el primero. Lo usa
/// también el editor de gastos habituales (RF47).
class PaymentMethodPicker extends ConsumerWidget {
  const PaymentMethodPicker(
      {super.key, required this.selectedId, required this.onSelected});
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methods = ref.watch(paymentMethodsProvider).valueOrNull ?? const [];
    if (methods.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: context.colors.ink,
            padding: EdgeInsets.zero,
          ),
          onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaymentMethodsScreen())),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Agregar un método de pago',
              style: TextStyle(fontSize: 13)),
        ),
      );
    }
    // Un id que ya no existe se muestra como "Sin especificar".
    final effective =
        methods.any((m) => m.id == selectedId) ? selectedId : null;
    Widget chip(String label, int? id, {Color? color, IconData? icon}) =>
        ChoiceChip(
          label: Text(label),
          avatar: icon == null
              ? null
              : Icon(icon, size: 16, color: color ?? context.colors.inkSoft),
          selected: effective == id,
          showCheckmark: false,
          onSelected: (_) => onSelected(id),
        );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final m in methods)
          chip(paymentMethodLabel(m), m.id,
              color: context.colors.category(m.colorValue),
              icon: paymentKindIcon(m.kind)),
        chip(kNoPaymentMethodLabel, null),
      ],
    );
  }
}
