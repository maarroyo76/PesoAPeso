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
  required String message,
  required UndoAction onUndo,
}) {
  final colors = messenger.context.colors;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 4),
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
