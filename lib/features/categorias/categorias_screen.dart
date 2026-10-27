import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/utils/amount_input.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/category_icons.dart';
import '../../core/widgets/load_error.dart';
import '../../data/local/app_database.dart';

/// RF03: crear, editar y eliminar categorías.
///
/// Se eligen a mano (no una rueda de color libre) para que toda categoría
/// quede en un tono "tinta de cuaderno" — mismo nivel de saturación/brillo
/// que el resto de la paleta ledger, nunca un color que desentone. El
/// selector es un slider horizontal (ver `showCategoryEditor`), así que
/// agregar más opciones no alarga el diálogo.
const kCategoryColorPalette = <int>[
  0xFF2F6F4E, // verde
  0xFFB8842E, // ocre/dorado
  0xFF3B6B78, // teal
  0xFF6B3F5C, // ciruela
  0xFF4B7A3E, // oliva
  0xFF8A5A2B, // marrón
  0xFFA63D2B, // terracota
  0xFF5C6B54, // salvia
  0xFF7A4B8A, // violeta
  0xFF2B6B8A, // azul
  0xFF4B4B8A, // índigo
  0xFF8A7A2B, // mostaza
  0xFF8A2B45, // vino
  0xFF2B8A7A, // esmeralda
  0xFF6B4B2B, // nogal
  0xFF3F5C3F, // bosque
  0xFF4B6B8A, // azul pizarra
  0xFF8A3F6B, // frambuesa
  0xFFA65C3D, // cobre
  0xFF5C4B8A, // lavanda oscuro
];

String _slugifyCategoryName(String name, List<String> existingIds) {
  var base = name.trim().toLowerCase();
  const accented = 'áéíóúñàèìòùäëïöü';
  const plain = 'aeiounaeiouaeiou';
  for (var i = 0; i < accented.length; i++) {
    base = base.replaceAll(accented[i], plain[i]);
  }
  base = base
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  if (base.isEmpty) base = 'categoria';
  var id = base;
  var n = 2;
  while (existingIds.contains(id)) {
    id = '${base}_$n';
    n++;
  }
  return id;
}

