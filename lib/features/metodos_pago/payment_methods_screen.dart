import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/amount_input.dart';
import '../../core/widgets/load_error.dart';
import '../../data/local/app_database.dart';
import '../categorias/categorias_screen.dart' show kCategoryColorPalette;
import 'payment_method_labels.dart';

/// RF31: crear, editar y eliminar métodos de pago.
class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodsAsync = ref.watch(paymentMethodsProvider);

    return Scaffold(
      backgroundColor: context.colors.paper,
      appBar: AppBar(
        title: const Text('Métodos de pago'),
        actions: [
          IconButton(
            tooltip: 'Nuevo método de pago',
            icon: const Icon(Icons.add),
            onPressed: () => showPaymentMethodEditor(context, ref),
          ),
        ],
      ),
      body: methodsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => LoadError(e),
        data: (methods) => methods.isEmpty
            ? _EmptyMethods(onAdd: () => showPaymentMethodEditor(context, ref))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: methods.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 20),
                itemBuilder: (context, i) {
                  final m = methods[i];
                  final color = context.colors.category(m.colorValue);
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          Icon(paymentKindIcon(m.kind), color: color, size: 18),
                    ),
                    title: Text(paymentMethodLabel(m),
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(_subtitle(m),
                        style: TextStyle(
                            fontSize: 12, color: context.colors.inkSoft)),
                    onTap: () =>
                        showPaymentMethodEditor(context, ref, method: m),
                    trailing: IconButton(
                      tooltip: 'Eliminar ${m.alias}',
                      icon: Icon(Icons.delete_outline,
                          color: context.colors.inkSoft),
                      onPressed: () => _confirmDelete(context, ref, m),
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _subtitle(PaymentMethod m) {
    final parts = [paymentKindLabel(m.kind)];
    if (m.billingDay != null) parts.add('factura el ${m.billingDay}');
    if (m.dueDay != null) parts.add('paga el ${m.dueDay}');
    return parts.join(' · ');
  }
}

class _EmptyMethods extends StatelessWidget {
  const _EmptyMethods({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aún no tienes métodos de pago',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.colors.ink)),
          const SizedBox(height: 4),
          Text(
            'Agrega tu efectivo, tarjeta de débito o de crédito para saber '
            'con qué pagas cada gasto. Solo se guarda el nombre que le des y, '
            'si quieres, los últimos 4 dígitos.',
            style: TextStyle(fontSize: 13, color: context.colors.inkSoft),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: context.colors.ink),
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Agregar método de pago'),
          ),
        ],
      ),
    );
  }
}

/// Día del mes (1–31) escrito en [text], o null si está vacío o es inválido.
int? _parseDay(String text) {
  final n = int.tryParse(text);
  return n != null && n >= 1 && n <= 31 ? n : null;
}

