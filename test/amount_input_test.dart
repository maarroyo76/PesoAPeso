import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_a_peso/core/utils/amount_input.dart';

TextEditingValue _fmt(String text, [int? cursor, String old = '']) =>
    const ThousandsSeparatorFormatter().formatEditUpdate(
      TextEditingValue(text: old),
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: cursor ?? text.length),
      ),
    );

void main() {
  group('ThousandsSeparatorFormatter', () {
    test('agrupa de a tres con punto', () {
      expect(_fmt('1').text, '1');
      expect(_fmt('1500').text, '1.500');
      expect(_fmt('1234567').text, '1.234.567');
      expect(_fmt('999999999').text, '999.999.999');
    });

    test('descarta lo que no es dígito y respeta el tope de 9 dígitos', () {
      expect(_fmt('1.500-abc').text, '1.500');
      expect(_fmt('1234567890123').text, '123.456.789');
    });

    test('pegar un monto ya formateado no lo altera', () {
      expect(_fmt('1.500.000').text, '1.500.000');
    });

    test('quita ceros a la izquierda', () {
      expect(_fmt('0').text, '');
      expect(_fmt('007').text, '7');
      expect(_fmt('0500').text, '500');
    });

    test('el cursor queda junto al mismo dígito', () {
      // Escribir al final: el cursor sigue al final.
      expect(_fmt('1500').selection.baseOffset, 5);
      // Insertar un dígito en medio de "1.500" → "12.500"; cursor tras el 2.
      final mid = _fmt('12.500', 2);
      expect(mid.text, '12.500');
      expect(mid.selection.baseOffset, 2);
      // Cruza un separador: "999" + "9" al principio → "9.999", cursor tras 1er dígito.
      final start = _fmt('9999', 1);
      expect(start.text, '9.999');
      expect(start.selection.baseOffset, 1);
    });
  });

  group('parse / format', () {
    test('formatAmountInput', () {
      expect(formatAmountInput(0), '0');
      expect(formatAmountInput(999), '999');
      expect(formatAmountInput(1500), '1.500');
      expect(formatAmountInput(1234567), '1.234.567');
    });

    test('parseAmountText ignora los puntos de miles', () {
      expect(parseAmountText('1.500'), 1500);
      expect(parseAmountText('1.234.567'), 1234567);
      expect(parseAmountText(''), isNull);
      expect(parseAmountText('abc'), isNull);
    });

    test('ida y vuelta: parse(format(n)) == n', () {
      for (final n in [1, 10, 999, 1000, 12345, 999999999]) {
        expect(parseAmountText(formatAmountInput(n)), n);
      }
    });

    test('parsePositiveAmount rechaza vacío y 0', () {
      expect(parsePositiveAmount('1.500'), 1500);
      expect(parsePositiveAmount('0'), isNull);
      expect(parsePositiveAmount(''), isNull);
    });
  });
}
