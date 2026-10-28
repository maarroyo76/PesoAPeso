import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/startup/budget_suggestion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/category_icons.dart';
import '../../core/utils/amount_input.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/load_error.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/backup_repository.dart';
import '../agregar_gasto/expense_form.dart';

/// RF23: clave en AppSettings que marca el recorrido inicial como
/// completado (u omitido). Las instalaciones que ya existían antes de
/// agregar este flujo se marcan como completadas en la migración de
/// `schemaVersion` (ver app_database.dart) — no les debe aparecer.
const kOnboardingCompletedKey = 'onboarding_completed';

/// RF23 (rediseño): bienvenida con la promesa de privacidad, presupuesto
/// total (o "Aún no sé"), elección de categorías y un primer gasto, que es
/// cuando se entiende para qué sirve la app. La meta de ahorro y los pagos
/// recurrentes se sugieren después, en contexto.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _Step { welcome, budget, categories, firstExpense }

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  _Step _step = _Step.welcome;
  bool _busy = false;

  final _totalController = TextEditingController();
  String? _totalError;

  /// null hasta que cargan las categorías: entonces parte con las
  /// preseleccionadas (las no archivadas del catálogo).
  Set<String>? _selected;
  final Map<String, TextEditingController> _amountControllers = {};

  DateTime get _month {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  @override
  void dispose() {
    _totalController.dispose();
    for (final c in _amountControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _go(_Step step) => setState(() => _step = step);

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish() async {
    await ref
        .read(settingsRepositoryProvider)
        .set(kOnboardingCompletedKey, 'true');
    widget.onDone();
  }

  // --- Bienvenida -----------------------------------------------------------

  /// Quien cambia de teléfono restaura su respaldo de inmediato, sin crear
  /// datos que la restauración luego borraría.
  Future<void> _restoreBackup() => _run(() async {
        final messenger = ScaffoldMessenger.of(context);
        final rust = context.colors.rust;
        try {
          final Uint8List? bytes = await BackupRepository.pickBackupFile();
          if (bytes == null) return;
          await ref.read(backupRepositoryProvider).restoreFromBytes(bytes);
          await _finish();
        } on FormatException catch (e) {
          messenger.showSnackBar(
              SnackBar(content: Text(e.message), backgroundColor: rust));
        } catch (_) {
          messenger.showSnackBar(SnackBar(
              content: const Text(
                  'No se pudo restaurar el respaldo. Inténtalo de nuevo.'),
              backgroundColor: rust));
        }
      });

  // --- Presupuesto total ----------------------------------------------------

  Future<void> _saveTotal() async {
    final value = parseAmountText(_totalController.text);
    if (value == null || value <= 0) {
      setState(() => _totalError = 'Ingresa un monto, o elige "Aún no sé".');
      return;
    }
    await _run(() => ref
        .read(categoriesRepositoryProvider)
        .setMonthlyBudgetForMonth(_month, value));
    _go(_Step.categories);
  }

  /// Sin presupuesto el primer mes: al cerrarlo, la app sugiere uno según lo
  /// que el usuario gastó de verdad.
  Future<void> _budgetUnknown() async {
    await _run(() => markBudgetUnknown(ref, _month));
    _go(_Step.categories);
  }

  // --- Categorías -----------------------------------------------------------

  TextEditingController _amountFor(String id) =>
      _amountControllers.putIfAbsent(id, TextEditingController.new);

  /// Reparte el total en partes iguales entre las elegidas, redondeando
  /// hacia abajo a miles; lo que sobra queda sin asignar.
  void _splitTotal(List<Category> chosen) {
    final total = parseAmountText(_totalController.text) ?? 0;
    if (total <= 0 || chosen.isEmpty) return;
    final each = total ~/ chosen.length ~/ 1000 * 1000;
    setState(() {
      for (final c in chosen) {
        _amountFor(c.id).text = each > 0 ? formatAmountInput(each) : '';
      }
    });
  }

  Future<void> _saveCategories() async {
    final selected = _selected ?? {};
    if (selected.isEmpty) return;
    await _run(() async {
      final repo = ref.read(categoriesRepositoryProvider);
      await repo.setActiveCategories(selected);
      for (final id in selected) {
        final value = parseAmountText(_amountFor(id).text);
        if (value != null && value > 0) {
          await repo.setBudgetForMonth(id, _month, value);
        }
      }
    });
    _go(_Step.firstExpense);
  }

  // --- Primer gasto ---------------------------------------------------------

  ({String categoryId, int amount, String note})? _firstExpense;

  Future<void> _offerQuickAccess() async {
    final expense = _firstExpense;
    if (expense == null) return _finish();
    final categories = ref.read(categoriesProvider).valueOrNull ?? const [];
    final categoryName =
        categories.where((c) => c.id == expense.categoryId).firstOrNull?.name ??
            '';
    final labelController = TextEditingController(
        text: expense.note.trim().isNotEmpty
            ? expense.note.trim()
            : categoryName);
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.paper,
        title: Text('¿Lo guardas como acceso rápido?',
            style: TextStyle(fontSize: 16, color: context.colors.ink)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'La próxima vez lo registras con un toque, por '
              '${currencyFmt.format(expense.amount)}.',
              style: TextStyle(fontSize: 13, color: context.colors.inkSoft),
            ),
            TextField(
              controller: labelController,
              maxLength: kMaxNameLength,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('No, gracias',
                style: TextStyle(color: context.colors.inkSoft)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.colors.ink),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar acceso'),
          ),
        ],
      ),
    );
    final label = labelController.text.trim();
    if (save == true && label.isNotEmpty) {
      await ref.read(quickExpenseTemplatesRepositoryProvider).create(
          label: label, amount: expense.amount, categoryId: expense.categoryId);
    }
    await _finish();
  }

  // --- Pantalla -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return Scaffold(
      backgroundColor: context.colors.paper,
      body: SafeArea(
        child: categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => LoadError(e),
          data: (categories) {
            _selected ??= {
              for (final c in categories)
                if (!c.archived) c.id
            };
            return switch (_step) {
              _Step.welcome => _Welcome(
                  busy: _busy,
                  onStart: () => _go(_Step.budget),
                  onRestore: _restoreBackup,
                ),
              _Step.budget => _StepPage(
                  step: 1,
                  title: 'Presupuesto del mes',
                  onBack: () => _go(_Step.welcome),
                  actions: [
                    TextButton(
                      onPressed: _busy ? null : _budgetUnknown,
                      child: const Text('Aún no sé'),
                    ),
                    _PrimaryButton(
                        label: 'Continuar', busy: _busy, onPressed: _saveTotal),
                  ],
                  children: [
                    const _Hint(
                        '¿Cuánto quieres gastar como máximo este mes, en '
                        'total? Si todavía no lo sabes, elige "Aún no sé": '
                        'al terminar el mes te sugerimos un presupuesto '
                        'según lo que gastaste.'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _totalController,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: amountInputFormatters,
                      style: appAmountTextStyle.copyWith(fontSize: 22),
                      onChanged: (_) {
                        if (_totalError != null) {
                          setState(() => _totalError = null);
                        }
                      },
                      decoration: InputDecoration(
                        prefixText: '\$ ',
                        hintText: '0',
                        errorText: _totalError,
                      ),
                    ),
                  ],
                ),
              _Step.categories => _categoriesStep(categories),
              _Step.firstExpense => _StepPage(
                  step: 3,
                  title: 'Tu primer gasto',
                  onBack: () => _go(_Step.categories),
                  actions: [
                    TextButton(
                      onPressed: _busy ? null : _finish,
                      child: const Text('Lo hago después'),
                    ),
                  ],
                  children: [
                    const _Hint(
                        'Así registras cada gasto: el monto, la categoría '
                        'y listo. Anota algo que hayas pagado hoy.'),
                    const SizedBox(height: 16),
                    ExpenseForm(
                      focusAmount: true,
                      onSubmit: ({
                        required categoryId,
                        required amount,
                        required date,
                        required note,
                        required recurring,
                        required paymentMethodId,
                        required installments,
                      }) async {
                        final txRepo = ref.read(transactionsRepositoryProvider);
                        final id = await txRepo.addTransaction(
                          categoryId: categoryId,
                          amount: amount,
                          date: date,
                          note: note,
                          paymentMethodId: paymentMethodId,
                        );
                        _firstExpense = (
                          categoryId: categoryId,
                          amount: amount,
                          note: note,
                        );
                        return () async {
                          await txRepo.deleteTransaction(id);
                        };
                      },
                      onRegistered: _offerQuickAccess,
                    ),
                  ],
                ),
            };
          },
        ),
      ),
    );
  }

  Widget _categoriesStep(List<Category> categories) {
    final selected = _selected!;
    final chosen = categories.where((c) => selected.contains(c.id)).toList();
    return _StepPage(
      step: 2,
      title: 'Tus categorías',
      onBack: () => _go(_Step.budget),
      actions: [
        _PrimaryButton(
          label: 'Continuar',
          busy: _busy,
          onPressed: selected.isEmpty ? null : _saveCategories,
        ),
      ],
      children: [
        const _Hint('Elige en qué gastas. Las que no elijas quedan guardadas y '
            'las activas cuando quieras desde Ajustes › Categorías.'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in categories)
              FilterChip(
                avatar: Icon(iconForCategory(c),
                    size: 16, color: context.colors.category(c.colorValue)),
                label: Text(c.name),
                selected: selected.contains(c.id),
                onSelected: (on) => setState(
                    () => on ? selected.add(c.id) : selected.remove(c.id)),
              ),
          ],
        ),
        if (selected.isEmpty) ...[
          const SizedBox(height: 8),
          Text('Elige al menos una.',
              style: TextStyle(fontSize: 12, color: context.colors.rust)),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text('PRESUPUESTO POR CATEGORÍA (OPCIONAL)',
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      color: context.colors.inkSoft)),
            ),
            if ((parseAmountText(_totalController.text) ?? 0) > 0 &&
                chosen.isNotEmpty)
              TextButton(
                onPressed: () => _splitTotal(chosen),
                child: const Text('Repartir el total'),
              ),
          ],
        ),
        for (final c in chosen)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(iconForCategory(c),
                    size: 18, color: context.colors.category(c.colorValue)),
                const SizedBox(width: 10),
                Expanded(child: Text(c.name)),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _amountFor(c.id),
                    keyboardType: TextInputType.number,
                    inputFormatters: amountInputFormatters,
                    textAlign: TextAlign.right,
                    style: appAmountTextStyle,
                    decoration: const InputDecoration(
                        prefixText: '\$ ', hintText: '0', isDense: true),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({
    required this.busy,
    required this.onStart,
    required this.onRestore,
  });
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final points = [
      (Icons.edit_note, 'Anota cada gasto en segundos y ve cuánto te queda.'),
      (Icons.lock_outline, 'Tus datos quedan solo en este teléfono, cifrados.'),
      (Icons.link_off, 'Sin conectar tu banco ni crear una cuenta.'),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Peso a Peso',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Tu libro de gastos, peso a peso.',
              style: TextStyle(fontSize: 15, color: context.colors.inkSoft)),
          const SizedBox(height: 32),
          for (final (icon, text) in points)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: context.colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(text,
                          style: TextStyle(
                              fontSize: 14, color: context.colors.ink))),
                ],
              ),
            ),
          const SizedBox(height: 24),
          _PrimaryButton(label: 'Empezar', busy: false, onPressed: onStart),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.ink,
              side: BorderSide(color: context.colors.rule),
            ),
            onPressed: busy ? null : onRestore,
            icon: const Icon(Icons.file_upload_outlined),
            label: const Text('Restaurar respaldo'),
          ),
        ],
      ),
    );
  }
}

/// Un paso numerado: encabezado con progreso, contenido desplazable y
/// botones abajo.
class _StepPage extends StatelessWidget {
  const _StepPage({
    required this.step,
    required this.title,
    required this.onBack,
    required this.actions,
    required this.children,
  });

  static const _totalSteps = 3;
  final int step;
  final String title;
  final VoidCallback onBack;
  final List<Widget> actions;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 24, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: Icon(Icons.arrow_back, color: context.colors.inkSoft),
                tooltip: 'Atrás',
              ),
              Text('PASO $step DE $_totalSteps',
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      color: context.colors.inkSoft)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              Row(
                children: List.generate(_totalSteps, (i) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin:
                          EdgeInsets.only(right: i == _totalSteps - 1 ? 0 : 4),
                      decoration: BoxDecoration(
                        color: i < step
                            ? context.colors.green
                            : context.colors.rule,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: children,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: actions,
          ),
        ),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: TextStyle(color: context.colors.inkSoft, fontSize: 13));
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });
  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: context.colors.ink,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
      onPressed: busy ? null : onPressed,
      child: busy
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: context.colors.paper),
            )
          : Text(label),
    );
  }
}
