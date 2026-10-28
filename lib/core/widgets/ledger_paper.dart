import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Textura de papel rayado (líneas horizontales finas) para el fondo de las
/// tarjetas de cifras — referencia directa al cuaderno de cuentas real, no
/// un efecto decorativo genérico. Dibuja las líneas y el padding del
/// contenido en un solo Stack para que queden detrás del texto pero encima
/// del color base de la tarjeta.
class RuledPaperBackground extends StatelessWidget {
  const RuledPaperBackground({
    required this.child,
    this.spacing = 22,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 12,
    super.key,
  });

  final Widget child;
  final double spacing;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
                painter: _RuledLinesPainter(
                    spacing: spacing, color: context.colors.rule)),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class _RuledLinesPainter extends CustomPainter {
  _RuledLinesPainter({required this.spacing, required this.color});
  final double spacing;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RuledLinesPainter oldDelegate) =>
      oldDelegate.spacing != spacing || oldDelegate.color != color;
}

/// El "cuadre": cuando un libro contable cierra una suma, se traza una
/// doble línea bajo el total. Esta barra reemplaza el LinearProgressIndicator
/// genérico por esa misma convención — la línea gruesa marca cuánto se
/// gastó, la línea fina debajo la "cierra", y las marcas al 25/50/75/100%
/// imitan las columnas de una hoja de cuentas rayada.
class LedgerCuadreBar extends StatelessWidget {
  const LedgerCuadreBar({
    required this.ratio,
    required this.color,
    this.height = 18,
    this.semanticsLabel,
    this.semanticsValue,
    super.key,
  });

  final double ratio;
  final Color color;
  final double height;

  /// UX08: qué mide la barra y su valor, para el lector de pantalla (un
  /// CustomPaint no expone nada por sí solo). Sin valor, se lee el
  /// porcentaje de [ratio].
  final String? semanticsLabel;
  final String? semanticsValue;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      value: semanticsValue ?? '${(ratio.clamp(0.0, 1.0) * 100).round()}%',
      child: _bar(),
    );
  }

  Widget _bar() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: ratio.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => SizedBox(
        width: double.infinity,
        height: height,
        child: CustomPaint(
            painter: _CuadrePainter(
                ratio: value, color: color, ruleColor: context.colors.rule)),
      ),
    );
  }
}

class _CuadrePainter extends CustomPainter {
  _CuadrePainter(
      {required this.ratio, required this.color, required this.ruleColor});
  final double ratio;
  final Color color;
  final Color ruleColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final baseY = size.height - 4;

    final basePaint = Paint()
      ..color = ruleColor
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, baseY), Offset(w, baseY), basePaint);

    for (final f in [0.25, 0.5, 0.75, 1.0]) {
      final x = w * f;
      canvas.drawLine(Offset(x, baseY - 3), Offset(x, baseY + 3), basePaint);
    }

    final filledW = (w * ratio).clamp(0.0, w);
    if (filledW <= 3) return;

    final thickPaint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(3, baseY - 7), Offset(filledW, baseY - 7), thickPaint);

    final underlinePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(3, baseY - 2), Offset(filledW, baseY - 2), underlinePaint);
  }

  @override
  bool shouldRepaint(covariant _CuadrePainter oldDelegate) =>
      oldDelegate.ratio != ratio ||
      oldDelegate.color != color ||
      oldDelegate.ruleColor != ruleColor;
}