/// RF31/RF33: crear o editar un método de pago.
Future<void> showPaymentMethodEditor(BuildContext context, WidgetRef ref,
    {PaymentMethod? method}) async {
  final aliasController = TextEditingController(text: method?.alias ?? '');
  final last4Controller = TextEditingController(text: method?.last4 ?? '');
  final billingController =
      TextEditingController(text: method?.billingDay?.toString() ?? '');
  final dueController =
      TextEditingController(text: method?.dueDay?.toString() ?? '');
  var kind = method?.kind ?? kPaymentKindDebit;
  var color = method?.colorValue ?? kCategoryColorPalette[2];
  String? aliasError;
  String? dayError;

  final digitsOnly = [FilteringTextInputFormatter.digitsOnly];
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: context.colors.paper,
        title: Text(
            method == null ? 'Nuevo método de pago' : 'Editar método de pago',
            style: TextStyle(fontSize: 16, color: context.colors.ink)),
        content: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: aliasController,
                  autofocus: method == null,
                  maxLength: kMaxNameLength,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'ej. CMR, Débito Santander',
                    errorText: aliasError,
                    border: const UnderlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final k in kPaymentKinds)
                      ChoiceChip(
                        label: Text(paymentKindLabel(k)),
                        avatar: Icon(paymentKindIcon(k), size: 16),
                        selected: kind == k,
                        showCheckmark: false,
                        onSelected: (_) => setDialogState(() => kind = k),
                      ),
                  ],
                ),
                if (kind != kPaymentKindCash)
                  TextField(
                    controller: last4Controller,
                    keyboardType: TextInputType.number,
                    // RNF16: a lo más 4 números; nunca el número completo.
                    inputFormatters: [
                      ...digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Últimos 4 dígitos (opcional)',
                      helperText: 'Nunca se guarda el número completo',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                if (kind == kPaymentKindCredit) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: billingController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            ...digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Día de facturación',
                            border: UnderlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: dueController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            ...digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Día de pago',
                            border: UnderlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      dayError ?? 'Opcionales, entre 1 y 31.',
                      style: TextStyle(
                          fontSize: 12,
                          color: dayError != null
                              ? context.colors.rust
                              : context.colors.inkSoft),
                    ),
                  ),
                ],
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
                      final selected = cv == color;
                      return Center(
                        child: Semantics(
                          button: true,
                          selected: selected,
                          label: 'Color ${i + 1} de '
                              '${kCategoryColorPalette.length}',
                          child: GestureDetector(
                            onTap: () => setDialogState(() => color = cv),
                            child: Container(
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
              final alias = aliasController.text.trim();
              final taken = (ref.read(paymentMethodsProvider).valueOrNull ??
                      const <PaymentMethod>[])
                  .any((m) =>
                      m.id != method?.id &&
                      m.alias.trim().toLowerCase() == alias.toLowerCase());
              final badDay = kind == kPaymentKindCredit &&
                  [
                    billingController,
                    dueController
                  ].any((c) => c.text.isNotEmpty && _parseDay(c.text) == null);
              setDialogState(() {
                aliasError = alias.isEmpty
                    ? 'Ponle un nombre'
                    : taken
                        ? 'Ya existe un método con ese nombre'
                        : null;
                dayError = badDay ? 'Los días van entre 1 y 31.' : null;
              });
              if (aliasError != null || dayError != null) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );

  if (result != true) return;
  final alias = aliasController.text.trim();
  final last4 = kind == kPaymentKindCash || last4Controller.text.isEmpty
      ? null
      : last4Controller.text;
  final billingDay = _parseDay(billingController.text);
  final dueDay = _parseDay(dueController.text);
  final repo = ref.read(paymentMethodsRepositoryProvider);
  if (method == null) {
    await repo.createPaymentMethod(
        alias: alias,
        kind: kind,
        colorValue: color,
        last4: last4,
        billingDay: billingDay,
        dueDay: dueDay);
  } else {
    await repo.updatePaymentMethod(method.id,
        alias: alias,
        kind: kind,
        colorValue: color,
        last4: last4,
        billingDay: billingDay,
        dueDay: dueDay);
  }
}

/// RF31: no se puede eliminar un método con gastos asociados, igual que
/// las categorías.
Future<void> _confirmDelete(
    BuildContext context, WidgetRef ref, PaymentMethod method) async {
  final repo = ref.read(paymentMethodsRepositoryProvider);
  final canDelete = await repo.canDeletePaymentMethod(method.id);
  if (!context.mounted) return;

  if (!canDelete) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.paper,
        title: Text('No se puede eliminar',
            style: TextStyle(fontSize: 16, color: context.colors.ink)),
        content: Text(
          '"${method.alias}" tiene gastos asociados. Cámbiales el método de '
          'pago o elimínalos primero.',
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
      title: Text('Eliminar método de pago',
          style: TextStyle(fontSize: 16, color: context.colors.ink)),
      content: Text('¿Eliminar "${method.alias}"?',
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
  if (confirmed == true) await repo.deletePaymentMethod(method.id);
}
