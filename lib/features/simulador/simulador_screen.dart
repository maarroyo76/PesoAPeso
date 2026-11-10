import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/amount_input.dart';
import '../../core/utils/budget_alert.dart';
import '../../core/utils/formatting.dart';
import '../../core/utils/installments.dart';
import '../../core/utils/projection.dart';
import '../../core/utils/purchase_simulation.dart';
import '../../core/utils/wishlist.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/section_label.dart';
import '../../core/widgets/undo_snack_bar.dart';
import '../../data/local/app_database.dart';
import '../agregar_gasto/expense_form.dart';
import '../categorias/category_filters.dart';
import '../lista_espera/lista_espera_screen.dart';
import '../metodos_pago/payment_method_labels.dart';
import '../metodos_pago/payment_methods_screen.dart';
import '../revision/category_worth_hint.dart';

/// RF57–RF60: simula una compra contra la proyección de los meses
/// siguientes, la compara con otras formas de pago y, si el usuario decide
/// comprar, la registra igual que el formulario de gasto. Nada se escribe en
/// la base antes de "Comprar así" o "Esperar" (RF61).
class SimuladorScreen extends ConsumerStatefulWidget {
  const SimuladorScreen({super.key, this.today, this.wish});

  /// Fecha de referencia; solo para tests. Por defecto, ahora.
  final DateTime? today;

  /// RF62: deseo de la lista de espera que se está decidiendo. Llena el
  /// formulario con sus datos y, al comprar, queda marcado como comprado.
  final WishlistItem? wish;

  @override
  ConsumerState<SimuladorScreen> createState() => _SimuladorScreenState();
}

