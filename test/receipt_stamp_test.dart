// RF26: lectura del timbre electrónico (TED) del PDF417 de una boleta.
// Estructura según el instructivo técnico del SII.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:peso_a_peso/features/escaner/prueba_boletas_screen.dart';
import 'package:peso_a_peso/features/escaner/receipt_stamp.dart';

String ted({
  String re = '76354771-K',
  String td = '39',
  String folio = '1523',
  String fe = '2026-10-21',
  String mnt = '12990',
  String it1 = 'Café &amp; medialuna',
  String rs = 'PANADERÍA LA ÑUSTA SPA',
  String caftd = '39',
}) =>
    '<TED version="1.0"><DD><RE>$re</RE><TD>$td</TD><F>$folio</F>'
    '<FE>$fe</FE><RR>66666666-6</RR><RSR>CONSUMIDOR FINAL</RSR>'
    '<MNT>$mnt</MNT><IT1>$it1</IT1>'
    '<CAF version="1.0"><DA><RE>$re</RE><RS>$rs</RS><TD>$caftd</TD>'
    '<RNG><D>1</D><H>5000</H></RNG><FA>2026-01-05</FA>'
    '<RSAPK><M>abc</M><E>Aw==</E></RSAPK><IDK>100</IDK></DA>'
    '<FRMA algoritmo="SHA1withRSA">xyz</FRMA></CAF>'
    '<TSTED>2026-10-21T13:47:05</TSTED></DD>'
    '<FRMT algoritmo="SHA1withRSA">firma</FRMT></TED>';

void main() {
  test('lee monto, fecha, hora, RUT, folio, comercio y primer ítem', () {
    final s = ReceiptStamp.tryParse(ted())!;
    expect(s.issuerRut, '76354771-K');
    expect(s.documentType, 39);
    expect(s.isReceipt, isTrue);
    expect(s.folio, 1523);
    expect(s.issueDate, DateTime(2026, 10, 21));
    expect(s.amount, 12990);
    expect(s.issuerName, 'PANADERÍA LA ÑUSTA SPA');
    expect(s.firstItem, 'Café & medialuna');
    expect(s.stampedAt, DateTime(2026, 10, 21, 13, 47, 5));
  });

  test('los bytes del PDF417 se decodifican como Latin-1', () {
    final bytes = Uint8List.fromList(latin1.encode(ted()));
    final s = ReceiptStamp.fromBytes(bytes)!;
    expect(s.issuerName, 'PANADERÍA LA ÑUSTA SPA');
    expect(s.firstItem, 'Café & medialuna');
  });

  test('decodifica entidades XML sin decodificar dos veces', () {
    final s = ReceiptStamp.tryParse(
        ted(it1: '&lt;Promo&gt; &quot;2x1&quot; d&apos;Or &amp;lt;'))!;
    expect(s.firstItem, '<Promo> "2x1" d\'Or &lt;');
  });

  test('toma TD del documento y no el del CAF', () {
    final s = ReceiptStamp.tryParse(ted(td: '33', caftd: '39'))!;
    expect(s.documentType, 33);
    expect(s.isReceipt, isFalse);
  });

  test('rechaza un timbre sin datos obligatorios o con datos corruptos', () {
    expect(ReceiptStamp.tryParse('hola'), isNull);
    expect(ReceiptStamp.tryParse(ted(mnt: '')), isNull);
    expect(ReceiptStamp.tryParse(ted(mnt: '12a90')), isNull);
    expect(ReceiptStamp.tryParse(ted(fe: '2026-02-30')), isNull);
    expect(ReceiptStamp.tryParse(ted(re: '76354771-1')), isNull,
        reason: 'dígito verificador incorrecto: lectura corrupta');
  });

  test('sin CAF no hay nombre de comercio, pero el resto se lee', () {
    final text = ted()
        .replaceAll(RegExp(r'<CAF version="1.0">.*</CAF>', dotAll: true), '');
    final s = ReceiptStamp.tryParse(text)!;
    expect(s.issuerName, isNull);
    expect(s.amount, 12990);
  });

  test('normalizeRut valida el dígito verificador y normaliza el formato', () {
    expect(normalizeRut('76.354.771-k'), '76354771-K');
    expect(normalizeRut('11111111-1'), '11111111-1');
    expect(normalizeRut('111111111'), '11111111-1');
    expect(normalizeRut('12.345.678-5'), '12345678-5');
    expect(normalizeRut('12345678-0'), isNull);
    expect(normalizeRut('abc'), isNull);
    expect(normalizeRut(null), isNull);
  });

  test('desde la cámara usa los bytes crudos, no el texto UTF-8 de Android',
      () {
    final bytes = Uint8List.fromList(latin1.encode(ted()));
    final barcode = Barcode(
      format: BarcodeFormat.pdf417,
      rawDecodedBytes: DecodedBarcodeBytes(bytes: bytes),
      // Así llega en Android: los bytes Latin-1 leídos como UTF-8.
      rawValue: utf8.decode(bytes, allowMalformed: true),
    );
    expect(stampFromBarcode(barcode)!.issuerName, 'PANADERÍA LA ÑUSTA SPA');
  });

  test('desde la cámara, un código que no es timbre da null', () {
    const barcode =
        Barcode(format: BarcodeFormat.pdf417, rawValue: 'NO ES UN TIMBRE');
    expect(stampFromBarcode(barcode), isNull);
  });
}
