import 'dart:ui' show Rect;

import 'receipt_stamp.dart' show normalizeRut;

/// Línea de texto reconocida en la foto de una boleta, con su posición. Es
/// independiente de ML Kit para poder probar el parser sin el teléfono.
class OcrLine {
  const OcrLine(this.text, this.box);
  final String text;
  final Rect box;
}

/// Datos leídos del texto impreso de una boleta, para las que no traen
/// timbre (plan B del escáner). Cualquiera puede faltar: el reconocimiento
/// de texto se equivoca más que el timbre, y el usuario confirma igual.
class ReceiptText {
  const ReceiptText({this.rut, this.folio, this.date, this.total});

  /// RUT del emisor, normalizado y con dígito verificador válido.
  final String? rut;

  /// Número de la boleta ("BOLETA ELECTRONICA N 3509694607").
  final int? folio;

  /// Fecha de la compra; con hora si la boleta la imprime junto a la fecha.
  final DateTime? date;

  /// Línea "TOTAL $" de la boleta (no el subtotal ni el IVA).
  final int? total;

  bool get isEmpty =>
      rut == null && folio == null && date == null && total == null;
}

/// Agrupa las líneas en filas según su altura en la imagen. ML Kit suele
/// devolver "TOTAL $" y "13.429" como líneas separadas; juntas en una fila
/// se pueden leer como en el papel.
List<String> groupIntoRows(List<OcrLine> lines) {
  final sorted = [...lines]
    ..sort((a, b) => a.box.center.dy.compareTo(b.box.center.dy));
  final rows = <List<OcrLine>>[];
  for (final line in sorted) {
    final row = rows.isEmpty ? null : rows.last;
    if (row != null) {
      final ref = row.first.box;
      final tolerance =
          (ref.height < line.box.height ? ref.height : line.box.height) / 2;
      if ((line.box.center.dy - ref.center.dy).abs() <= tolerance) {
        row.add(line);
        continue;
      }
    }
    rows.add([line]);
  }
  return [
    for (final row in rows)
      (row..sort((a, b) => a.box.left.compareTo(b.box.left)))
          .map((l) => l.text.trim())
          .join(' '),
  ];
}

final _rutPattern =
    RegExp(r'(\d{1,2}[.\s]?\d{3}[.\s]?\d{3})\s*-\s*([\dkK])(?![\d])');
final _folioPatterns = [
  RegExp(r'BOLETA[^\d]*?\bN\s*[°º.O]?\s*:?\s*(\d{3,12})', caseSensitive: false),
  RegExp(r'\bFOLIO\s*[:N°º.]*\s*(\d{3,12})', caseSensitive: false),
];
final _datePattern = RegExp(
    r'(?<!\d)(\d{1,2})[/-](\d{1,2})[/-](\d{4}|\d{2})(?!\d)(?:\s+(\d{1,2}):(\d{2}))?');
final _totalLabel =
    RegExp(r'(?<!SUB\s?)\bTOTAL\b(?!\s*IVA)', caseSensitive: false);
final _amount = RegExp(r'\d{1,3}(?:[.,\s]\d{3})+(?!\d)|\d+');

/// Lee RUT, folio, fecha y total del texto de una boleta.
ReceiptText parseReceiptText(List<OcrLine> lines) =>
    parseReceiptRows(groupIntoRows(lines));

/// Igual que [parseReceiptText], a partir de las filas ya armadas.
ReceiptText parseReceiptRows(List<String> rows) {
  String? rut;
  for (final row in rows) {
    for (final m in _rutPattern.allMatches(row)) {
      rut = normalizeRut('${m.group(1)}-${m.group(2)}');
      if (rut != null) break;
    }
    if (rut != null) break;
  }

  int? folio;
  for (final pattern in _folioPatterns) {
    for (final row in rows) {
      final m = pattern.firstMatch(row);
      if (m != null) {
        folio = int.tryParse(m.group(1)!);
        break;
      }
    }
    if (folio != null) break;
  }

  // Se prefiere una fecha con hora: la de la compra. Otras fechas sin hora
  // (vencimiento de puntos, saldo) suelen aparecer antes en la boleta.
  DateTime? date;
  DateTime? dateWithoutTime;
  for (final row in rows) {
    for (final m in _datePattern.allMatches(row)) {
      final day = int.parse(m.group(1)!);
      final month = int.parse(m.group(2)!);
      var year = int.parse(m.group(3)!);
      if (year < 100) year += 2000;
      final candidate = DateTime(year, month, day);
      if (candidate.month != month || candidate.day != day) continue;
      if (m.group(4) != null) {
        final hour = int.parse(m.group(4)!);
        final minute = int.parse(m.group(5)!);
        if (hour < 24 && minute < 60) {
          date = DateTime(year, month, day, hour, minute);
          break;
        }
      }
      dateWithoutTime ??= candidate;
    }
    if (date != null) break;
  }

  // El primer "TOTAL" es el de la boleta; el comprobante de la tarjeta, más
  // abajo, repite otro.
  int? total;
  for (final row in rows) {
    final label = _totalLabel.firstMatch(row);
    if (label == null) continue;
    final amounts = _amount.allMatches(row.substring(label.end)).toList();
    if (amounts.isEmpty) continue;
    total =
        int.tryParse(amounts.last.group(0)!.replaceAll(RegExp(r'[.,\s]'), ''));
    if (total != null) break;
  }

  return ReceiptText(
      rut: rut, folio: folio, date: date ?? dateWithoutTime, total: total);
}
