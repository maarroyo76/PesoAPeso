// UX07: las pantallas principales no se desbordan con la letra del sistema
// al 200% en un teléfono típico (390x844).

import 'package:flutter_test/flutter_test.dart';

import 'support/main_screens.dart';

void main() {
  setUpAll(setUpMainScreens);

  for (final (name, screen) in mainScreens) {
    testWidgets('$name sin desbordes con letra al 200%', (tester) async {
      final dispose = await pumpMainScreen(tester, screen, textScale: 2.0);
      // Sin expect explícito: un desborde hace fallar el test por sí solo,
      // con el widget y la línea que lo causa en el reporte.
      await dispose();
    });
  }
}
