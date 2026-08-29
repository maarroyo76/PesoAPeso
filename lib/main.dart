import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/notifications/notification_service.dart';
import 'core/providers/app_providers.dart';
import 'core/startup/remainder_prompt.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/budget_alert.dart';
import 'core/utils/formatting.dart';
import 'features/agregar_gasto/agregar_screen.dart';
import 'features/categorias/categorias_screen.dart';
import 'features/estadisticas/estadisticas_screen.dart';
import 'features/metas/metas_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/presupuestos/presupuestos_screen.dart';
import 'features/recurrentes/recurrentes_screen.dart';
import 'features/resumen/resumen_screen.dart';
import 'features/respaldo/respaldo_screen.dart';

void main() async {
  await initializeDateFormatting('es_CL', null);
  runApp(const ProviderScope(child: GastoAManoApp()));
}

class GastoAManoApp extends StatelessWidget {
  const GastoAManoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peso a Peso',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _StartupGate(),
    );
  }
}

/// RF23: antes de mostrar la app, revisa si esta instalación ya completó
/// (u omitió) el recorrido inicial. Instalaciones nuevas lo ven una vez;
/// instalaciones que ya existían quedan marcadas como completadas por la
/// migración de schemaVersion (ver app_database.dart) y no lo ven nunca.
class _StartupGate extends ConsumerStatefulWidget {
  const _StartupGate();

  @override
  ConsumerState<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends ConsumerState<_StartupGate> {
  bool? _needsOnboarding;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final done =
        await ref.read(settingsRepositoryProvider).get(kOnboardingCompletedKey);
    if (mounted) setState(() => _needsOnboarding = done != 'true');
  }

  @override
  Widget build(BuildContext context) {
    if (_needsOnboarding == null) {
      return const Scaffold(
        backgroundColor: AppColors.paper,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_needsOnboarding == true) {
      return OnboardingScreen(
          onDone: () => setState(() => _needsOnboarding = false));
    }
    return const RootShell();
  }
}

class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late final _fadeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..value = 1.0;

  @override
  void initState() {
    super.initState();
    // RF12: al abrir la app, genera la ocurrencia del mes actual de
    // cualquier plantilla recurrente que todavía no la tenga.
    WidgetsBinding.instance.addPostFrameCallback((_) => _runStartupChecks());
  }

  Future<void> _runStartupChecks() async {
    final generated =
        await ref.read(recurringTemplatesRepositoryProvider).runCatchUp();
    if (!mounted) return;

    // RF20: notificación local SOLO para transacciones generadas
    // automáticamente por el catch-up (no para gastos manuales — eso ya lo
    // cubre el banner en pantalla de RF18).
    for (final tx in generated) {
      final alert =
          await checkBudgetAlert(ref, categoryId: tx.categoryId, date: tx.date);
      if (alert == null) continue;
      await NotificationService.instance.init();
      final pct = (alert.ratio * 100).round();
      final noteText = tx.note.isNotEmpty ? tx.note : alert.categoryName;
      await NotificationService.instance.showBudgetAlert(
        id: tx.id,
        title: alert.isOverBudget
            ? 'Presupuesto superado'
            : 'Presupuesto casi lleno',
        body: '${alert.categoryName} llegó al $pct% — se registró '
            '"$noteText" (${currencyFmt.format(tx.amount)}) automáticamente.',
      );
    }

    // RF15: remanente del mes anterior, si corresponde.
    if (!mounted) return;
    await checkPreviousMonthRemainder(context, ref);
  }

  static const _screens = [
    ResumenScreen(),
    AgregarScreen(),
    PresupuestosScreen(),
    MetasScreen(),
    EstadisticasScreen(),
  ];

  static const _destinations = [
    (
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
      label: 'Resumen',
    ),
    (
      icon: Icons.add_circle_outline,
      selectedIcon: Icons.add_circle,
      label: 'Agregar',
    ),
    (
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
      label: 'Presupuestos',
    ),
    (
      icon: Icons.savings_outlined,
      selectedIcon: Icons.savings,
      label: 'Metas',
    ),
    (
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
      label: 'Estadísticas',
    ),
  ];

  void _selectTab(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    _fadeController.forward(from: 0);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peso a Peso'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sell_outlined),
            tooltip: 'Categorías',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoriasScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.event_repeat_outlined),
            tooltip: 'Gastos recurrentes',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RecurrentesScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.backup_outlined),
            tooltip: 'Respaldo',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RespaldoScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: _fadeController,
            curve: Curves.easeOut,
          ),
          child: IndexedStack(index: _index, children: _screens),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _selectTab,
        backgroundColor: AppColors.paperDeep,
        indicatorColor: AppColors.green.withValues(alpha: 0.18),
        animationDuration: const Duration(milliseconds: 350),
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon, color: AppColors.inkSoft),
              selectedIcon: Icon(d.selectedIcon, color: AppColors.green),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
