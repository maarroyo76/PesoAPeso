import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// UX09: mensaje para el usuario cuando un dato no se pudo cargar, en lugar
/// del error técnico tal cual (`Error: $e`). El error real queda en el log.
class LoadError extends StatelessWidget {
  LoadError(Object error, {super.key, this.compact = false}) {
    debugPrint('LoadError: $error');
  }

  /// true dentro de una sección pequeña (una línea, sin centrar ni ícono).
  final bool compact;

  static const _message = 'No se pudieron cargar estos datos.';
  static const _hint = 'Cierra y vuelve a abrir la app. Si sigue pasando, '
      'restaura tu último respaldo desde Respaldo.';

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Text(_message,
          style: TextStyle(fontSize: 12, color: context.colors.rust));
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 32, color: context.colors.rust),
            const SizedBox(height: 12),
            Text(_message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: context.colors.ink)),
            const SizedBox(height: 6),
            Text(_hint,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: context.colors.inkSoft)),
          ],
        ),
      ),
    );
  }
}
