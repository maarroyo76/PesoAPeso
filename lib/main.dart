import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/notifications/notification_service.dart';
import 'core/providers/app_providers.dart';
import 'core/startup/remainder_prompt.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/budget_alert.dart';
import 'core/utils/formatting.dart';
import 'data/local/connection.dart';
import 'data/repositories/backup_repository.dart';
import 'features/agregar_gasto/agregar_screen.dart';
import 'features/ajustes/ajustes_screen.dart';
import 'features/estadisticas/estadisticas_screen.dart';
import 'features/metas/metas_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/presupuestos/presupuestos_screen.dart';
import 'features/resumen/resumen_screen.dart';

void main() async {
  await initializeDateFormatting('es_CL', null);
  runApp(const ProviderScope(child: GastoAManoApp()));
}

/// Habilita arrastre con mouse en listas horizontales (ej. los sliders de
/// color/ícono de categoría) — por defecto Flutter solo scrollea con mouse
/// vía la rueda, no con drag; en touch (Android/iOS) no hace falta.
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        ...super.dragDevices,
        PointerDeviceKind.mouse,
      };
}

class GastoAManoApp extends StatelessWidget {
  const GastoAManoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peso a Peso',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // UX11: sigue el modo claro/oscuro del sistema.
      darkTheme: buildAppTheme(brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      scrollBehavior: _AppScrollBehavior(),
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
  Object? _startupError;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final done = await ref
          .read(settingsRepositoryProvider)
          .get(kOnboardingCompletedKey);
      if (mounted) setState(() => _needsOnboarding = done != 'true');
    } catch (e) {
      // Si la base no abre (p. ej. la clave de cifrado ya no coincide con el
      // archivo), mostramos el error en vez de dejar el spinner para siempre.
      if (mounted) setState(() => _startupError = e);
    }
  }

  void _retry() {
    setState(() => _startupError = null);
    ref.invalidate(appDatabaseProvider);
    _check();
  }

  bool _busy = false;

  /// Cierra la base que no abre, la borra junto con su clave y deja que el
  /// provider cree una nueva y vacía en la próxima lectura.
  Future<void> _resetDatabase() async {
    try {
      await ref.read(appDatabaseProvider).close();
    } catch (_) {
      // Nunca llegó a abrirse: no hay nada que cerrar.
    }
    await deleteDatabaseStorage();
    ref.invalidate(appDatabaseProvider);
  }

  Future<bool> _confirmWipe({required String action}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.paper,
        title: Text(action,
            style: TextStyle(fontSize: 16, color: context.colors.ink)),
        content: Text(
          'La base de datos actual de este dispositivo se borrará para '
          'siempre. Hazlo solo si ya no se puede abrir.',
          style: TextStyle(color: context.colors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TextStyle(color: context.colors.inkSoft)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.colors.rust),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar y continuar'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: context.colors.rust),
    );
  }

  /// El respaldo se elige y valida ANTES de borrar nada: si el archivo no
  /// sirve, la base actual queda como estaba.
  Future<void> _restoreFromBackup() async {
    setState(() => _busy = true);
    try {
      final Uint8List? bytes;
      try {
        bytes = await BackupRepository.pickBackupFile();
        if (bytes == null) return;
        BackupRepository.parseBackup(bytes);
      } on FormatException catch (e) {
        _showMessage(e.message);
        return;
      }
      if (!mounted || !await _confirmWipe(action: 'Restaurar respaldo')) {
        return;
      }

      await _resetDatabase();
      await ref.read(backupRepositoryProvider).restoreFromBytes(bytes);
      // Respaldos antiguos pueden no traer esta marca; quien restaura ya
      // configuró la app y no debe ver el recorrido inicial.
      await ref
          .read(settingsRepositoryProvider)
          .set(kOnboardingCompletedKey, 'true');
      _retry();
    } catch (_) {
      if (mounted) {
        _showMessage('No se pudo restaurar el respaldo. Inténtalo de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startFresh() async {
    if (!await _confirmWipe(action: 'Empezar de cero')) return;
    setState(() => _busy = true);
    try {
      await _resetDatabase();
      _retry();
    } catch (_) {
      if (mounted) _showMessage('No se pudo borrar la base de datos.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_startupError != null) {
      return Scaffold(
        backgroundColor: context.colors.paper,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 40, color: context.colors.rust),
                const SizedBox(height: 16),
                Text('No se pudo abrir tu base de datos',
                    style: TextStyle(fontSize: 18, color: context.colors.ink)),
                const SizedBox(height: 8),
                Text(
                  'Tus datos están cifrados con una clave que vive solo en '
                  'este dispositivo. Si reinstalaste la app o cambiaste de '
                  'equipo, restaura tu archivo de respaldo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.colors.inkSoft, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text('$_startupError',
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(color: context.colors.inkSoft, fontSize: 11)),
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: context.colors.ink),
                  onPressed: _busy ? null : _retry,
                  child: const Text('Reintentar'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colors.ink,
                    side: BorderSide(color: context.colors.rule),
                  ),
                  onPressed: _busy ? null : _restoreFromBackup,
                  icon: const Icon(Icons.file_upload_outlined),
                  label: const Text('Restaurar desde respaldo'),
                ),
                TextButton(
                  onPressed: _busy ? null : _startFresh,
                  child: Text('Empezar de cero',
                      style: TextStyle(color: context.colors.rust)),
                ),
                if (_busy) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
      );
    }
    if (_needsOnboarding == null) {
      return Scaffold(
        backgroundColor: context.colors.paper,
        body: const Center(child: CircularProgressIndicator()),
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int get _index => ref.watch(selectedTabProvider);
  late final _fadeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..value = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // RF12: al abrir la app, genera la ocurrencia del mes actual de
    // cualquier plantilla recurrente que todavía no la tenga.
    WidgetsBinding.instance.addPostFrameCallback((_) => _runStartupChecks());
  }

  bool _checking = false;

  /// La app puede quedar semanas en segundo plano: al volver, se repiten los
  /// chequeos de arranque (recurrentes del mes, remanente) y se refresca el
  /// mes en curso. Ambos son idempotentes.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final now = DateTime.now();
    ref.read(currentMonthProvider.notifier).state =
        DateTime(now.year, now.month);
    _runStartupChecks();
  }

  Future<void> _runStartupChecks() async {
    if (_checking) return;
    _checking = true;
    try {
      await _doStartupChecks();
    } finally {
      _checking = false;
    }
  }

  Future<void> _doStartupChecks() async {
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

  List<Widget> get _screens => [
        const ResumenScreen(),
        AgregarScreen(active: _index == kAgregarTabIndex),
        const PresupuestosScreen(),
        const MetasScreen(),
        const EstadisticasScreen(),
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
    if (i == ref.read(selectedTabProvider)) return;
    ref.read(selectedTabProvider.notifier).state = i;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(selectedTabProvider, (prev, next) {
      if (prev != next) _fadeController.forward(from: 0);
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peso a Peso'),
        actions: [
          // UX05: un solo acceso con nombre en lugar de tres íconos sin texto.
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: context.colors.ink),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AjustesScreen()),
            ),
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Ajustes'),
          ),
          const SizedBox(width: 4),
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
        backgroundColor: context.colors.paperDeep,
        indicatorColor: context.colors.green.withValues(alpha: 0.18),
        animationDuration: const Duration(milliseconds: 350),
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon, color: context.colors.inkSoft),
              selectedIcon: Icon(d.selectedIcon, color: context.colors.green),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
