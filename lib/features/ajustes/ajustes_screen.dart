import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../categorias/categorias_screen.dart';
import '../escaner/prueba_boletas_screen.dart';
import '../recurrentes/recurrentes_screen.dart';
import '../respaldo/respaldo_screen.dart';

/// UX05: Categorías, Recurrentes y Respaldo con nombre visible. Antes eran
/// tres íconos sin texto en la barra superior, reconocibles solo con
/// pulsación larga.
class AjustesScreen extends StatelessWidget {
  const AjustesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.paper,
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: const [
          _SettingsTile(
            icon: Icons.sell_outlined,
            title: 'Categorías',
            subtitle: 'Crear, editar y elegir ícono y color',
            screen: CategoriasScreen(),
          ),
          Divider(height: 1, indent: 72),
          _SettingsTile(
            icon: Icons.event_repeat_outlined,
            title: 'Gastos recurrentes',
            subtitle: 'Arriendo, suscripciones y otros pagos mensuales',
            screen: RecurrentesScreen(),
          ),
          Divider(height: 1, indent: 72),
          _SettingsTile(
            icon: Icons.backup_outlined,
            title: 'Respaldo',
            subtitle: 'Guardar o restaurar tus datos en un archivo',
            screen: RespaldoScreen(),
          ),
          // Herramienta del equipo para la prueba con boletas reales; no se
          // incluye en builds de release.
          if (!kReleaseMode) ...[
            Divider(height: 1, indent: 72),
            _SettingsTile(
              icon: Icons.qr_code_scanner,
              title: 'Prueba de boletas (equipo)',
              subtitle: 'Mide si el timbre de las boletas se puede leer',
              screen: PruebaBoletasScreen(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.screen,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget screen;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: context.colors.ink),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: 12, color: context.colors.inkSoft)),
      trailing: Icon(Icons.chevron_right, color: context.colors.inkSoft),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen),
      ),
    );
  }
}
