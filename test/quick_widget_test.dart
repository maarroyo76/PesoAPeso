// RF39: datos del widget de inicio y enlaces con que abre la app.

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:peso_a_peso/core/home_widget/quick_widget.dart';
import 'package:peso_a_peso/data/local/app_database.dart';

QuickExpenseTemplate _qa(int id, String label, int amount) =>
    QuickExpenseTemplate(
        id: id, label: label, amount: amount, categoryId: 'transporte');

void main() {
  setUpAll(() => initializeDateFormatting('es_CL', null));

  test('los primeros 4 accesos, con el monto ya formateado', () {
    final data = quickWidgetData([
      _qa(3, 'Carga bip!', 5000),
      _qa(7, 'Café', 2500),
      _qa(8, 'Almuerzo', 6990),
      _qa(9, 'Pan', 1800),
      _qa(10, 'Uber', 4500),
    ]);
    expect(data['quick_count'], 4);
    expect(data['quick_0_id'], '3');
    expect(data['quick_0_label'], 'Carga bip!');
    expect(data['quick_0_amount'], r'$5.000');
    expect(data['quick_3_label'], 'Pan');
    expect(data.values.contains('Uber'), isFalse);
  });

  test('los espacios sobrantes se vacían', () {
    final data = quickWidgetData([_qa(1, 'Café', 2500)]);
    expect(data['quick_count'], 1);
    for (var i = 1; i < kWidgetMaxSlots; i++) {
      expect(data.containsKey('quick_${i}_id'), isTrue);
      expect(data['quick_${i}_id'], isNull);
      expect(data['quick_${i}_label'], isNull);
      expect(data['quick_${i}_amount'], isNull);
    }
  });

  test('solo guarda etiqueta y monto de los accesos, nada más', () {
    final keys = quickWidgetData([_qa(1, 'Café', 2500)]).keys.toSet();
    expect(keys, {
      'quick_count',
      for (var i = 0; i < kWidgetMaxSlots; i++) ...[
        'quick_${i}_id',
        'quick_${i}_label',
        'quick_${i}_amount',
      ],
    });
  });

  test('enlaces del widget, ida y vuelta', () {
    expect(quickWidgetUri(12).toString(), 'pesoapeso://quick?id=12');
    expect(parseWidgetUri(quickWidgetUri(12)), const QuickAddAction(12));
    expect(registerWidgetUri.toString(), 'pesoapeso://registrar');
    expect(parseWidgetUri(registerWidgetUri), const OpenRegisterAction());
  });

  test('enlaces ajenos o incompletos no hacen nada', () {
    expect(parseWidgetUri(null), isNull);
    expect(parseWidgetUri(Uri.parse('https://quick?id=1')), isNull);
    expect(parseWidgetUri(Uri.parse('pesoapeso://quick')), isNull);
    expect(parseWidgetUri(Uri.parse('pesoapeso://quick?id=abc')), isNull);
    expect(parseWidgetUri(Uri.parse('pesoapeso://borrar')), isNull);
  });
}
