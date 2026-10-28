// Plan B del escáner: leer RUT, folio, fecha y total del texto impreso de
// boletas sin timbre. Filas tomadas de las boletas reales de la prueba.

import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:peso_a_peso/features/escaner/receipt_text.dart';

void main() {
  test('boleta de Cencosud pagada con crédito (sin timbre)', () {
    final r = parseReceiptRows([
      'RUT 81201000-K',
      'BOLETA ELECTRONICA N 3509694607',
      'SII LAS CONDES',
      'CENCOSUD RETAIL S.A.',
      '7801610223727 BEBIDA SPRITE Z 1. 2.250',
      'SUB TOTAL \$ 4.240',
      'NETO \$ 3.563',
      'TOTAL IVA 19,00% \$ 677',
      'TOTAL \$ 4.240',
      'T. CREDITO \$ 4.240',
      'FECHA HORA LOCAL CA TRX ID',
      '28/10/26 19:41 2871 02 3675 2',
      'VENTA CREDITO',
      '28/10/26 19:41:41 C-AX',
      'TOTAL \$ 4.240',
    ]);
    expect(r.rut, '81201000-K');
    expect(r.folio, 3509694607);
    expect(r.date, DateTime(2026, 10, 28, 19, 41));
    expect(r.total, 4240);
  });

  test('toma el total de la boleta, no el subtotal ni el del comprobante', () {
    final r = parseReceiptRows([
      'SUB TOTAL \$ 18 269',
      'TOTAL IVA 19,00% \$ 2 145',
      'DESCUENTOS \$ 4.840',
      'TOTAL \$ 13.429',
      'TOTAL \$ 99.999',
    ]);
    expect(r.total, 13429);
  });

  test('prefiere la fecha con hora a la de vencimiento de puntos', () {
    final r = parseReceiptRows([
      'SALDO DE PUNTOS al 26-10-2026: 1962',
      'PUNTOS POR VENCER AL 01-11-2026: 0',
      '28/10/26 18:44 0991 01 9240 16',
    ]);
    expect(r.date, DateTime(2026, 10, 28, 18, 44));
  });

  test('RUT con puntos y K minúscula; descarta RUT con dígito inválido', () {
    expect(parseReceiptRows(['R.U.T.: 77.049.760-4']).rut, '77049760-4');
    expect(parseReceiptRows(['RUT 81.201.000-k']).rut, '81201000-K');
    expect(parseReceiptRows(['RUT 81201000-5']).rut, isNull);
  });

  test('folio con N°, Nº o FOLIO', () {
    expect(parseReceiptRows(['BOLETA ELECTRÓNICA N° 852944']).folio, 852944);
    expect(parseReceiptRows(['BOLETA ELECTRONICA Nº: 123467588']).folio,
        123467588);
    expect(parseReceiptRows(['FOLIO: 4521']).folio, 4521);
    // El número de boleta del comprobante de la tarjeta no es el folio.
    expect(parseReceiptRows(['BOLETA:  178 EMPLEADO:']).folio, isNull);
  });

  test('arma filas con la etiqueta y el monto en líneas separadas', () {
    final r = parseReceiptText(const [
      OcrLine('TOTAL \$', Rect.fromLTWH(300, 700, 120, 30)),
      OcrLine('13.429', Rect.fromLTWH(600, 704, 120, 30)),
      OcrLine('SUB TOTAL \$', Rect.fromLTWH(300, 600, 160, 30)),
      OcrLine('18 269', Rect.fromLTWH(600, 602, 120, 30)),
    ]);
    expect(r.total, 13429);
  });

  test('sin datos reconocibles', () {
    expect(parseReceiptRows(['GRACIAS POR SU COMPRA']).isEmpty, isTrue);
  });
}
