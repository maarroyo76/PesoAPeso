import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';

/// RF16/RF17/RNF09: exportar/restaurar un respaldo local en JSON.
class RespaldoScreen extends ConsumerStatefulWidget {
  const RespaldoScreen({super.key});

  @override
  ConsumerState<RespaldoScreen> createState() => _RespaldoScreenState();
}

class _RespaldoScreenState extends ConsumerState<RespaldoScreen> {
  bool _busy = false;

  void _showMessage(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? AppColors.rust : AppColors.ink,
      ),
    );
  }

  /// Errores de respaldo en un diálogo (un SnackBar se pierde y no deja
  /// espacio para explicar qué hacer). Los [FormatException] ya traen un
  /// mensaje pensado para el usuario; cualquier otra cosa se resume sin
  /// mostrar el texto técnico de la excepción.
  Future<void> _showFriendlyError({
    required String title,
    required Object error,
    required String fallback,
    String? reassurance,
  }) async {
    final message = error is FormatException ? error.message : fallback;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        icon: const Icon(Icons.error_outline, color: AppColors.rust),
        title: Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: AppColors.ink)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message,
                style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
            if (reassurance != null) ...[
              const SizedBox(height: 12),
              Text(reassurance,
                  style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final saved = await ref.read(backupRepositoryProvider).exportBackup();
      if (!mounted) return;
      if (saved) _showMessage('Respaldo guardado.');
    } catch (e) {
      await _showFriendlyError(
        title: 'No se pudo guardar el respaldo',
        error: e,
        fallback: 'Ocurrió un problema al guardar el archivo. Revisa que '
            'haya espacio disponible e inténtalo de nuevo.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: const Text('Restaurar respaldo',
            style: TextStyle(fontSize: 16, color: AppColors.ink)),
        content: const Text(
          'Esto reemplazará TODOS tus datos actuales (gastos, categorías, presupuestos, metas) por los del archivo elegido. Esta acción no se puede deshacer.',
          style: TextStyle(color: AppColors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.inkSoft)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.rust),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reemplazar datos'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final restored = await ref.read(backupRepositoryProvider).importBackup();
      if (!mounted) return;
      if (restored) _showMessage('Datos restaurados.');
    } catch (e) {
      await _showFriendlyError(
        title: 'No pudimos restaurar tu respaldo',
        error: e,
        fallback: 'Ocurrió un problema inesperado al leer el archivo. '
            'Inténtalo de nuevo con otro archivo.',
        reassurance: 'Tus datos actuales no se modificaron.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Respaldo')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Todos tus datos viven solo en este dispositivo. Exporta un '
              'archivo de respaldo periódicamente por si cambias de equipo o '
              'lo necesitas recuperar — funciona completamente sin conexión.',
              style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ojo: la base de datos del teléfono está cifrada, pero el '
              'archivo de respaldo NO. Guárdalo en un lugar de confianza.',
              style: TextStyle(color: AppColors.rust, fontSize: 12),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _busy ? null : _export,
                icon: const Icon(Icons.file_download_outlined),
                label: const Text('Exportar respaldo'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: const BorderSide(color: AppColors.rule),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _busy ? null : _import,
                icon: const Icon(Icons.file_upload_outlined),
                label: const Text('Restaurar desde archivo'),
              ),
            ),
            if (_busy) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
