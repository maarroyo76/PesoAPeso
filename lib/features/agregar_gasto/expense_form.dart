import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/category_icons.dart';
import '../../core/utils/formatting.dart';
import '../../data/local/app_database.dart';

typedef ExpenseFormSubmit = Future<void> Function({
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

  final ExpenseFormSubmit onSubmit;

  /// Se llama después de un guardado exitoso, solo relevante en modo edición
  /// (para que la pantalla que aloja el formulario pueda cerrarse).
  final VoidCallback? onSaved;

  @override
  ConsumerState<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<ExpenseForm> {
  late final _amountController =
      TextEditingController(text: widget.initialAmount?.toString() ?? '');
  late final _noteController = TextEditingController(text: widget.initialNote);
  String? _selectedCategoryId;
  late DateTime _selectedDate = widget.initialDate ?? DateTime.now();
  late bool _isRecurring = widget.initialRecurring;
  bool _justSubmitted = false;
  bool _submitPressed = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<bool> _confirmAdd(int amount, String categoryId) async {
    final categories = ref.read(categoriesProvider).valueOrNull ?? const [];
    Category? category;
    for (final c in categories) {
      if (c.id == categoryId) {
        category = c;
        break;
      }
    }
    final note = _noteController.text.trim();
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.paper,
            title: const Text('Confirmar gasto',
                style: TextStyle(fontSize: 16, color: AppColors.ink)),
            content: Text(
              '${currencyFmt.format(amount)} en '
              '${category?.name ?? 'categoría desconocida'}'
              '${note.isNotEmpty ? ' — $note' : ''}',
              style: const TextStyle(color: AppColors.inkSoft),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar',
                    style: TextStyle(color: AppColors.inkSoft)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Registrar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _handleSubmit() async {
    final amount = int.tryParse(_amountController.text) ?? 0;
    final categoryId = _selectedCategoryId;
    if (amount <= 0 || categoryId == null) return;

    if (!widget.isEditing) {
      final confirmed = await _confirmAdd(amount, categoryId);
      if (!confirmed || !mounted) return;
    }

    await widget.onSubmit(
      categoryId: categoryId,
      amount: amount,
      date: _selectedDate,
      note: _noteController.text,
      recurring: _isRecurring,
    );
    if (!mounted) return;

    if (widget.isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cambios guardados'),
          duration: Duration(milliseconds: 900),
          backgroundColor: AppColors.ink,
        ),
      );
      widget.onSaved?.call();
      return;
    }

    _amountController.clear();
    _noteController.clear();
    setState(() {
      _isRecurring = false;
      _selectedDate = DateTime.now();
      _justSubmitted = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Registrado — ${currencyFmt.format(amount)}'),
        duration: const Duration(milliseconds: 900),
        backgroundColor: AppColors.ink,
      ),
    );
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _justSubmitted = false);
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
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
      error: (err, _) =>
          Center(child: Text('Error al cargar categorías: $err')),
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
                    color: _justSubmitted ? AppColors.green : AppColors.ink,
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
                      keyboardType: TextInputType.number,
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
                        onTap: () => setState(() => _selectedCategoryId = c.id),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.rule),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: AppColors.inkSoft),
                    const SizedBox(width: 10),
                    Text(
                      _formatSelectedDate(),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                        size: 16, color: AppColors.inkSoft),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Nota (opcional)', style: _labelStyle),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                hintText: 'ej. almuerzo con equipo',
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Gasto recurrente',
                  style: TextStyle(fontSize: 13)),
              subtitle: const Text('Se repite cada mes',
                  style: TextStyle(fontSize: 11, color: AppColors.inkSoft)),
              value: _isRecurring,
              activeThumbColor: AppColors.green,
              onChanged: (v) => setState(() => _isRecurring = v),
            ),
            const SizedBox(height: 16),
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
                      backgroundColor:
                          _justSubmitted ? AppColors.green : AppColors.ink,
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

  static const _labelStyle = TextStyle(fontSize: 12, color: AppColors.inkSoft);
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
    final color = Color(category.colorValue);
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
                color: selected ? color : AppColors.rule,
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
                    color: selected ? color : AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected ? color : AppColors.inkSoft,
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
