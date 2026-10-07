import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Envuelve un bloque que depende del mes para poder cambiarlo deslizando:
/// hacia la derecha va al mes anterior ([onPrev]) y hacia la izquierda al
/// siguiente ([onNext], null en el mes actual: no se avanza más). El bloque se
/// desliza hacia el lado de la navegación al cambiar [month]; el sentido se
/// deduce solo de si el mes nuevo es posterior o anterior al previo, así que
/// también anima los cambios hechos con las flechas o "volver al mes actual".
class MonthSwipe extends StatefulWidget {
  const MonthSwipe({
    super.key,
    required this.month,
    required this.onPrev,
    required this.onNext,
    required this.child,
    this.onSwiped,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final Widget child;

  /// Se llama tras un swipe efectivo (p. ej. para marcar la pista como vista).
  final VoidCallback? onSwiped;

  @override
  State<MonthSwipe> createState() => _MonthSwipeState();
}

class _MonthSwipeState extends State<MonthSwipe> {
  int _dir = 1;

  @override
  void didUpdateWidget(MonthSwipe old) {
    super.didUpdateWidget(old);
    if (widget.month != old.month) {
      _dir = widget.month.isAfter(old.month) ? 1 : -1;
    }
  }

  void _onSwipe(DragEndDetails details) {
    final v = details.primaryVelocity ?? 0;
    if (v > 250) {
      HapticFeedback.selectionClick();
      widget.onSwiped?.call();
      widget.onPrev();
    } else if (v < -250 && widget.onNext != null) {
      HapticFeedback.selectionClick();
      widget.onSwiped?.call();
      widget.onNext!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = ValueKey(widget.month);
    return Semantics(
      hint: 'Desliza hacia los lados para cambiar de mes',
      customSemanticsActions: {
        const CustomSemanticsAction(label: 'Mes anterior'): widget.onPrev,
        if (widget.onNext != null)
          const CustomSemanticsAction(label: 'Mes siguiente'): widget.onNext!,
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: _onSwipe,
        child: ClipRect(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              // El hijo nuevo entra desde el lado hacia el que se navega y
              // el viejo sale por el opuesto.
              final incoming = child.key == key;
              final dx = incoming ? _dir : -_dir;
              return SlideTransition(
                position: Tween<Offset>(
                        begin: Offset(dx.toDouble(), 0), end: Offset.zero)
                    .animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: KeyedSubtree(key: key, child: widget.child),
          ),
        ),
      ),
    );
  }
}

/// Pista de un renglón ("‹ Desliza para cambiar de mes ›") que se muestra bajo
/// el bloque deslizable hasta que el usuario la descarta navegando.
class SwipeHint extends StatelessWidget {
  const SwipeHint({super.key, required this.visible});
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: visible
          ? const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chevron_left, size: 14, color: AppColors.inkSoft),
                  SizedBox(width: 4),
                  Text('Desliza para cambiar de mes',
                      style: TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 14, color: AppColors.inkSoft),
                ],
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
