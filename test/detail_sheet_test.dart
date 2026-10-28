// UX02: la hoja de detalle tiene su propio ScaffoldMessenger, para que el
// aviso "Deshacer" se vea sobre la hoja y no detrás de ella.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:peso_a_peso/core/providers/app_providers.dart';
import 'package:peso_a_peso/core/widgets/undo_snack_bar.dart';
import 'package:peso_a_peso/data/local/app_database.dart';
import 'package:peso_a_peso/features/resumen/transaction_detail_sheet.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_CL', null));

  testWidgets('el aviso de la hoja se muestra dentro de la hoja',
      (tester) async {
    const category = Category(
        id: 'ocio',
        name: 'Ocio',
        colorValue: 0xFF6B3F5C,
        iconKey: 'theaters',
        archived: false);
    final month = DateTime(2026, 10);
    final tx = Transaction(
        id: 1,
        categoryId: 'ocio',
        amount: 15000,
        date: DateTime(2026, 10, 3, 21, 30),
        note: 'Cine',
        isRecurring: false);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        monthTransactionsProvider.overrideWith((ref, m) => Stream.value([tx])),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => TransactionDetailSheet(
                    category: category, month: month, transactions: [tx]),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ));
    final semantics = tester.ensureSemantics();
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Cine'), findsOneWidget);

    // UX08: deslizar para eliminar también existe como acción del lector de
    // pantalla.
    expect(
        tester.getSemantics(find
            .ancestor(of: find.text('Cine'), matching: find.byType(Semantics))
            .first),
        isSemantics(
            customActions: [const CustomSemanticsAction(label: 'Eliminar')]));

    final sheetMessenger = tester.state<ScaffoldMessengerState>(find.descendant(
      of: find.byType(TransactionDetailSheet),
      matching: find.byType(ScaffoldMessenger),
    ));
    showUndoSnackBar(sheetMessenger,
        message: 'Gasto eliminado', onUndo: () async {});
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byType(TransactionDetailSheet),
            matching: find.text('Deshacer')),
        findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    semantics.dispose();
  });
}
