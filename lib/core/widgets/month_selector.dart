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
      required this.onNext,
      this.onToday});
  final String label;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  /// Atajo "volver al mes actual"; null cuando ya se está en él. Su espacio
  /// se reserva siempre para que el selector no cambie de alto al aparecer.
  final VoidCallback? onToday;

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
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink),
            ),
            SizedBox(
              height: 18,
              child: AnimatedOpacity(
                opacity: onToday != null ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: IgnorePointer(
                  ignoring: onToday == null,
                  child: InkWell(
                    onTap: onToday,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('Volver al mes actual',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.green,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
