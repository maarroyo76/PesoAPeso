import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/category_icons.dart';
import '../../core/utils/amount_input.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/undo_snack_bar.dart';
import '../../core/widgets/load_error.dart';
import '../../data/local/app_database.dart';

/// Guarda el gasto. Al registrar uno nuevo devuelve cómo deshacerlo (UX01);
/// al editar devuelve null.
typedef ExpenseFormSubmit = Future<UndoAction?> Function({
  required String categoryId,
  required int amount,
  required DateTime date,
  required String note,
  required bool recurring,
});

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
    this.isEditing = false,
    this.focusAmount = false,
    required this.onSubmit,
    this.onSaved,
  });

  final int? initialAmount;
  final String? initialCategoryId;
  final DateTime? initialDate;
  final String initialNote;
  final bool initialRecurring;

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

  @override
  ConsumerState<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<ExpenseForm> {
  late final _amountController = TextEditingController(
      text: widget.initialAmount == null
          ? ''
          : formatAmountInput(widget.initialAmount!));
  late final _noteController = TextEditingController(text: widget.initialNote);
  final _amountFocus = FocusNode();
  String? _selectedCategoryId;
  late DateTime _selectedDate = widget.initialDate ?? DateTime.now();
  late bool _isRecurring = widget.initialRecurring;
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
    if (categories != null && !categories.any((c) => c.id == lastId)) return;
    if (_userPickedCategory) return;
    setState(() => _selectedCategoryId = lastId);
  }

  bool _userPickedCategory = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_submitting) return;
    final amount = parsePositiveAmount(_amountController.text);
    final categoryId = _selectedCategoryId;
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
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _justSubmitted = false);
    });
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
      data: (categories) {
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
            Text('Categoría', style: _labelStyle),
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
            if (!widget.isEditing) ...[
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