class _SimuladorScreenState extends ConsumerState<SimuladorScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _countController = TextEditingController();
  final _rateController = TextEditingController();
  String? _categoryId;
  int? _cardId;
  bool _userPickedCard = false;
  bool _buying = false;

  DateTime get _today => widget.today ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    final wish = widget.wish;
    if (wish != null) {
      _amountController.text = formatAmountInput(wish.amount);
      _noteController.text = wish.name;
      if (wish.installmentCount > 1) {
        _countController.text = '${wish.installmentCount}';
      }
      if (wish.monthlyRate > 0) {
        _rateController.text = '${wish.monthlyRate}'
            .replaceAll(RegExp(r'\.0$'), '')
            .replaceAll('.', ',');
      }
      _categoryId = wish.categoryId;
      if (wish.paymentMethodId != null) {
        _cardId = wish.paymentMethodId;
        _userPickedCard = true;
      }
    }
    _preselectCard();
  }

  /// La tarjeta del último gasto con método, si es de crédito.
  Future<void> _preselectCard() async {
    final lastId = await ref
        .read(paymentMethodsRepositoryProvider)
        .lastUsedPaymentMethodId();
    if (!mounted || lastId == null || _userPickedCard) return;
    final methods = ref.read(paymentMethodsProvider).valueOrNull;
    if (methods != null &&
        !methods.any((m) => m.id == lastId && m.kind == kPaymentKindCredit)) {
      return;
    }
    setState(() => _cardId = lastId);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _countController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  int? get _amount => parsePositiveAmount(_amountController.text);

  /// Vacío = al contado. Null si está fuera de 1 a 48.
  int? get _count {
    final text = _countController.text.trim();
    if (text.isEmpty) return 1;
    final n = int.tryParse(text);
    if (n == null || n < kMinSimulatedInstallments || n > kMaxInstallments) {
      return null;
    }
    return n;
  }

  double? get _rate => parseMonthlyRatePercent(_rateController.text);

  TextStyle get _labelStyle =>
      TextStyle(fontSize: 12, color: context.colors.inkSoft);

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final templatesAsync = ref.watch(recurringTemplatesProvider);
    final budgetsAsync = ref.watch(monthlyBudgetsProvider);
    final adjustmentsAsync = ref.watch(monthlyAdjustmentsProvider);
    final methods = ref.watch(paymentMethodsProvider).valueOrNull ?? const [];
    final saved =
        ref.watch(monthContributedProvider(monthOf(_today))).valueOrNull ?? 0;

    final error = categoriesAsync.error ??
        transactionsAsync.error ??
        templatesAsync.error ??
        budgetsAsync.error ??
        adjustmentsAsync.error;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.wish == null
            ? 'Simular una compra'
            : 'Comprar "${widget.wish!.name}"'),
        actions: [
          if (widget.wish == null)
            IconButton(
              tooltip: 'Lista de espera',
              icon: const Icon(Icons.hourglass_empty),
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ListaEsperaScreen())),
            ),
        ],
      ),
      body: SafeArea(
        child: error != null
            ? LoadError(error)
            : !(categoriesAsync.hasValue &&
                    transactionsAsync.hasValue &&
                    templatesAsync.hasValue &&
                    budgetsAsync.hasValue &&
                    adjustmentsAsync.hasValue)
                ? const Center(child: CircularProgressIndicator())
                : _body(
                    categories: selectableCategories(categoriesAsync.value!),
                    cards: methods
                        .where((m) => m.kind == kPaymentKindCredit)
                        .toList(),
                    transactions: transactionsAsync.value!,
                    templates: templatesAsync.value!,
                    budgets: budgetsAsync.value!,
                    adjustments: adjustmentsAsync.value!,
                    saved: saved,
                  ),
      ),
    );
  }

  Widget _body({
    required List<Category> categories,
    required List<PaymentMethod> cards,
    required List<Transaction> transactions,
    required List<RecurringTemplate> templates,
    required List<MonthlyBudget> budgets,
    required List<MonthlyAdjustment> adjustments,
    required int saved,
  }) {
    final amount = _amount;
    final count = _count;
    final rate = _rate;
    final ready = amount != null && count != null && rate != null;

    Projection simulate(PurchaseOption option) => simulatePurchase(
          today: _today,
          purchaseDate: _today,
          installmentAmounts: option.amounts,
          transactions: transactions,
          templates: templates,
          monthlyBudgets: budgets,
          adjustments: adjustments,
          savedThisMonth: saved,
        );

    final option =
        ready ? PurchaseOption(amount, count, ratePercent: rate) : null;
    final projection = option == null ? null : simulate(option);
    // RF59: al contado, 3, 6 y 12 cuotas y la elegida, con la misma tasa.
    final alternatives = [
      if (option != null)
        for (final n in alternativeCounts(option.count))
          if (n == option.count)
            (option, projection!)
          else
            (
              PurchaseOption(option.principal, n, ratePercent: rate!),
              simulate(PurchaseOption(option.principal, n, ratePercent: rate)),
            ),
    ];
    final card = cards.where((c) => c.id == _cardId).firstOrNull;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Text(
          'Mira cómo quedan tus próximos meses antes de comprometerte. '
          'Nada se guarda hasta que elijas comprar.',
          style: TextStyle(fontSize: 14, color: context.colors.inkSoft),
        ),
        const SizedBox(height: 20),
        Text('Precio', style: _labelStyle),
        Container(
          margin: const EdgeInsets.only(top: 4, bottom: 16),
          decoration: BoxDecoration(
            border:
                Border(bottom: BorderSide(color: context.colors.ink, width: 2)),
          ),
          child: Row(
            children: [
              Text('\$', style: appAmountTextStyle.copyWith(fontSize: 22)),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  key: const ValueKey('simulador-precio'),
                  controller: _amountController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: amountInputFormatters,
                  onChanged: (_) => setState(() {}),
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
        Wrap(
          spacing: 24,
          runSpacing: 8,
          children: [
            SizedBox(
              width: 140,
              child: TextField(
                controller: _countController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Cuotas',
                  hintText: 'Al contado',
                  border: const UnderlineInputBorder(),
                  errorText: count == null ? 'De 1 a $kMaxInstallments' : null,
                ),
              ),
            ),
            SizedBox(
              width: 170,
              child: TextField(
                controller: _rateController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  LengthLimitingTextInputFormatter(5),
                ],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Interés mensual',
                  hintText: 'Sin interés',
                  suffixText: '%',
                  border: const UnderlineInputBorder(),
                  errorText: rate == null
                      ? 'Entre 0 y ${kMaxMonthlyRatePercent.toInt()}%'
                      : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Tarjeta de crédito', style: _labelStyle),
        const SizedBox(height: 8),
        _cardPicker(cards),
        const SizedBox(height: 20),
        Text('Categoría', style: _labelStyle),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in categories)
              ExpenseCategoryChip(
                category: c,
                selected: c.id == _categoryId,
                onTap: () => setState(() => _categoryId = c.id),
              ),
          ],
        ),
        // RF68: cómo le ha ido al usuario con gastos de esta categoría.
        CategoryWorthHint(categoryId: _categoryId, today: widget.today),
        const SizedBox(height: 16),
        TextField(
          controller: _noteController,
          maxLength: kMaxNoteLength,
          decoration: const InputDecoration(
            labelText: 'Qué es (opcional)',
            hintText: 'Por ejemplo, notebook',
            border: UnderlineInputBorder(),
            counterText: '',
          ),
        ),
        if (option != null && projection != null) ...[
          const SizedBox(height: 24),
          _OptionSummary(option: option),
          const SizedBox(height: 12),
          _BasisNotice(projection: projection),
          const SizedBox(height: 20),
          const SectionLabel(
            'Mes a mes',
            info: 'Disponible de cada mes = presupuesto total, menos '
                'recurrentes, menos cuotas que ya tienes, menos tu gasto '
                'variable típico (la mediana de los últimos 3 meses). '
                'Este mes parte de lo que ya gastaste.',
          ),
          const SizedBox(height: 12),
          _MonthTable(projection: projection),
          const SizedBox(height: 24),
          const SectionLabel('Otras formas de pagarlo'),
          const SizedBox(height: 8),
          for (final (alt, altProjection) in alternatives)
            _AlternativeRow(
              option: alt,
              projection: altProjection,
              selected: alt.count == option.count,
              onTap: () => setState(() =>
                  _countController.text = alt.isCash ? '' : '${alt.count}'),
            ),
          const SizedBox(height: 24),
          ..._buyButton(option, card),
        ],
      ],
    );
  }

  Widget _cardPicker(List<PaymentMethod> cards) {
    if (cards.isEmpty) {
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
          label: const Text('Agregar una tarjeta de crédito',
              style: TextStyle(fontSize: 13)),
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in cards)
          ChoiceChip(
            label: Text(paymentMethodLabel(c)),
            avatar: Icon(paymentKindIcon(c.kind),
                size: 16, color: context.colors.category(c.colorValue)),
            selected: c.id == _cardId,
            showCheckmark: false,
            onSelected: (_) => setState(() {
              _cardId = c.id;
              _userPickedCard = true;
            }),
          ),
      ],
    );
  }

  /// RF60: "Comprar así", con lo que falta para poder hacerlo.
  List<Widget> _buyButton(PurchaseOption option, PaymentMethod? card) {
    final missing = _categoryId == null
        ? 'Elige una categoría para registrar la compra.'
        : !option.isCash && card == null
            ? 'Elige la tarjeta de crédito para comprar en cuotas.'
            : null;
    return [
      FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: context.colors.ink,
          foregroundColor: context.colors.paper,
          minimumSize: const Size.fromHeight(48),
        ),
        onPressed: missing != null || _buying ? null : () => _buy(option, card),
        child: const Text('Comprar así'),
      ),
      if (missing != null) ...[
        const SizedBox(height: 8),
        Text(missing,
            style: TextStyle(fontSize: 13, color: context.colors.inkSoft)),
      ],
      // RF60/RF61: en vez de comprar, dejarlo en la lista de espera.
      if (widget.wish == null) ...[
        const SizedBox(height: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: context.colors.ink,
            side: BorderSide(color: context.colors.ink),
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: _buying ? null : () => _wait(option, card),
          child: const Text('Esperar'),
        ),
      ],
    ];
  }

  /// RF61: guarda la compra simulada en la lista de espera con el plazo que
  /// elija el usuario.
  Future<void> _wait(PurchaseOption option, PaymentMethod? card) async {
    final note = _noteController.text.trim();
    final choice = await showWaitSheet(context,
        initialName: note.isEmpty
            ? 'Compra de ${currencyFmt.format(option.principal)}'
            : note);
    if (choice == null || !mounted) return;
    final repo = ref.read(wishlistRepositoryProvider);
    final now = DateTime.now();
    final dueAt = wishDueAt(now, choice.period);
    final id = await repo.create(
      name: choice.name,
      amount: option.principal,
      installmentCount: option.count,
      monthlyRate: _rate ?? 0,
      paymentMethodId: card?.id,
      categoryId: _categoryId,
      createdAt: now,
      dueAt: dueAt,
    );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    showUndoSnackBar(
      messenger,
      message: 'En espera hasta el ${wishDueLabel(dueAt)}',
      onUndo: () => repo.deleteUndoable(id),
    );
  }

  /// RF60: registra la compra tal como lo haría el formulario de gasto: en
  /// cuotas, el plan de RF34 con el total de las cuotas (con interés, todas
  /// valen la cuota fija); al contado, un gasto normal.
  Future<void> _buy(PurchaseOption option, PaymentMethod? card) async {
    final categoryId = _categoryId!;
    final note = _noteController.text.trim();
    final date = DateTime.now();
    final host = Navigator.of(context, rootNavigator: true).context;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _buying = true);
    final UndoAction undo;
    int? planIdForWish;
    int? transactionIdForWish;
    if (option.isCash) {
      final txRepo = ref.read(transactionsRepositoryProvider);
      final id = await txRepo.addTransaction(
        categoryId: categoryId,
        amount: option.total,
        date: date,
        note: note,
        paymentMethodId: card?.id,
      );
      undo = () => txRepo.deleteTransaction(id);
      transactionIdForWish = id;
    } else {
      final repo = ref.read(installmentsRepositoryProvider);
      final planId = await repo.createPlan(
        paymentMethodId: card!.id,
        categoryId: categoryId,
        note: note,
        totalAmount: option.total,
        count: option.count,
        purchaseDate: date,
      );
      undo = () => repo.deletePlan(planId);
      planIdForWish = planId;
    }
    // RF62: el deseo queda comprado, enlazado a lo que se creó. Deshacer lo
    // vuelve a la espera antes de borrar la compra.
    final wish = widget.wish;
    final UndoAction undoAll;
    if (wish != null) {
      final wishes = ref.read(wishlistRepositoryProvider);
      await wishes.markBought(wish.id,
          installmentPlanId: planIdForWish,
          transactionId: transactionIdForWish,
          at: date);
      undoAll = () async {
        await wishes.reset(wish.id);
        await undo();
      };
    } else {
      undoAll = undo;
    }
    final alerts =
        await checkBudgetAlerts(ref, categoryId: categoryId, date: date);
    if (!mounted) return;
    Navigator.of(context).pop();
    if (host.mounted) showBudgetAlertBanner(host, alerts);
    showUndoSnackBar(
      messenger,
      message: option.isCash
          ? 'Compra registrada'
          : 'Compra registrada en ${option.count} cuotas',
      onUndo: undoAll,
    );
  }
}

