import 'package:flutter_test/flutter_test.dart';
import 'package:peso_a_peso/core/startup/remainder_prompt.dart';

void main() {
  test(
      'evalúa el último mes en que se abrió la app, no el mes calendario previo',
      () {
    // Abrió por última vez en agosto y ahora es octubre: evalúa agosto.
    expect(remainderMonthFor(202608, 202610), DateTime(2026, 8));
    // Cambio de año.
    expect(remainderMonthFor(202512, 202601), DateTime(2025, 12));
  });

  test('sin aviso si es el mismo mes, es la primera vez o el dato es inválido',
      () {
    expect(remainderMonthFor(202610, 202610), isNull);
    expect(remainderMonthFor(null, 202610), isNull);
    expect(remainderMonthFor(202699, 202710), isNull);
    expect(remainderMonthFor(202611, 202610), isNull);
  });
}
