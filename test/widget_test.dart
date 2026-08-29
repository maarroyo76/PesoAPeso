// Smoke test: la app arranca, muestra el onboarding (RF23) en una
// instalación nueva, y tras omitirlo se ve el shell principal.
//
// Usa una base en memoria (igual que los otros tests) en vez de la conexión
// real: AppDatabase() de producción abre un isolate de background + usa
// path_provider, que no tienen plugin real en flutter test y cuelgan
// `_StartupGate` para siempre — antes esto era invisible porque el test no
// esperaba ninguna resolución async.

import 'dart:ffi';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqlite3/open.dart';

import 'package:gasto_a_mano/core/providers/app_providers.dart';
import 'package:gasto_a_mano/data/local/app_database.dart';
import 'package:gasto_a_mano/main.dart';

void main() {
  setUpAll(() async {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    // main() normalmente inicializa esto antes de runApp(); el test se
    // salta main(), así que hay que hacerlo a mano o cualquier pantalla que
    // formatee fechas en es_CL (Resumen, Presupuestos, Estadísticas) explota.
    await initializeDateFormatting('es_CL', null);
  });

  testWidgets(
      'GastoAManoApp arranca, muestra el onboarding y tras omitirlo el shell principal',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(
            AppDatabase.forTesting(NativeDatabase.memory()),
          ),
        ],
        child: const GastoAManoApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Instalación nueva: primero se ve el onboarding, no el shell.
    expect(find.text('PASO 1 DE 4'), findsOneWidget);
    expect(find.text('Peso a Peso'), findsNothing);

    // Omitir los 4 pasos.
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Omitir'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Peso a Peso'), findsOneWidget);

    // Desmontar el árbol DENTRO del test (no dejárselo al teardown
    // automático): así los timers de limpieza de drift que dispara la
    // cancelación de las suscripciones de los StreamProvider (uno por tab
    // del IndexedStack) alcanzan a dispararse con el pump siguiente, en vez
    // de quedar pendientes cuando flutter_test verifica al final.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
