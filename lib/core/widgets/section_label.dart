import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'info_hint.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.info});
  final String text;

  /// Si se entrega, muestra un ícono "i" y la explicación al pasar el mouse
  /// o tocar el título.
  final String? info;

  @override
  Widget build(BuildContext context) {
    // La rayita corta bajo el texto imita la pestaña de una sección en un
    // libro contable físico (folio/rubro), no un subrayado decorativo.
    final label = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.1,
            color: AppColors.inkSoft,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 22,
          height: 2,
          decoration: BoxDecoration(
            color: AppColors.rust,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
    if (info == null) return label;
    return InfoTooltip(
      message: info!,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          label,
          const SizedBox(width: 6),
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: InfoIcon(),
          ),
        ],
      ),
    );
  }
}
