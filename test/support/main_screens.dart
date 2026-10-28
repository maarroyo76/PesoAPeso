// Datos y armado comunes para probar las pantallas principales con datos
// realistas y sin streams de Drift (que no avanzan con el reloj falso).

import 'dart:ffi' show DynamicLibrary;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqlite3/open.dart';
import 'package:peso_a_peso/core/providers/app_providers.dart';
import 'package:peso_a_peso/core/theme/app_theme.dart';
import 'package:peso_a_peso/data/local/app_database.dart';
import 'package:peso_a_peso/features/agregar_gasto/agregar_screen.dart';
import 'package:peso_a_peso/features/ajustes/ajustes_screen.dart';
import 'package:peso_a_peso/features/categorias/categorias_screen.dart';
import 'package:peso_a_peso/features/cuotas/cuotas_screen.dart';
import 'package:peso_a_peso/features/estadisticas/estadisticas_screen.dart';
import 'package:peso_a_peso/features/metodos_pago/payment_methods_screen.dart';
import 'package:peso_a_peso/features/metas/metas_screen.dart';
import 'package:peso_a_peso/features/presupuestos/presupuestos_screen.dart';
import 'package:peso_a_peso/features/recurrentes/recurrentes_screen.dart';
import 'package:peso_a_peso/features/respaldo/respaldo_screen.dart';
import 'package:peso_a_peso/features/resumen/resumen_screen.dart';

Future<void> setUpMainScreens() async {
  open.overrideFor(
      OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
  await initializeDateFormatting('es_CL', null);
}

const mainScreens = [
  ('Resumen', ResumenScreen()),
  ('Agregar', AgregarScreen()),
  ('Presupuestos', PresupuestosScreen()),
  ('Metas', MetasScreen()),
  ('Estadísticas', EstadisticasScreen()),
  ('Ajustes', AjustesScreen()),
  ('Categorías', CategoriasScreen()),
  ('Recurrentes', RecurrentesScreen()),
  ('Respaldo', RespaldoScreen()),
  ('Métodos de pago', PaymentMethodsScreen()),
  ('Compras en cuotas', CuotasScreen()),
];

const categories = [
  Category(
      id: 'alimentacion',
      name: 'Alimentación',
      colorValue: 0xFF2F6F4E,
      iconKey: 'restaurant'),
  Category(
      id: 'transporte',
      name: 'Transporte',
      colorValue: 0xFFB8842E,
      iconKey: 'directions_car'),
  Category(
      id: 'vivienda',
      name: 'Vivienda',
      colorValue: 0xFF3B6B78,
      iconKey: 'home'),
];
final now = DateTime.now();
final month = DateTime(now.year, now.month);
List<Transaction> txsFor(DateTime m) => [
      for (var i = 0; i < 6; i++)
        Transaction(
          id: m.month * 100 + i,
          categoryId: categories[i % 3].id,
          amount: 12345 * (i + 1),
          date: DateTime(m.year, m.month, 1 + i, 13, 5),
          note: i.isEven ? 'Almuerzo con el equipo de trabajo' : '',
          isRecurring: i == 5,
          paymentMethodId: i == 4 ? 1 : null,
        ),
    ];
final budgets = [
  for (final c in categories)
    CategoryBudget(
        categoryId: c.id, year: month.year, month: month.month, amount: 50000),
];
const goals = [
  SavingsGoal(id: 1, name: 'Vacaciones en el sur', targetAmount: 1200000),
];
const quick = [
  QuickExpenseTemplate(
      id: 1, label: 'Café', amount: 2500, categoryId: 'alimentacion'),
  QuickExpenseTemplate(
      id: 2, label: 'Micro/Metro', amount: 790, categoryId: 'transporte'),
];

const paymentMethods = [
  PaymentMethod(
      id: 1,
      alias: 'CMR',
      kind: 'credit',
      colorValue: 0xFF3B6B78,
      last4: '1234',
      billingDay: 20,
      dueDay: 5),
  PaymentMethod(id: 2, alias: 'Efectivo', kind: 'cash', colorValue: 0xFF2F6F4E),
];

/// Compra de 6 cuotas que empezó el mes pasado: 2 pagadas y 4 pendientes.
final installmentPlans = [
  InstallmentPlan(
    id: 1,
    paymentMethodId: 1,
    categoryId: 'transporte',
    note: 'Neumáticos',
    totalAmount: 360000,
    installmentCount: 6,
    purchaseDate: DateTime(month.year, month.month - 1, 1),
    prepaid: false,
  ),
];
final installmentTxs = [
  for (var k = 1; k <= 6; k++)
    Transaction(
      id: 900 + k,
      categoryId: 'transporte',
      amount: 60000,
      date: DateTime(month.year, month.month - 2 + k, 1),
      note: 'Neumáticos · Cuota $k de 6',
      isRecurring: false,
      paymentMethodId: 1,
      installmentPlanId: 1,
      installmentNumber: k,
    ),
];

const recurring = [
  RecurringTemplate(
    id: 1,
    categoryId: 'vivienda',
    amount: 350000,
    note: 'Arriendo departamento',
    dayOfMonth: 5,
    active: true,
    lastGeneratedYearMonth: 202610,
  ),
  RecurringTemplate(
    id: 2,
    categoryId: 'alimentacion',
    amount: 8990,
    note: '',
    dayOfMonth: 28,
    active: false,
    lastGeneratedYearMonth: 202609,
  ),
];

/// Monta [screen] en un teléfono de 390x844 con [textScale]. Devuelve una
/// función que desmonta la pantalla y cierra la base.
Future<Future<void> Function()> pumpMainScreen(
    WidgetTester tester, Widget screen,
    {double textScale = 1.0, Brightness brightness = Brightness.light}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await tester.pumpWidget(ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      categoriesProvider.overrideWith((ref) => Stream.value(categories)),
      monthTransactionsProvider
          .overrideWith((ref, m) => Stream.value(txsFor(m))),
      categoryBudgetsProvider.overrideWith((ref) => Stream.value(budgets)),
      monthlyBudgetsProvider.overrideWith((ref) => Stream.value([
            MonthlyBudget(year: month.year, month: month.month, amount: 150000)
          ])),
      monthlyAdjustmentsProvider
          .overrideWith((ref) => Stream.value(<MonthlyAdjustment>[])),
      savingsGoalsProvider.overrideWith((ref) => Stream.value(goals)),
      savingsTotalsProvider.overrideWith((ref) => Stream.value({1: 450000})),
      monthContributedProvider.overrideWith((ref, m) => Stream.value(30000)),
      paymentMethodsProvider
          .overrideWith((ref) => Stream.value(paymentMethods)),
      installmentPlansProvider
          .overrideWith((ref) => Stream.value(installmentPlans)),
      installmentTransactionsProvider
          .overrideWith((ref) => Stream.value(installmentTxs)),
      quickExpenseTemplatesProvider.overrideWith((ref) => Stream.value(quick)),
      recurringTemplatesProvider.overrideWith((ref) => Stream.value(recurring)),
    ],
    child: MaterialApp(
      theme: buildAppTheme(brightness: brightness),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(body: screen),
    ),
  ));
  await tester.pumpAndSettle();
  return () async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
    await db.close();
  };
}