/// Valor de la cuota, total e interés de la forma de pago elegida.
class _OptionSummary extends StatelessWidget {
  const _OptionSummary({required this.option});
  final PurchaseOption option;

  @override
  Widget build(BuildContext context) {
    final amountStyle =
        appAmountTextStyle.copyWith(fontSize: 20, color: context.colors.ink);
    final last = option.amounts.last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          option.isCash
              ? 'Al contado: ${currencyFmt.format(option.total)}'
              : '${option.count} cuotas de '
                  '${currencyFmt.format(option.installment)}',
          style: amountStyle,
        ),
        const SizedBox(height: 4),
        Text(
          [
            if (!option.isCash && last != option.installment)
              'la última de ${currencyFmt.format(last)}',
            if (!option.isCash) 'total ${currencyFmt.format(option.total)}',
            if (option.interest > 0)
              'interés ${currencyFmt.format(option.interest)}'
            else if (!option.isCash)
              'sin interés',
          ].join(' · '),
          style: TextStyle(fontSize: 13, color: context.colors.inkSoft),
        ),
      ],
    );
  }
}

/// Contra qué se compara: presupuesto, gasto típico o nada (RF58).
class _BasisNotice extends ConsumerWidget {
  const _BasisNotice({required this.projection});
  final Projection projection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = TextStyle(fontSize: 13, color: context.colors.inkSoft);
    final history = projection.historyMonths;
    final historyText = history == 0
        ? 'Aún no tienes meses cerrados: el gasto variable de los próximos '
            'meses no se puede estimar.'
        : history < kProjectionHistoryMonths
            ? 'Tu gasto típico se calcula con $history '
                '${history == 1 ? 'mes' : 'meses'} de historial.'
            : null;
    return switch (projection.basis) {
      ProjectionBasis.none => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Define un presupuesto total para ver cuánto te queda cada mes.',
              style: style,
            ),
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: context.colors.ink,
                  padding: EdgeInsets.zero),
              onPressed: () {
                ref.read(selectedTabProvider.notifier).state = 1;
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
              child: const Text('Ir a Presupuestos'),
            ),
          ],
        ),
      ProjectionBasis.spendingMedian => Text(
          'No tienes presupuesto total: se compara con tu gasto típico de '
          '${currencyFmt.format(projection.months.first.reference)} al mes.'
          '${historyText == null ? '' : ' $historyText'}',
          style: style,
        ),
      ProjectionBasis.totalBudget => historyText == null
          ? const SizedBox.shrink()
          : Text(historyText, style: style),
    };
  }
}

