import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Deshace una acción ya guardada (p. ej. borra el gasto recién registrado).
typedef UndoAction = Future<void> Function();

/// UX01: la acción ya se guardó; este aviso solo ofrece revertirla durante
/// unos segundos, en lugar de pedir confirmación antes.
///
/// Recibe el messenger y no un context: dentro de una hoja modal hay que usar
/// el messenger propio de la hoja, porque el de la app queda detrás de ella.
void showUndoSnackBar(
  ScaffoldMessengerState messenger, {
  String? message,
  required UndoAction onUndo,

  /// Reemplaza a [message] cuando el aviso necesita más que un texto (p. ej.
  /// el selector de cantidad de RF46, que se actualiza sin cerrar el aviso).
  Widget? content,
  Duration duration = const Duration(seconds: 4),
}) {
  assert(message != null || content != null);
  final colors = messenger.context.colors;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: content ?? Text(message!),
      duration: duration,
      // Con acción, el SnackBar queda fijo por defecto; este debe irse solo.
      persist: false,
      backgroundColor: colors.ink,
      action: SnackBarAction(
        label: 'Deshacer',
        textColor: colors.paper,
        onPressed: () async {
          await onUndo();
          // El aviso de presupuesto (RF18) lo pudo disparar este mismo gasto.
          messenger.hideCurrentMaterialBanner();
        },
      ),
    ),
  );
}
