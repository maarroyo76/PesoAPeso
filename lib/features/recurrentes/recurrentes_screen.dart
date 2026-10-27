import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/category_icons.dart';
import '../../core/utils/amount_input.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/undo_snack_bar.dart';
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
      backgroundColor: context.colors.paper,
      appBar: AppBar(title: const Text('Gastos recurrentes')),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => LoadError(e),
        data: (templates) => categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => LoadError(e),
          data: (categories) {
            final categoriesById = {for (final c in categories) c.id: c};
            if (templates.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No tienes gastos recurrentes todavía. Se crean desde '
                    '"Agregar" marcando "Gasto recurrente".',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: context.colors.inkSoft, fontSize: 13),
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
                  onTap: () => showRecurringEditor(context, ref, categories,
                      template: tpl),
                  onDelete: () => _delete(context, ref, tpl),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// UX02: elimina sin diálogo y ofrece deshacer. Los gastos ya generados
  /// se mantienen; solo se detienen los futuros.
  Future<void> _delete(
      BuildContext context, WidgetRef ref, RecurringTemplate template) async {
    final messenger = ScaffoldMessenger.of(context);
    final undo = await ref
        .read(recurringTemplatesRepositoryProvider)
        .deleteTemplateUndoable(template.id);
    showUndoSnackBar(messenger,
        message:
            'Recurrente eliminado. Los gastos ya registrados se mantienen.',
        onUndo: undo);
  }
}

/// Editor de una plantilla recurrente. Público para abrirlo también desde un
/// gasto generado por ella (I4: "Ver recurrente" en EditTransactionScreen).
Future<void> showRecurringEditor(
  BuildContext context,
  WidgetRef ref,
  List<Category> categories, {
  required RecurringTemplate template,
}) async {
  final amountController =
      TextEditingController(text: formatAmountInput(template.amount));
  final noteController = TextEditingController(text: template.note);
  final dayController =
      TextEditingController(text: template.dayOfMonth.toString());
  var selectedCategoryId = template.categoryId;
  var active = template.active;
  String? amountError;
  String? dayError;

  final save = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: context.colors.paper,
        title: Text('Editar recurrente',
            style: TextStyle(fontSize: 16, color: context.colors.ink)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: amountInputFormatters,
                decoration: InputDecoration(
                    labelText: 'Monto',
                    prefixText: '\$ ',
                    errorText: amountError,
                    border: const UnderlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dayController,
                keyboardType: TextInputType.number,
                inputFormatters: dayInputFormatters,
                decoration: InputDecoration(
                    labelText: 'Día del mes (1-31)',
                    errorText: dayError,
                    border: const UnderlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLength: kMaxNoteLength,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    labelText: 'Nota (opcional)',
                    border: UnderlineInputBorder()),
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
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Activo', style: TextStyle(fontSize: 13)),
                subtitle: Text('Si lo pausas, deja de generarse cada mes',
                    style:
                        TextStyle(fontSize: 11, color: context.colors.inkSoft)),
                value: active,
                activeThumbColor: context.colors.green,
                onChanged: (v) => setDialogState(() => active = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TextStyle(color: context.colors.inkSoft)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.colors.ink),
            onPressed: () {
              final amount = parsePositiveAmount(amountController.text);
              final day = int.tryParse(dayController.text);
              final dayInvalid = day == null || day < 1 || day > 31;
              if (amount == null || dayInvalid) {
                setDialogState(() {
                  amountError = amount == null ? kInvalidAmountMessage : null;
                  dayError = dayInvalid ? 'Ingresa un día entre 1 y 31' : null;
                });
                return;
              }
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
        amount: parseAmountText(amountController.text)!,
        note: noteController.text,
        dayOfMonth: int.parse(dayController.text),
        active: active,
      );
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
    final color = context.colors.category(category.colorValue);
    return Semantics(
      // UX08: deslizar no está disponible con lector de pantalla; la misma
      // acción se ofrece en el menú de acciones de TalkBack / VoiceOver.
      customSemanticsActions: {
        const CustomSemanticsAction(label: 'Eliminar'): onDelete,
      },
      child: Dismissible(
        key: ValueKey(template.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: context.colors.rust,
          child: Icon(Icons.delete_outline, color: context.colors.paper),
        ),
        child: ListTile(
          onTap: onTap,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
          title: Text(
            template.note.isNotEmpty ? template.note : category.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // "Pausado" va en el subtítulo, que puede envolver: junto al título
          // no cabía con letra grande.
          subtitle: Text(
              '${template.active ? '' : 'Pausado · '}'
              'Día ${template.dayOfMonth} de cada mes · ${category.name}',
              style: TextStyle(fontSize: 11, color: context.colors.inkSoft)),
          trailing: Text(
            currencyFmt.format(template.amount),
            style: appAmountTextStyle.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color:
                  template.active ? context.colors.ink : context.colors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}
