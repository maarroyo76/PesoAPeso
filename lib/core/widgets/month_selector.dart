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
          tooltip: 'Mes anterior',
          icon: const Icon(Icons.chevron_left),
          color: context.colors.ink,
          onPressed: onPrev,
        ),
        // Expanded + textos que envuelven: con letra grande del sistema el
        // mes y el atajo no caben en una línea junto a las flechas (UX07).
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.colors.ink),
              ),
              // Con opacidad 0 el atajo sigue ocupando su espacio, así que el
              // selector no cambia de alto (antes se fijaba con un SizedBox de
              // 18 px, que se rompía con letra grande).
              AnimatedOpacity(
                opacity: onToday != null ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: IgnorePointer(
                  ignoring: onToday == null,
                  child: InkWell(
                    onTap: onToday,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text('Volver al mes actual',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11,
                              color: context.colors.green,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Mes siguiente',
          icon: const Icon(Icons.chevron_right),
          color: onNext != null ? context.colors.ink : context.colors.rule,
          onPressed: onNext,
        ),
      ],
    );
  }
}
