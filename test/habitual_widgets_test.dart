// RF47/RF49: la tarjeta de gastos habituales pendientes en Resumen y las dos
// secciones de la pantalla de Recurrentes.

import 'dart:ffi';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:peso_a_peso/core/providers/app_providers.dart';
import 'package:peso_a_peso/core/utils/formatting.dart';
import 'package:peso_a_peso/core/utils/habitual.dart';
import 'package:peso_a_peso/data/local/app_database.dart';
import 'package:peso_a_peso/features/recurrentes/recurrentes_screen.dart';
import 'package:peso_a_peso/features/resumen/habitual_pending_card.dart';
import 'package:sqlite3/open.dart';

const _category = Category(
    id: 'transporte',
    name: 'Transporte',
    colorValue: 0xFF3B6B78,
    iconKey: 'directions_car',
    archived: false);

RecurringTemplate _habitual(
        {required int weekdays, String note = 'Metro', DateTime? startDate}) =>
    RecurringTemplate(
      id: 1,
      categoryId: 'transporte',
      amount: 1640,
      note: note,
      dayOfMonth: 0,
      active: true,
      lastGeneratedYearMonth: 0,
      mode: kRecurringModeConfirm,
      weekdays: weekdays,
      // Medianoche: el día de hoy ya cuenta como pendiente.
      reminderTime: '00:00',
      startDate: startDate ?? DateTime(2020),
    );

const _fixed = RecurringTemplate(
  id: 2,
  categoryId: 'transporte',
  amount: 30000,
  note: 'TAG',
  dayOfMonth: 5,
  active: true,
  lastGeneratedYearMonth: 202601,
  mode: kRecurringModeAuto,
);

void main() {
  setUpAll(() async {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    await initializeDateFormatting('es_CL', null);
  });

  Future<void> pump(WidgetTester tester, Widget child,
      {required List<RecurringTemplate> templates,
      List<HabitualOccurrence> occurrences = const []}) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        categoriesProvider.overrideWith((ref) => Stream.value([_category])),
        recurringTemplatesProvider
            .overrideWith((ref) => Stream.value(templates)),
        habitualOccurrencesProvider
            .overrideWith((ref) => Stream.value(occurrences)),
        paymentMethodsProvider
            .overrideWith((ref) => Stream.value(<PaymentMethod>[])),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('un solo pendiente pregunta por él, con "Hoy no"',
      (tester) async {
    final today = DateTime.now().weekday;
    await pump(tester, const HabitualPendingCard(), templates: [
      // Creado hoy: el mismo día de la semana pasada no cuenta.
      _habitual(
          weekdays: weekdayBit(today), startDate: dateOnly(DateTime.now()))
    ]);
    expect(find.text('¿Registras "Metro"?'), findsOneWidget);
    expect(find.text('Hoy · ${currencyFmt.format(1640)}'), findsOneWidget);
    expect(find.text('Registrar'), findsOneWidget);
    expect(find.text('Hoy no'), findsOneWidget);
  });

  testWidgets('varios pendientes ofrecen registrar todos o revisar',
      (tester) async {
    await pump(tester, const HabitualPendingCard(),
        templates: [_habitual(weekdays: 0x7F)]);
    // Todos los días de la última semana, incluido hoy.
    expect(find.text('Gastos habituales sin confirmar'), findsOneWidget);
    expect(
        find.text(
            '8 días pendientes · ${currencyFmt.format(8 * 1640)} en total'),
        findsOneWidget);
    expect(find.text('Registrar todos'), findsOneWidget);

    await tester.tap(find.text('Revisar uno por uno'));
    await tester.pumpAndSettle();
    expect(find.text('Registrar'), findsNWidgets(8));
  });

  testWidgets('sin pendientes no se muestra', (tester) async {
    final today = dateOnly(DateTime.now());
    await pump(tester, const HabitualPendingCard(), templates: [
      _habitual(weekdays: weekdayBit(today.weekday), startDate: today)
    ], occurrences: [
      HabitualOccurrence(templateId: 1, date: today, status: kHabitualSkipped),
    ]);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('Recurrentes separa gastos habituales y pagos fijos',
      (tester) async {
    await pump(tester, const RecurrentesScreen(),
        templates: [_habitual(weekdays: 0x1F), _fixed]);
    expect(find.text('GASTOS HABITUALES'), findsOneWidget);
    expect(find.text('PAGOS FIJOS MENSUALES'), findsOneWidget);
    expect(find.text('lun a vie, 00:00 · Transporte'), findsOneWidget);
    expect(find.text('Día 5 de cada mes · Transporte'), findsOneWidget);

    await tester.tap(find.text('Metro'));
    await tester.pumpAndSettle();
    expect(find.text('Editar gasto habitual'), findsOneWidget);
  });
}
