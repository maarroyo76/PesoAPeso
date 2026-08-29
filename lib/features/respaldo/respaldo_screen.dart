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

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final saved = await ref.read(backupRepositoryProvider).exportBackup();
      if (!mounted) return;
      if (saved) _showMessage('Respaldo guardado.');
    } catch (e) {
      if (mounted) _showMessage('No se pudo exportar: $e', isError: true);
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
      if (mounted) _showMessage('No se pudo restaurar: $e', isError: true);
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
