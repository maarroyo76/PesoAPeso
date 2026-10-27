// UX07/UX08: guías de accesibilidad de Flutter sobre las pantallas
// principales: todo lo tocable tiene nombre para el lector de pantalla, mide
// al menos 48x48 y el texto cumple contraste AA.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/main_screens.dart';

void main() {
  setUpAll(setUpMainScreens);

  for (final (name, screen) in mainScreens) {
    for (final brightness in Brightness.values) {
      final mode = brightness == Brightness.dark ? 'oscuro' : 'claro';
      testWidgets('$name ($mode): elementos tocables con nombre',
          (tester) async {
        final handle = tester.ensureSemantics();
        final dispose =
            await pumpMainScreen(tester, screen, brightness: brightness);
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await dispose();
        handle.dispose();
      });

      testWidgets('$name ($mode): áreas táctiles de al menos 48x48',
          (tester) async {
        final handle = tester.ensureSemantics();
        final dispose =
            await pumpMainScreen(tester, screen, brightness: brightness);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await dispose();
        handle.dispose();
      });

      testWidgets('$name ($mode): contraste de texto AA', (tester) async {
        final handle = tester.ensureSemantics();
        final dispose =
            await pumpMainScreen(tester, screen, brightness: brightness);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await dispose();
        handle.dispose();
      });
    }
  }
}