/// RF58: disponible de cada mes sin y con la compra; hasta 12 meses y un
/// resumen del resto.
class _MonthTable extends StatelessWidget {
  const _MonthTable({required this.projection});
  final Projection projection;

  @override
  Widget build(BuildContext context) {
    final months = projection.months;
    final visible = months.take(kProjectionVisibleMonths).toList();
    final tail = summarizeTail(months);
    final head = TextStyle(fontSize: 11, color: context.colors.inkSoft);
    return Column(
      children: [
        ExcludeSemantics(
          child: Row(
            children: [
              const Expanded(flex: 4, child: SizedBox.shrink()),
              Expanded(
                  flex: 3,
                  child: Text('Sin la compra',
                      textAlign: TextAlign.right, style: head)),
              Expanded(
                  flex: 3,
                  child: Text('Con la compra',
                      textAlign: TextAlign.right, style: head)),
            ],
          ),
        ),
        Divider(color: context.colors.rule, height: 12),
        for (final m in visible) _MonthRow(month: m),
        if (tail != null) ...[
          Divider(color: context.colors.rule, height: 16),
          Text(
            'Y ${tail.months} meses más, con '
            '${currencyFmt.format(tail.purchase)} en cuotas. '
            '${tail.monthsBelowZero == 0 ? 'Alcanza en todos.' : 'En ${tail.monthsBelowZero} no alcanza: faltan ${currencyFmt.format(tail.totalShortfall)} en total.'}',
            style: TextStyle(fontSize: 13, color: context.colors.inkSoft),
          ),
        ],
      ],
    );
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({required this.month});
  final MonthProjection month;

  @override
  Widget build(BuildContext context) {
    final name = capitalizeMonth(month.month, monthFmt);
    final amount = appAmountTextStyle.copyWith(fontSize: 13);
    Color colorFor(int v) => v < 0 ? context.colors.rust : context.colors.ink;
    final semantics = '$name: sin la compra '
        '${currencyFmt.format(month.availableWithout)}, con la compra '
        '${currencyFmt.format(month.availableWith)}'
        '${month.belowZero ? ', faltan ${currencyFmt.format(month.shortfall)}' : ''}';
    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Expanded(
                    flex: 4,
                    child: Text(name, style: const TextStyle(fontSize: 14))),
                Expanded(
                  flex: 3,
                  child: Text(currencyFmt.format(month.availableWithout),
                      textAlign: TextAlign.right,
                      style: amount.copyWith(
                          color: colorFor(month.availableWithout))),
                ),
                Expanded(
                  flex: 3,
                  child: Text(currencyFmt.format(month.availableWith),
                      textAlign: TextAlign.right,
                      style: amount.copyWith(
                          color: colorFor(month.availableWith),
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            if (month.belowZero)
              Text('Faltan ${currencyFmt.format(month.shortfall)}',
                  style: TextStyle(fontSize: 12, color: context.colors.rust)),
          ],
        ),
      ),
    );
  }
}

