import 'dart:convert';
import 'dart:typed_data';

/// Datos del timbre electrónico (TED) de una boleta o factura electrónica
/// chilena, leídos del código PDF417 impreso (RF26).
///
/// El TED es un bloque XML: `<TED><DD>…datos…<CAF>…</CAF><TSTED>…</TSTED>
/// </DD><FRMT>…</FRMT></TED>`, según el instructivo técnico del SII.
class ReceiptStamp {
  const ReceiptStamp({
    required this.issuerRut,
    required this.documentType,
    required this.folio,
    required this.issueDate,
    required this.amount,
    this.issuerName,
    this.firstItem,
    this.stampedAt,
  });

  /// RUT del emisor (`DD/RE`), normalizado como `12345678-K`.
  final String issuerRut;

  /// Tipo de documento (`DD/TD`): 39 boleta, 41 boleta exenta, 33 factura…
  final int documentType;

  /// Folio (`DD/F`). Junto con [issuerRut] identifica la boleta (RF29).
  final int folio;

  /// Fecha de emisión (`DD/FE`), sin hora.
  final DateTime issueDate;

  /// Monto total en pesos (`DD/MNT`).
  final int amount;

  /// Razón social del emisor (`CAF/DA/RS`): el nombre del comercio.
  final String? issuerName;

  /// Descripción del primer ítem (`DD/IT1`), útil como nota del gasto.
  final String? firstItem;

  /// Fecha y hora en que se generó el timbre (`DD/TSTED`): la hora de la
  /// compra, o muy cercana.
  final DateTime? stampedAt;

  bool get isReceipt => documentType == 39 || documentType == 41;

  /// Interpreta los bytes crudos del PDF417. El código usa compactación
  /// binaria en ISO-8859-1: decodificarlo como UTF-8 rompe tildes y eñes.
  /// Devuelve null si no es un timbre válido.
  static ReceiptStamp? fromBytes(Uint8List bytes) =>
      tryParse(latin1.decode(bytes, allowInvalid: true));

  /// Interpreta el texto del timbre. Devuelve null si falta algún dato
  /// obligatorio (RUT, tipo, folio, fecha o monto) o si el RUT del emisor
  /// no pasa el dígito verificador (señal de una lectura corrupta).
  static ReceiptStamp? tryParse(String text) {
    final dd = _element(text, 'DD');
    if (dd == null) return null;
    // El CAF también trae RE y TD; se separa para no confundirlos con los
    // del documento.
    final caf = _element(dd, 'CAF');
    final data = caf == null ? dd : dd.replaceFirst(caf, '');

    final rut = normalizeRut(_value(data, 'RE'));
    final type = int.tryParse(_value(data, 'TD') ?? '');
    final folio = int.tryParse(_value(data, 'F') ?? '');
    final date = _parseDate(_value(data, 'FE'));
    final amount = int.tryParse(_value(data, 'MNT') ?? '');
    if (rut == null ||
        type == null ||
        folio == null ||
        date == null ||
        amount == null ||
        amount < 0) {
      return null;
    }

    return ReceiptStamp(
      issuerRut: rut,
      documentType: type,
      folio: folio,
      issueDate: date,
      amount: amount,
      issuerName: caf == null ? null : _value(caf, 'RS'),
      firstItem: _value(data, 'IT1'),
      stampedAt: DateTime.tryParse(_value(data, 'TSTED') ?? ''),
    );
  }

  static String? _element(String xml, String tag) =>
      RegExp('<$tag(?:\\s[^>]*)?>.*?</$tag>', dotAll: true)
          .firstMatch(xml)
          ?.group(0);

  static String? _value(String xml, String tag) {
    final raw = RegExp('<$tag(?:\\s[^>]*)?>(.*?)</$tag>', dotAll: true)
        .firstMatch(xml)
        ?.group(1)
        ?.trim();
    if (raw == null || raw.isEmpty) return null;
    return _decodeEntities(raw);
  }

  static String _decodeEntities(String s) => s
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      // Al final: si no, "&amp;lt;" terminaría como "<".
      .replaceAll('&amp;', '&');

  static DateTime? _parseDate(String? s) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s ?? '');
    if (m == null) return null;
    final y = int.parse(m.group(1)!);
    final mo = int.parse(m.group(2)!);
    final d = int.parse(m.group(3)!);
    final date = DateTime(y, mo, d);
    // Rechaza fechas imposibles (DateTime(2026, 2, 30) pasa a marzo).
    if (date.month != mo || date.day != d) return null;
    return date;
  }
}

/// Normaliza un RUT (`12.345.678-k` → `12345678-K`) y valida su dígito
/// verificador (módulo 11). Devuelve null si no es un RUT válido.
String? normalizeRut(String? input) {
  if (input == null) return null;
  final clean = input.replaceAll(RegExp(r'[.\s]'), '').toUpperCase();
  final m = RegExp(r'^(\d{1,9})-?([\dK])$').firstMatch(clean);
  if (m == null) return null;
  final body = m.group(1)!;
  final dv = m.group(2)!;

  var sum = 0;
  var factor = 2;
  for (var i = body.length - 1; i >= 0; i--) {
    sum += int.parse(body[i]) * factor;
    factor = factor == 7 ? 2 : factor + 1;
  }
  final rest = 11 - sum % 11;
  final expected = rest == 11
      ? '0'
      : rest == 10
          ? 'K'
          : '$rest';
  if (dv != expected) return null;
  return '${int.parse(body)}-$dv';
}
