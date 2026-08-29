import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/category_icons.dart';
import '../../core/utils/formatting.dart';
import '../../data/local/app_database.dart';
import '../agregar_gasto/expense_form.dart' show ExpenseCategoryChip;

/// RF25: ver, editar y eliminar los pagos recurrentes ya creados (RF12) —
/// antes solo se podían crear desde AgregarScreen, y quedaban invisibles.
class RecurrentesScreen extends ConsumerWidget {
  const RecurrentesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(recurringTemplatesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Gastos recurrentes')),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (templates) => categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (categories) {
            final categoriesById = {for (final c in categories) c.id: c};
            if (templates.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No tienes gastos recurrentes todavía. Se crean desde '
                    '"Agregar" marcando "Gasto recurrente".',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: templates.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 20),
              itemBuilder: (context, i) {
                final tpl = templates[i];
                final category = categoriesById[tpl.categoryId];
                if (category == null) return const SizedBox.shrink();
                return _RecurringTile(
                  template: tpl,
                  category: category,
                  onTap: () =>
                      _showEditor(context, ref, categories, template: tpl),
                  onDelete: () => _confirmDelete(context, ref, tpl, category),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref,
      RecurringTemplate template, Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: const Text('Eliminar recurrente',
            style: TextStyle(fontSize: 16, color: AppColors.ink)),
        content: Text(
          '¿Eliminar el pago recurrente de ${currencyFmt.format(template.amount)} '
          'en "${category.name}"? No se borran los gastos ya generados, solo se '
          'detienen los futuros.',
          style: const TextStyle(color: AppColors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.inkSoft)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.rust),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(recurringTemplatesRepositoryProvider)
          .deleteTemplate(template.id);
    }
  }

  Future<void> _showEditor(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories, {
    required RecurringTemplate template,
  }) async {
    final amountController =
        TextEditingController(text: template.amount.toString());
    final noteController = TextEditingController(text: template.note);
    final dayController =
        TextEditingController(text: template.dayOfMonth.toString());
    var selectedCategoryId = template.categoryId;
    var active = template.active;

    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.paper,
          title: const Text('Editar recurrente',
              style: TextStyle(fontSize: 16, color: AppColors.ink)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Monto',
                      prefixText: '\$ ',
                      border: UnderlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dayController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                      labelText: 'Día del mes (1-31)',
                      border: UnderlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                      labelText: 'Nota (opcional)',
                      border: UnderlineInputBorder()),
                ),
                const SizedBox(height: 16),
                const Text('Categoría',
                    style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
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
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activo', style: TextStyle(fontSize: 13)),
                  subtitle: const Text(
                      'Si lo pausas, deja de generarse cada mes',
                      style: TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                  value: active,
                  activeThumbColor: AppColors.green,
                  onChanged: (v) => setDialogState(() => active = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.inkSoft)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
              onPressed: () {
                final amount = int.tryParse(amountController.text);
                final day = int.tryParse(dayController.text);
                if (amount == null || amount <= 0) return;
                if (day == null || day < 1 || day > 31) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (save != true) return;
    await ref.read(recurringTemplatesRepositoryProvider).updateTemplate(
          template.id,
          categoryId: selectedCategoryId,
          amount: int.parse(amountController.text),
          note: noteController.text,
          dayOfMonth: int.parse(dayController.text),
          active: active,
        );
  }
}

class _RecurringTile extends StatelessWidget {
  const _RecurringTile({
    required this.template,
    required this.category,
    required this.onTap,
    required this.onDelete,
  });
  final RecurringTemplate template;
  final Category category;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);
    return Dismissible(
      key: ValueKey(template.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false; // onDelete ya pregunta confirmación y borra si aplica.
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.rust,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 3,
              height: 36,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(iconForCategory(category), color: color, size: 18),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                template.note.isNotEmpty ? template.note : category.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!template.active)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Text('Pausado',
                    style: TextStyle(fontSize: 10, color: AppColors.inkSoft)),
              ),
          ],
        ),
        subtitle: Text(
            'Día ${template.dayOfMonth} de cada mes · ${category.name}',
            style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
        trailing: Text(
          currencyFmt.format(template.amount),
          style: appAmountTextStyle.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: template.active ? AppColors.ink : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}
