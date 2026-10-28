import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/categories_repository.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../utils/budget_resolver.dart';
import '../utils/daily_allowance.dart';
import '../utils/formatting.dart';

/// Clave en AppSettings con el mes (yyyyMM) en que el usuario eligió "Aún
/// no sé" en el onboarding. Vacía cuando ya se sugirió el presupuesto.
const kBudgetUnknownMonthKey = 'budget_unknown_month';

/// Onboarding: el usuario no fijó presupuesto en [month]; al cerrar ese mes
/// se le sugiere uno según lo que gastó.
Future<void> markBudgetUnknown(WidgetRef ref, DateTime month) => ref
    .read(settingsRepositoryProvider)
    .set(kBudgetUnknownMonthKey, '${month.year * 100 + month.month}');

/// Presupuesto sugerido a partir de lo gastado: redondeado hacia arriba a
/// los $10.000, para dejar algo de margen.
int suggestedBudget(int spent) => (spent + 9999) ~/ 10000 * 10000;

/// El mes que corresponde revisar: el marcado con "Aún no sé", si ya
/// terminó y el usuario todavía no fijó un presupuesto total después.
Future<DateTime?> pendingBudgetSuggestionMonth({
  required String? stored,
  required CategoriesRepository categories,
  required DateTime today,
}) async {
  final ym = int.tryParse(stored ?? '');
  if (ym == null) return null;
  final month = DateTime(ym ~/ 100, ym % 100);
  final current = DateTime(today.year, today.month);
  if (!month.isBefore(current)) return null;
  final budget = resolveMonthlyBudgetForMonth(
      await categories.watchAllMonthlyBudgets().first, current);
  return budget > 0 ? null : month;
}

/// Al abrir la app en un mes nuevo, si el primero quedó sin presupuesto,
/// propone usar lo gastado en él (redondeado) como presupuesto total.
/// Se pregunta una sola vez.
Future<void> checkBudgetSuggestion(BuildContext context, WidgetRef ref) async {
  final settings = ref.read(settingsRepositoryProvider);
  final categories = ref.read(categoriesRepositoryProvider);
  final now = DateTime.now();
  final month = await pendingBudgetSuggestionMonth(
    stored: await settings.get(kBudgetUnknownMonthKey),
    categories: categories,
    today: now,
  );
  if (month == null) return;
  await settings.set(kBudgetUnknownMonthKey, '');
  final spent = budgetSpent(await ref
      .read(transactionsRepositoryProvider)
      .watchTransactionsForMonth(month)
      .first);
  if (spent <= 0 || !context.mounted) return;
  final suggestion = suggestedBudget(spent);

  final accept = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: context.colors.paper,
      title: Text('¿Fijamos tu presupuesto?',
          style: TextStyle(fontSize: 16, color: context.colors.ink)),
      content: Text(
        'En ${monthFmt.format(month)} gastaste ${currencyFmt.format(spent)}. '
        '¿Usamos ${currencyFmt.format(suggestion)} como presupuesto mensual? '
        'Puedes cambiarlo cuando quieras en Presupuestos.',
        style: TextStyle(color: context.colors.inkSoft, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child:
              Text('Ahora no', style: TextStyle(color: context.colors.inkSoft)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: context.colors.ink),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('Usar ${currencyFmt.format(suggestion)}'),
        ),
      ],
    ),
  );
  if (accept == true) {
    await categories.setMonthlyBudgetForMonth(
        DateTime(now.year, now.month), suggestion);
  }
}
