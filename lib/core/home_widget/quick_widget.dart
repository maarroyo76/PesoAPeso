/// RF39: widget de Android con accesos rápidos. Lo que se le pasa al widget y
/// cómo se leen los toques. Puro: sin plugins, para poder probarlo.
library;

import '../../data/local/app_database.dart';
import '../utils/formatting.dart';

/// Accesos rápidos que caben en el widget (dos filas de dos).
const kWidgetMaxSlots = 4;

/// Esquema de los enlaces con que el widget abre la app.
const kWidgetUriScheme = 'pesoapeso';

/// Nombre de la clase del widget en Android.
const kQuickWidgetAndroidClass = 'cl.pesoapeso.app.QuickAccessWidgetProvider';

/// Lo que se guarda para el widget: cuántos accesos y, de cada uno, su id,
/// etiqueta y monto ya formateado. Solo eso: ningún gasto ni saldo sale de la
/// base cifrada. Los espacios sobrantes se vacían (null los borra).
Map<String, Object?> quickWidgetData(List<QuickExpenseTemplate> templates) {
  final shown = templates.take(kWidgetMaxSlots).toList();
  return {
    'quick_count': shown.length,
    for (var i = 0; i < kWidgetMaxSlots; i++) ...{
      'quick_${i}_id': i < shown.length ? '${shown[i].id}' : null,
      'quick_${i}_label': i < shown.length ? shown[i].label : null,
      'quick_${i}_amount':
          i < shown.length ? currencyFmt.format(shown[i].amount) : null,
    },
  };
}

/// Enlace de un acceso rápido del widget: pesoapeso://quick?id=3.
Uri quickWidgetUri(int templateId) => Uri(
    scheme: kWidgetUriScheme,
    host: 'quick',
    queryParameters: {'id': '$templateId'});

/// Enlace del botón "+": abre la hoja de registro.
final registerWidgetUri = Uri(scheme: kWidgetUriScheme, host: 'registrar');

/// Qué pidió el usuario al tocar el widget.
sealed class WidgetAction {
  const WidgetAction();
}

/// Registrar el acceso rápido [templateId].
class QuickAddAction extends WidgetAction {
  const QuickAddAction(this.templateId);
  final int templateId;

  @override
  bool operator ==(Object other) =>
      other is QuickAddAction && other.templateId == templateId;

  @override
  int get hashCode => templateId.hashCode;
}

/// Abrir la hoja de registro.
class OpenRegisterAction extends WidgetAction {
  const OpenRegisterAction();

  @override
  bool operator ==(Object other) => other is OpenRegisterAction;

  @override
  int get hashCode => 0;
}

/// La acción de un enlace del widget; null si no es uno de los nuestros.
WidgetAction? parseWidgetUri(Uri? uri) {
  if (uri == null || uri.scheme != kWidgetUriScheme) return null;
  switch (uri.host) {
    case 'quick':
      final id = int.tryParse(uri.queryParameters['id'] ?? '');
      return id == null ? null : QuickAddAction(id);
    case 'registrar':
      return const OpenRegisterAction();
  }
  return null;
}
