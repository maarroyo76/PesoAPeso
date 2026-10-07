// UX: tooltips informativos, atajo "volver al mes actual" y swipe de meses
// en Resumen.

import 'dart:ffi';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqlite3/open.dart';
import 'package:peso_a_peso/core/providers/app_providers.dart';
import 'package:peso_a_peso/core/utils/formatting.dart';
import 'package:peso_a_peso/core/widgets/info_hint.dart';
import 'package:peso_a_peso/core/widgets/section_label.dart';
import 'package:peso_a_peso/data/local/app_database.dart';
import 'package:peso_a_peso/features/estadisticas/estadisticas_screen.dart';
import 'package:peso_a_peso/features/resumen/resumen_screen.dart';

void main() {
  setUpAll(() async {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    await initializeDateFormatting('es_CL', null);
  });

  Widget app(Widget screen, AppDatabase db) {
    const category = Category(
        id: 'ocio', name: 'Ocio', colorValue: 0xFF6B3F5C, iconKey: 'theaters');
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        categoriesProvider.overrideWith((ref) => Stream.value([category])),
        monthTransactionsProvider
            .overrideWith((ref, month) => Stream.value(<Transaction>[])),
        categoryBudgetsProvider
            .overrideWith((ref) => Stream.value(<CategoryBudget>[])),
        monthlyBudgetsProvider
            .overrideWith((ref) => Stream.value(<MonthlyBudget>[])),
      ],
      child: MaterialApp(home: Scaffold(body: screen)),
    );
  }

  testWidgets('InfoTooltip muestra la explicación al tocar', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: InfoTooltip(message: 'Explicación de prueba', child: Text('X')),
        ),
      ),
    ));
    expect(find.text('Explicación de prueba'), findsNothing);
    await tester.tap(find.text('X'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Explicación de prueba'), findsOneWidget);
  });

  testWidgets('SectionLabel con info muestra el ícono; sin info no',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(children: [
          SectionLabel('Con info', info: 'Algo'),
          SectionLabel('Sin info'),
        ]),
      ),
    ));
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });

  testWidgets('el swipe sobre el gasto del mes cambia de mes', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(app(const ResumenScreen(), db));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final current = capitalizeMonth(DateTime(now.year, now.month), monthFmt);
    final prev = capitalizeMonth(DateTime(now.year, now.month - 1), monthFmt);

    expect(find.text(current), findsOneWidget);
    expect(find.text('Volver al mes actual'), findsOneWidget);
    // El atajo existe pero está oculto (opacidad 0) en el mes actual.
    expect(
        tester
            .widget<AnimatedOpacity>(find.ancestor(
                of: find.text('Volver al mes actual'),
                matching: find.byType(AnimatedOpacity)))
            .opacity,
        0);

    // Swipe a la derecha: mes anterior.
    await tester.fling(find.text('GASTO DEL MES'), const Offset(300, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text(prev), findsOneWidget);
    expect(
        tester
            .widget<AnimatedOpacity>(find.ancestor(
                of: find.text('Volver al mes actual'),
                matching: find.byType(AnimatedOpacity)))
            .opacity,
        1);

    // Swipe a la izquierda: vuelve al mes actual.
    await tester.fling(find.text('GASTO DEL MES'), const Offset(-300, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text(current), findsOneWidget);

    // En el mes actual no se puede avanzar más.
    await tester.fling(find.text('GASTO DEL MES'), const Offset(-300, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text(current), findsOneWidget);

    // "Volver al mes actual" desde un mes pasado.
    await tester.fling(find.text('GASTO DEL MES'), const Offset(300, 0), 1500);
    await tester.pumpAndSettle();
    await tester.fling(find.text('GASTO DEL MES'), const Offset(300, 0), 1500);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volver al mes actual'));
    await tester.pumpAndSettle();
    expect(find.text(current), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('la pista de swipe sale una vez y no vuelve tras usarla',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(app(const ResumenScreen(), db));
    await tester.pumpAndSettle();
    expect(find.text('Desliza para cambiar de mes'), findsOneWidget);

    // Al primer swipe se oculta y queda registrada como vista.
    await tester.fling(find.text('GASTO DEL MES'), const Offset(300, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('Desliza para cambiar de mes'), findsNothing);
    expect(await db.getSetting('swipe_month_hint_seen'), 'true');

    // Una pantalla nueva (otra sesión) ya no la muestra.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(const ResumenScreen(), db));
    await tester.pumpAndSettle();
    expect(find.text('Desliza para cambiar de mes'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('la pista se oculta sola a los 8 segundos', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(app(const ResumenScreen(), db));
    await tester.pumpAndSettle();
    expect(find.text('Desliza para cambiar de mes'), findsOneWidget);

    await tester.pump(const Duration(seconds: 9));
    await tester.pumpAndSettle();
    expect(find.text('Desliza para cambiar de mes'), findsNothing);
    expect(await db.getSetting('swipe_month_hint_seen'), 'true');

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('Estadísticas: el swipe sobre los recuadros cambia de mes',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(app(const EstadisticasScreen(), db));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final current = capitalizeMonth(DateTime(now.year, now.month), monthFmt);
    final prev = capitalizeMonth(DateTime(now.year, now.month - 1), monthFmt);
    expect(find.text(current), findsOneWidget);

    await tester.fling(find.text('PROMEDIO DIARIO'), const Offset(300, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text(prev), findsOneWidget);

    await tester.fling(find.text('TOTAL DEL MES'), const Offset(-300, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text(current), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}
