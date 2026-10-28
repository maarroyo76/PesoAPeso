import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Explicación flotante para una métrica. En escritorio/web aparece al pasar
/// el mouse; en el teléfono, al tocar (y se cierra sola o al tocar de nuevo).
/// Envuelve a [child] completo, así toda la tarjeta es "interactiva", no solo
/// el ícono de info.
class InfoTooltip extends StatelessWidget {
  const InfoTooltip({super.key, required this.message, required this.child});

  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      enableTapToDismiss: true,
      waitDuration: const Duration(milliseconds: 250),
      showDuration: const Duration(seconds: 6),
      preferBelow: true,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        color: context.colors.ink,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle:
          TextStyle(color: context.colors.paper, fontSize: 12, height: 1.35),
      child: child,
    );
  }
}

/// Ícono "i" que indica que la métrica tiene una explicación disponible.
class InfoIcon extends StatelessWidget {
  const InfoIcon({super.key, this.size = 14});
  final double size;

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.info_outline, size: size, color: context.colors.inkSoft);
}
