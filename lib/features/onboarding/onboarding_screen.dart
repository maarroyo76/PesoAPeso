import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/category_icons.dart';
import '../../core/utils/formatting.dart';
import '../../data/local/app_database.dart';
import '../agregar_gasto/expense_form.dart' show ExpenseCategoryChip;
import '../categorias/categorias_screen.dart'
    show confirmDeleteCategory, showCategoryEditor;

/// RF23: clave en AppSettings que marca el recorrido inicial como
/// completado (u omitido). Las instalaciones que ya existían antes de
/// agregar este flujo se marcan como completadas en la migración de
/// `schemaVersion` (ver app_database.dart) — no les debe aparecer.
const kOnboardingCompletedKey = 'onboarding_completed';

/// RF23: recorrido de configuración inicial, guiado y omitible paso a paso —
/// presupuesto mensual total, presupuestos por categoría, una meta de
/// ahorro opcional y un pago recurrente opcional.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _totalSteps = 4;
  final _pageController = PageController();
  int _step = 0;
  bool _busy = false;

  final _totalBudgetController = TextEditingController();
  bool _totalBudgetPrefilled = false;
  final Map<String, TextEditingController> _categoryControllers = {};

  final _goalNameController = TextEditingController();
  final _goalTargetController = TextEditingController();

  String? _recurringCategoryId;
  final _recurringAmountController = TextEditingController();
  final _recurringNoteController = TextEditingController();
  final _recurringDayController = TextEditingController(text: '1');

  DateTime get _currentMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _totalBudgetController.dispose();
    for (final c in _categoryControllers.values) {
      c.dispose();
    }
    _goalNameController.dispose();
    _goalTargetController.dispose();
    _recurringAmountController.dispose();
    _recurringNoteController.dispose();
    _recurringDayController.dispose();
    super.dispose();
  }

  TextEditingController _controllerForCategory(
      String categoryId, int currentValue) {
    return _categoryControllers.putIfAbsent(
      categoryId,
      () => TextEditingController(
          text: currentValue > 0 ? currentValue.toString() : ''),
    );
  }

  void _goToNextOrFinish() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
      _pageController.animateToPage(_step,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  void _handleSkip() => _goToNextOrFinish();

  void _goBack() {
    if (_step == 0) return;
    setState(() => _step--);
    _pageController.animateToPage(_step,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  Future<void> _handleContinue(List<Category> categories) async {
    setState(() => _busy = true);
    switch (_step) {
      case 0:
        final val = int.tryParse(_totalBudgetController.text);
        if (val != null && val >= 0) {
          await ref
              .read(categoriesRepositoryProvider)
              .setMonthlyBudgetForMonth(_currentMonth, val);
        }
        break;
      case 1:
        for (final c in categories) {
          final controller = _categoryControllers[c.id];
          final val = controller == null ? null : int.tryParse(controller.text);
          if (val != null && val >= 0) {
            await ref
                .read(categoriesRepositoryProvider)
                .setBudgetForMonth(c.id, _currentMonth, val);
          }
        }
        break;
      case 2:
        final name = _goalNameController.text.trim();
        final target = int.tryParse(_goalTargetController.text);
        if (name.isNotEmpty && target != null && target > 0) {
          await ref
              .read(savingsRepositoryProvider)
              .createGoal(name: name, targetAmount: target);
        }
        break;
      case 3:
        final amount = int.tryParse(_recurringAmountController.text);
        final day = int.tryParse(_recurringDayController.text);
        if (_recurringCategoryId != null &&
            amount != null &&
            amount > 0 &&
            day != null &&
            day >= 1 &&
            day <= 31) {
          await ref.read(recurringTemplatesRepositoryProvider).createTemplate(
                categoryId: _recurringCategoryId!,
                amount: amount,
                note: _recurringNoteController.text,
                dayOfMonth: day,
                initialYearMonth:
                    _currentMonth.year * 100 + _currentMonth.month,
              );
        }
        break;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _goToNextOrFinish();
  }

  Future<void> _finish() async {
    await ref
        .read(settingsRepositoryProvider)
        .set(kOnboardingCompletedKey, 'true');
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (categories) {
            if (!_totalBudgetPrefilled) {
              final total = ref.read(monthTotalBudgetProvider(_currentMonth));
              _totalBudgetController.text = total > 0 ? total.toString() : '';
              _totalBudgetPrefilled = true;
            }
            final budgets = ref.read(monthBudgetsProvider(_currentMonth));
            // Ahora que las categorías se pueden crear/eliminar en el paso 2
            // (RF23), la seleccionada acá podría haber sido borrada.
            if (_recurringCategoryId == null ||
                !categories.any((c) => c.id == _recurringCategoryId)) {
              _recurringCategoryId =
                  categories.isNotEmpty ? categories.first.id : null;
            }

            return Column(
              children: [
                _ProgressHeader(step: _step, totalSteps: _totalSteps),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _StepTotalBudget(controller: _totalBudgetController),
                      _StepCategoryBudgets(
                        categories: categories,
                        controllerFor: (id) =>
                            _controllerForCategory(id, budgets[id] ?? 0),
                        totalBudgetController: _totalBudgetController,
                      ),
                      _StepGoal(
                        nameController: _goalNameController,
                        targetController: _goalTargetController,
                      ),
                      _StepRecurring(
                        categories: categories,
                        selectedCategoryId: _recurringCategoryId,
                        onCategorySelected: (id) =>
                            setState(() => _recurringCategoryId = id),
                        amountController: _recurringAmountController,
                        dayController: _recurringDayController,
                        noteController: _recurringNoteController,
                      ),
                    ],
                  ),
                ),
                _BottomBar(
                  isLastStep: _step == _totalSteps - 1,
                  showBack: _step > 0,
                  busy: _busy,
                  onBack: _busy ? null : _goBack,
                  onSkip: _busy ? null : _handleSkip,
                  onContinue: _busy ? null : () => _handleContinue(categories),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.step, required this.totalSteps});
  final int step;
  final int totalSteps;

  static const _titles = [
    'Presupuesto del mes',
    'Presupuesto por categoría',
    'Meta de ahorro',
    'Pago recurrente',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PASO ${step + 1} DE $totalSteps',
              style: const TextStyle(
                  fontSize: 10, letterSpacing: 1.2, color: AppColors.inkSoft)),
          const SizedBox(height: 6),
          Text(_titles[step],
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 14),
          Row(
            children: List.generate(totalSteps, (i) {
              final active = i <= step;
              return Expanded(
                child: Container(
                  height: 3,
                  margin: EdgeInsets.only(right: i == totalSteps - 1 ? 0 : 4),
                  decoration: BoxDecoration(
                    color: active ? AppColors.green : AppColors.rule,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.isLastStep,
    required this.showBack,
    required this.busy,
    required this.onBack,
    required this.onSkip,
    required this.onContinue,
  });
  final bool isLastStep;
  final bool showBack;
  final bool busy;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: AppColors.inkSoft),
              tooltip: 'Atrás',
            ),
          TextButton(
            onPressed: onSkip,
            child: const Text('Omitir',
                style: TextStyle(color: AppColors.inkSoft)),
          ),
          const Spacer(),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.ink,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            onPressed: onContinue,
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(isLastStep ? 'Finalizar' : 'Continuar'),
          ),
        ],
      ),
    );
  }
}

