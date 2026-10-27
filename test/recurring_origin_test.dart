// I4: un gasto generado por una plantilla recurrente muestra "Ver recurrente"
// al editarlo; un gasto manual no.

import 'dart:ffi';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqlite3/open.dart';
import 'package:peso_a_peso/core/providers/app_providers.dart';
import 'package:peso_a_peso/data/local/app_database.dart';
import 'package:peso_a_peso/features/agregar_gasto/edit_transaction_screen.dart';

void main() {
  setUpAll(() async {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    await initializeDateFormatting('es_CL', null);
  });

  const category = Category(
      id: 'vivienda',
      name: 'Vivienda',
      colorValue: 0xFF3B6B78,
      iconKey: 'home');
  const template = RecurringTemplate(
    id: 7,
    categoryId: 'vivienda',
    amount: 300000,
    note: 'Arriendo',
    dayOfMonth: 5,
    active: true,
    lastGeneratedYearMonth: 202610,
  );

  Future<void> pumpEdit(WidgetTester tester, Transaction tx) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        categoriesProvider.overrideWith((ref) => Stream.value([category])),
        paymentMethodsProvider
            .overrideWith((ref) => Stream.value(<PaymentMethod>[])),
        recurringTemplatesProvider
            .overrideWith((ref) => Stream.value([template])),
      ],
      child: MaterialApp(home: EditTransactionScreen(transaction: tx)),
    ));
    await tester.pumpAndSettle();
  }

  Transaction tx({int? templateId}) => Transaction(
        id: 1,
        categoryId: 'vivienda',
        amount: 300000,
        date: DateTime(2026, 10, 5),
        note: 'Arriendo',
        isRecurring: templateId != null,
        recurringTemplateId: templateId,
      );

  testWidgets('gasto generado por plantilla: abre el editor del recurrente',
      (tester) async {
    await pumpEdit(tester, tx(templateId: 7));
    expect(find.text('Ver recurrente'), findsOneWidget);

    await tester.tap(find.text('Ver recurrente'));
    await tester.pumpAndSettle();
    expect(find.text('Editar recurrente'), findsOneWidget);
  });

  testWidgets('gasto manual: sin enlace a recurrente', (tester) async {
    await pumpEdit(tester, tx());
    expect(find.text('Ver recurrente'), findsNothing);
  });
}