class CategoriasScreen extends ConsumerWidget {
  const CategoriasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: context.colors.paper,
      appBar: AppBar(
        title: const Text('Categorías'),
        actions: [
          IconButton(
            tooltip: 'Nueva categoría',
            icon: const Icon(Icons.add),
            onPressed: () => showCategoryEditor(context, ref),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => LoadError(e),
        data: (categories) => categories.isEmpty
            ? Center(
                child: Text('No hay categorías todavía.',
                    style: TextStyle(color: context.colors.inkSoft)))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: categories.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 20),
                itemBuilder: (context, i) {
                  final c = categories[i];
                  final color = context.colors.category(c.colorValue);
                  return ListTile(
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
                          child:
                              Icon(iconForCategory(c), color: color, size: 18),
                        ),
                      ],
                    ),
                    title: Text(c.name,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    onTap: () => showCategoryEditor(context, ref, category: c),
                    trailing: IconButton(
                      tooltip: 'Eliminar ${c.name}',
                      icon: Icon(Icons.delete_outline,
                          color: context.colors.inkSoft),
                      onPressed: () => confirmDeleteCategory(context, ref, c),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

/// RF03/RF23: crear o editar una categoría (nombre + color). Se usa desde
/// CategoriasScreen y también desde el paso 2 del onboarding.
Future<void> showCategoryEditor(BuildContext context, WidgetRef ref,
    {Category? category}) async {
  final nameController = TextEditingController(text: category?.name ?? '');
  var selectedColor = category?.colorValue ?? kCategoryColorPalette.first;
  var selectedIconKey =
      category?.iconKey ?? kSelectableCategoryIcons.keys.first;
  final iconEntries = kSelectableCategoryIcons.entries.toList();
  String? nameError;

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: context.colors.paper,
        title: Text(category == null ? 'Nueva categoría' : 'Editar categoría',
            style: TextStyle(fontSize: 16, color: context.colors.ink)),
        content: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  maxLength: kMaxNameLength,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    errorText: nameError,
                    border: const UnderlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text('COLOR',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        color: context.colors.inkSoft)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: kCategoryColorPalette.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final cv = kCategoryColorPalette[i];
                      final selected = cv == selectedColor;
                      return Center(
                        child: Semantics(
                          button: true,
                          selected: selected,
                          label: 'Color ${i + 1} de '
                              '${kCategoryColorPalette.length}',
                          child: GestureDetector(
                            onTap: () =>
                                setDialogState(() => selectedColor = cv),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: context.colors.category(cv),
                                shape: BoxShape.circle,
                                border: selected
                                    ? Border.all(
                                        color: context.colors.ink, width: 2)
                                    : null,
                              ),
                              child: selected
                                  ? Icon(Icons.check,
                                      size: 16, color: context.colors.paper)
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Text('ÍCONO',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        color: context.colors.inkSoft)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: iconEntries.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final entry = iconEntries[i];
                      final selected = entry.key == selectedIconKey;
                      final previewColor = Color(selectedColor);
                      return Center(
                        child: Semantics(
                          button: true,
                          selected: selected,
                          label: 'Ícono '
                              '${kCategoryIconLabels[entry.key] ?? entry.key}',
                          child: GestureDetector(
                            onTap: () => setDialogState(
                                () => selectedIconKey = entry.key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: selected
                                    ? previewColor.withAlpha(40)
                                    : context.colors.paperDeep,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selected
                                      ? previewColor
                                      : context.colors.rule,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Icon(entry.value,
                                  size: 18,
                                  color: selected
                                      ? previewColor
                                      : context.colors.inkSoft),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
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
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final taken = (ref.read(categoriesProvider).valueOrNull ??
                      const <Category>[])
                  .any((c) =>
                      c.id != category?.id &&
                      c.name.trim().toLowerCase() == name.toLowerCase());
              if (taken) {
                setDialogState(() => nameError = 'Ya existe una categoría así');
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

  if (result != true) return;
  final name = nameController.text.trim();
  final repo = ref.read(categoriesRepositoryProvider);
  if (category == null) {
    final existingIds =
        ref.read(categoriesProvider).valueOrNull?.map((c) => c.id).toList() ??
            const [];
    final id = _slugifyCategoryName(name, existingIds);
    await repo.createCategory(
        id: id,
        name: name,
        colorValue: selectedColor,
        iconKey: selectedIconKey);
  } else {
    await repo.updateCategoryInfo(category.id,
        name: name, colorValue: selectedColor, iconKey: selectedIconKey);
  }
}

/// RF03/RF23: confirma y elimina una categoría, bloqueando el borrado si
/// tiene gastos asociados. Se usa desde CategoriasScreen y el onboarding.
Future<void> confirmDeleteCategory(
    BuildContext context, WidgetRef ref, Category category) async {
  final canDelete = await ref
      .read(categoriesRepositoryProvider)
      .canDeleteCategory(category.id);
  if (!context.mounted) return;

  if (!canDelete) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.paper,
        title: Text('No se puede eliminar',
            style: TextStyle(fontSize: 16, color: context.colors.ink)),
        content: Text(
          '"${category.name}" tiene gastos, recurrentes o accesos rápidos asociados. '
          'Elimina o reasigna esos elementos primero.',
          style: TextStyle(color: context.colors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: context.colors.paper,
      title: Text('Eliminar categoría',
          style: TextStyle(fontSize: 16, color: context.colors.ink)),
      content: Text(
          '¿Eliminar "${category.name}"? Esta acción no se puede deshacer.',
          style: TextStyle(color: context.colors.inkSoft)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child:
              Text('Cancelar', style: TextStyle(color: context.colors.inkSoft)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: context.colors.rust),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await ref.read(categoriesRepositoryProvider).deleteCategory(category.id);
  }
}
