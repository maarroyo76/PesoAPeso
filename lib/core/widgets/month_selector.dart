import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Navegación de mes (←/→) compartida por las pantallas que muestran datos
/// de un mes a la vez (Resumen, Estadísticas). `onNext` null deshabilita la
/// flecha derecha — se usa para bloquear el avance más allá del mes actual.
class MonthSelector extends StatelessWidget {
  const MonthSelector(
      {super.key,
      required this.label,
      required this.onPrev,
      required this.onNext});
  final String label;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          color: AppColors.ink,
          onPressed: onPrev,
        ),
        Text(
          label,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          color: onNext != null ? AppColors.ink : AppColors.rule,
          onPressed: onNext,
        ),
      ],
    );
  }
}
