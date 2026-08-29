import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/category_icons.dart';
import '../../data/local/app_database.dart';

/// RF03: crear, editar y eliminar categorías.
const kCategoryColorPalette = <int>[
  0xFF2F6F4E,
  0xFFB8842E,
  0xFF3B6B78,
  0xFF6B3F5C,
  0xFF4B7A3E,
  0xFF8A5A2B,
  0xFFA63D2B,
  0xFF5C6B54,
  0xFF7A4B8A,
  0xFF2B6B8A,
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
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('Categorías'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showCategoryEditor(context, ref),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (categories) => categories.isEmpty
            ? const Center(
                child: Text('No hay categorías todavía.',
                    style: TextStyle(color: AppColors.inkSoft)))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: categories.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 20),
                itemBuilder: (context, i) {
                  final c = categories[i];
                  final color = Color(c.colorValue);
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
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.inkSoft),
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

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text(category == null ? 'Nueva categoría' : 'Editar categoría',
            style: const TextStyle(fontSize: 16, color: AppColors.ink)),
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
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: UnderlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('COLOR',
                    style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        color: AppColors.inkSoft)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: kCategoryColorPalette.map((cv) {
                    final selected = cv == selectedColor;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = cv),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(cv),
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(color: AppColors.ink, width: 2)
                              : null,
                        ),
                        child: selected
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text('ÍCONO',
                    style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        color: AppColors.inkSoft)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kSelectableCategoryIcons.entries.map((entry) {
                    final selected = entry.key == selectedIconKey;
                    final previewColor = Color(selectedColor);
                    return GestureDetector(
                      onTap: () =>
                          setDialogState(() => selectedIconKey = entry.key),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: selected
                              ? previewColor.withAlpha(40)
                              : AppColors.paperDeep,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected ? previewColor : AppColors.rule,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Icon(entry.value,
                            size: 18,
                            color: selected ? previewColor : AppColors.inkSoft),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
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
              if (nameController.text.trim().isEmpty) return;
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
        backgroundColor: AppColors.paper,
        title: const Text('No se puede eliminar',
            style: TextStyle(fontSize: 16, color: AppColors.ink)),
        content: Text(
          '"${category.name}" tiene gastos, recurrentes o accesos rápidos asociados. '
          'Elimina o reasigna esos elementos primero.',
          style: const TextStyle(color: AppColors.inkSoft),
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
      backgroundColor: AppColors.paper,
      title: const Text('Eliminar categoría',
          style: TextStyle(fontSize: 16, color: AppColors.ink)),
      content: Text(
          '¿Eliminar "${category.name}"? Esta acción no se puede deshacer.',
          style: const TextStyle(color: AppColors.inkSoft)),
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
    await ref.read(categoriesRepositoryProvider).deleteCategory(category.id);
  }
}
