import 'package:flutter/services.dart';

/// Límites de entrada de toda la app. Sin tope, un texto o monto enorme
/// desborda filas y gráficos (o supera lo que `int`/`NumberFormat` muestran
/// bien); con topes muy chicos se sentiría restrictivo. Centralizados acá
/// para que cualquier campo nuevo use los mismos valores.
const kMaxAmountDigits = 9; // hasta $999.999.999
const kMaxNameLength = 30; // categoría, etiqueta de acceso rápido
const kMaxGoalNameLength = 40; // meta de ahorro
const kMaxNoteLength = 120; // nota de un gasto / recurrente

/// Agrupa de a tres con punto (1500 → 1.500, como el resto de la app en
/// es_CL). Descarta todo lo que no sea dígito, los ceros a la izquierda y lo
/// que pase de [maxDigits], y mantiene el cursor junto al mismo dígito aunque
/// se inserten o quiten puntos.
class ThousandsSeparatorFormatter extends TextInputFormatter {
  const ThousandsSeparatorFormatter({this.maxDigits = kMaxAmountDigits});
  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text;
    final sel = newValue.selection;
    final cursor =
        sel.isValid ? sel.extentOffset.clamp(0, raw.length) : raw.length;

    final digits = StringBuffer();
    var digitsBeforeCursor = 0;
    for (var i = 0; i < raw.length; i++) {
      final c = raw.codeUnitAt(i);
      if (c < 0x30 || c > 0x39) continue;
      if (digits.length >= maxDigits) continue;
      digits.write(raw[i]);
      if (i < cursor) digitsBeforeCursor++;
    }

    var d = digits.toString();
    final stripped = d.length - d.replaceFirst(RegExp(r'^0+'), '').length;
    d = d.substring(stripped);
    digitsBeforeCursor =
        (digitsBeforeCursor - stripped).clamp(0, d.length).toInt();

    final out = StringBuffer();
    var newCursor = 0;
    var seen = 0;
    if (digitsBeforeCursor == 0) newCursor = 0;
    for (var i = 0; i < d.length; i++) {
      if (i > 0 && (d.length - i) % 3 == 0) out.write('.');
      out.write(d[i]);
      seen++;
      if (seen == digitsBeforeCursor) newCursor = out.length;
    }
    return TextEditingValue(
      text: out.toString(),
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }
}

/// Campos de monto: miles con punto mientras se escribe, tope de largo, solo
/// dígitos. Leer el valor con [parseAmountText] / [parsePositiveAmount].
final amountInputFormatters = <TextInputFormatter>[
  const ThousandsSeparatorFormatter(),
];

/// Texto inicial de un campo de monto (1500 → "1.500").
String formatAmountInput(int value) {
  final out = StringBuffer();
  final d = value.abs().toString();
  for (var i = 0; i < d.length; i++) {
    if (i > 0 && (d.length - i) % 3 == 0) out.write('.');
    out.write(d[i]);
  }
  return value < 0 ? '-$out' : out.toString();
}

/// Valor entero de un campo de monto (ignora los puntos de miles), o null si
/// está vacío.
int? parseAmountText(String text) =>
    int.tryParse(text.replaceAll('.', '').trim());

/// Día del mes (1-31): a lo más 2 dígitos.
final dayInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(2),
];

/// Porcentaje (1-100): a lo más 3 dígitos.
final percentInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(3),
];

/// Monto estrictamente positivo, o null si el texto está vacío / es 0.
int? parsePositiveAmount(String text) {
  final v = parseAmountText(text);
  return (v != null && v > 0) ? v : null;
}

const kInvalidAmountMessage = 'Ingresa un monto mayor a 0';