class _StepTotalBudget extends StatelessWidget {
  const _StepTotalBudget({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Cuánto quieres gastar como máximo este mes, en total? Es tu '
            'presupuesto general — puedes cambiarlo cuando quieras desde '
            'Presupuestos.',
            style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
            style: appAmountTextStyle.copyWith(
                fontSize: 26, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              prefixText: '\$ ',
              border: UnderlineInputBorder(),
              hintText: '0',
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCategoryBudgets extends ConsumerWidget {
  const _StepCategoryBudgets({
    required this.categories,
    required this.controllerFor,
    required this.totalBudgetController,
  });
  final List<Category> categories;
  final TextEditingController Function(String categoryId) controllerFor;
  final TextEditingController totalBudgetController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryControllers =
        categories.map((c) => controllerFor(c.id)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Text(
                'Cuánto quieres presupuestar en cada categoría esencial. Puedes '
                'dejarlas en blanco y asignarlas después, y crear o editar '
                'categorías acá mismo.',
                style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline,
                  color: AppColors.inkSoft),
              tooltip: 'Nueva categoría',
              onPressed: () => showCategoryEditor(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // RF22: mismo aviso de sobre-asignación que Presupuestos, pero
        // en vivo mientras se completa el onboarding — así no se sale de
        // este paso con las categorías sumando más que el total del paso 1.
        AnimatedBuilder(
          animation:
              Listenable.merge([totalBudgetController, ...categoryControllers]),
          builder: (context, _) {
            final total = int.tryParse(totalBudgetController.text) ?? 0;
            final assigned = categoryControllers.fold<int>(
                0, (a, c) => a + (int.tryParse(c.text) ?? 0));
            final overAllocated = total > 0 && assigned > total;
            return Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.paperDeep,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: overAllocated ? AppColors.rust : AppColors.rule),
              ),
              child: Row(
                children: [
                  Icon(
                    overAllocated
                        ? Icons.warning_amber_outlined
                        : Icons.info_outline,
                    size: 16,
                    color: overAllocated ? AppColors.rust : AppColors.inkSoft,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      overAllocated
                          ? 'Asignaste ${currencyFmt.format(assigned)} en categorías, '
                              'pero tu presupuesto total es ${currencyFmt.format(total)}. '
                              'Baja alguna categoría o vuelve al paso anterior y sube el total.'
                          : 'Asignado a categorías: ${currencyFmt.format(assigned)}'
                              '${total > 0 ? ' de ${currencyFmt.format(total)}' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            overAllocated ? AppColors.rust : AppColors.inkSoft,
                        fontWeight:
                            overAllocated ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (categories.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No hay categorías todavía. Toca "+" para crear una.',
                style: TextStyle(color: AppColors.inkSoft, fontSize: 13)),
          )
        else
          ...categories.map((c) {
            final color = Color(c.colorValue);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => showCategoryEditor(context, ref, category: c),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(iconForCategory(c), size: 18, color: color),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () =>
                          showCategoryEditor(context, ref, category: c),
                      child: Text(c.name,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                  ),
                  SizedBox(
                    width: 110,
                    child: TextField(
                      controller: controllerFor(c.id),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.end,
                      decoration: const InputDecoration(
                        prefixText: '\$ ',
                        border: UnderlineInputBorder(),
                        hintText: '0',
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: AppColors.inkSoft),
                    onPressed: () => confirmDeleteCategory(context, ref, c),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _StepGoal extends StatelessWidget {
  const _StepGoal(
      {required this.nameController, required this.targetController});
  final TextEditingController nameController;
  final TextEditingController targetController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Opcional. Si ya tienes algo en mente (ej. vacaciones, un fondo de '
            'emergencia), créalo ahora — si no, omite este paso y crea metas '
            'después desde la pestaña Metas.',
            style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
                labelText: 'Nombre de la meta', border: UnderlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: targetController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Monto objetivo',
              prefixText: '\$ ',
              border: UnderlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRecurring extends StatelessWidget {
  const _StepRecurring({
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.amountController,
    required this.dayController,
    required this.noteController,
  });
  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<String> onCategorySelected;
  final TextEditingController amountController;
  final TextEditingController dayController;
  final TextEditingController noteController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Opcional. Si tienes un pago fijo cada mes (ej. arriendo, una '
            'suscripción), créalo ahora y la app lo registrará sola cada mes '
            '— si no, omite este paso.',
            style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
                border: UnderlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: dayController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
                labelText: 'Día del mes (1-31)',
                border: UnderlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: noteController,
            decoration: const InputDecoration(
                labelText: 'Nota (ej. Arriendo)',
                border: UnderlineInputBorder()),
          ),
          const SizedBox(height: 16),
          const Text('Categoría',
              style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
          const SizedBox(height: 8),
          if (categories.isEmpty)
            const Text('No hay categorías todavía.',
                style: TextStyle(color: AppColors.inkSoft, fontSize: 12))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories
                  .map((c) => ExpenseCategoryChip(
                        category: c,
                        selected: c.id == selectedCategoryId,
                        onTap: () => onCategorySelected(c.id),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}
