// Editar un gasto de más de 2 años de antigüedad abre el selector de fecha
// sin reventar el assert initialDate >= firstDate.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:peso_a_peso/core/providers/app_providers.dart';
import 'package:peso_a_peso/data/local/app_database.dart';
import 'package:peso_a_peso/features/agregar_gasto/expense_form.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_CL', null));

  testWidgets('abre el selector de fecha con un gasto de hace 5 años',
      (tester) async {
    const category = Category(
        id: 'ocio', name: 'Ocio', colorValue: 0xFF6B3F5C, iconKey: 'theaters');
    final old = DateTime.now().subtract(const Duration(days: 365 * 5));

    await tester.pumpWidget(ProviderScope(
      overrides: [
        categoriesProvider.overrideWith((ref) => Stream.value([category])),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ExpenseForm(
              isEditing: true,
              initialAmount: 1000,
              initialCategoryId: 'ocio',
              initialDate: old,
              onSubmit: ({
                required categoryId,
                required amount,
                required date,
                required note,
                required recurring,
              }) async {},
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  Widget form({required bool editing, required void Function() onSubmit}) {
    const category = Category(
        id: 'ocio', name: 'Ocio', colorValue: 0xFF6B3F5C, iconKey: 'theaters');
    return ProviderScope(
      overrides: [
        categoriesProvider.overrideWith((ref) => Stream.value([category])),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ExpenseForm(
              isEditing: editing,
              onSubmit: ({
                required categoryId,
                required amount,
                required date,
                required note,
                required recurring,
              }) async =>
                  onSubmit(),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('monto vacío muestra aviso y no envía', (tester) async {
    var submitted = 0;
    await tester.pumpWidget(form(editing: false, onSubmit: () => submitted++));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Registrar gasto'));
    await tester.pump();

    expect(find.text('Ingresa un monto mayor a 0'), findsOneWidget);
    expect(submitted, 0);
  });

  testWidgets('el campo de monto agrupa miles y descarta signos', (tester) async {
    await tester.pumpWidget(form(editing: false, onSubmit: () {}));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '1.500-');
    expect(find.text('1.500'), findsOneWidget);
  });

  testWidgets('al editar no se ofrece el switch de recurrente',
      (tester) async {
    await tester.pumpWidget(form(editing: true, onSubmit: () {}));
    await tester.pumpAndSettle();
    expect(find.text('Gasto recurrente'), findsNothing);

    await tester.pumpWidget(form(editing: false, onSubmit: () {}));
    await tester.pumpAndSettle();
    expect(find.text('Gasto recurrente'), findsOneWidget);
  });

  testWidgets('los campos tienen tope de largo (monto 9 dígitos, nota 120)',
      (tester) async {
    await tester.pumpWidget(form(editing: false, onSubmit: () {}));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '1234567890123');
    await tester.enterText(fields.at(1), 'n' * 500);
    await tester.pump();

    expect(find.text('123.456.789'), findsOneWidget);
    final note = tester.widget<TextField>(fields.at(1));
    expect(note.controller!.text.length, 120);
  });
}