/// RF59: una forma de pago alternativa con su costo y si alcanza.
class _AlternativeRow extends StatelessWidget {
  const _AlternativeRow({
    required this.option,
    required this.projection,
    required this.selected,
    required this.onTap,
  });
  final PurchaseOption option;
  final Projection projection;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final below = projection.months.where((m) => m.belowZero).toList();
    final worst = below.fold(0, (w, m) => m.shortfall > w ? m.shortfall : w);
    final title = option.isCash
        ? 'Al contado'
        : '${option.count} cuotas de ${currencyFmt.format(option.installment)}';
    final cost = option.interest > 0
        ? 'Total ${currencyFmt.format(option.total)} · interés '
            '${currencyFmt.format(option.interest)}'
        : 'Total ${currencyFmt.format(option.total)}';
    final outcome = below.isEmpty
        ? 'Alcanza'
        : '${below.length} ${below.length == 1 ? 'mes' : 'meses'} sin '
            'alcanzar · faltan hasta ${currencyFmt.format(worst)}';
    return Semantics(
      selected: selected,
      button: true,
      label: '$title. $cost. $outcome',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? context.colors.ink : context.colors.rule,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: appAmountTextStyle.copyWith(
                        fontSize: 14, color: context.colors.ink)),
                const SizedBox(height: 2),
                Text(cost,
                    style:
                        TextStyle(fontSize: 13, color: context.colors.inkSoft)),
                const SizedBox(height: 2),
                Text(outcome,
                    style: TextStyle(
                        fontSize: 13,
                        color: below.isEmpty
                            ? context.colors.green
                            : context.colors.rust)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
