import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatting.dart';
import 'receipt_stamp.dart';

/// Herramienta del equipo para la prueba con boletas reales (pendientes
/// técnicos del escáner): mide cuántas boletas traen timbre y si se lee bien.
/// No es parte de la app para usuarios: solo aparece fuera de release.
///
/// Por cada boleta: se apunta al timbre y se cronometra hasta la primera
/// lectura válida. Exitosa = monto, fecha y RUT en 3 s o menos (el RUT se
/// valida con su dígito verificador). Los resultados se copian como CSV para
/// la tabla del documento.
class PruebaBoletasScreen extends StatefulWidget {
  const PruebaBoletasScreen({super.key});

  @override
  State<PruebaBoletasScreen> createState() => _PruebaBoletasScreenState();
}

/// Lectura exitosa según el protocolo de la prueba.
const kMaxSuccessfulReadTime = Duration(seconds: 3);

const _conditions = ['normal', 'arrugada', 'desteñida', 'enrollada'];

class _Trial {
  _Trial({
    required this.hasStamp,
    required this.condition,
    this.stamp,
    this.elapsed,
  });
  final bool hasStamp;
  final String condition;
  final ReceiptStamp? stamp;
  final Duration? elapsed;

  bool get successful =>
      stamp != null && elapsed != null && elapsed! <= kMaxSuccessfulReadTime;
}

class _PruebaBoletasScreenState extends State<PruebaBoletasScreen> {
  // PDF417 es denso: ML Kit pide unos 1.156 px de ancho como mínimo y, sin
  // indicar resolución, Android usa 640x480.
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.pdf417],
    cameraResolution: const Size(1920, 1080),
  );
  final _stopwatch = Stopwatch();
  final _trials = <_Trial>[];

  ReceiptStamp? _stamp;
  Duration? _elapsed;

  /// Último código leído que no resultó ser un timbre válido.
  String? _unreadable;
  String _condition = _conditions.first;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_stamp != null) return;
    for (final barcode in capture.barcodes) {
      final stamp = stampFromBarcode(barcode);
      if (stamp != null) {
        _stopwatch.stop();
        HapticFeedback.mediumImpact();
        setState(() {
          _stamp = stamp;
          _elapsed = _stopwatch.elapsed;
          _unreadable = null;
        });
        return;
      }
      final text = barcode.rawValue ?? '';
      setState(() =>
          _unreadable = text.length > 80 ? '${text.substring(0, 80)}…' : text);
    }
  }

  void _save({required bool hasStamp}) {
    setState(() {
      _trials.add(_Trial(
        hasStamp: hasStamp,
        condition: _condition,
        stamp: hasStamp ? _stamp : null,
        elapsed: hasStamp ? _elapsed ?? _stopwatch.elapsed : null,
      ));
      _stamp = null;
      _elapsed = null;
      _unreadable = null;
      _condition = _conditions.first;
    });
    _stopwatch
      ..reset()
      ..start();
  }

  String _csv() {
    final rows = [
      '#,Comercio,Tipo,¿Trae timbre?,¿Lectura exitosa?,Segundos,Estado,'
          'RUT,Folio,Fecha,Monto',
      for (final (i, t) in _trials.indexed)
        [
          i + 1,
          '"${(t.stamp?.issuerName ?? '').replaceAll('"', '""')}"',
          t.stamp?.documentType ?? '',
          t.hasStamp ? 'Sí' : 'No',
          t.hasStamp ? (t.successful ? 'Sí' : 'No') : '',
          t.elapsed == null
              ? ''
              : (t.elapsed!.inMilliseconds / 1000).toStringAsFixed(1),
          t.condition,
          t.stamp?.issuerRut ?? '',
          t.stamp?.folio ?? '',
          t.stamp == null
              ? ''
              : DateFormat('yyyy-MM-dd').format(t.stamp!.issueDate),
          t.stamp?.amount ?? '',
        ].join(','),
    ];
    return rows.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final withStamp = _trials.where((t) => t.hasStamp).length;
    final ok = _trials.where((t) => t.successful).length;

    return Scaffold(
      backgroundColor: context.colors.paper,
      appBar: AppBar(
        title: const Text('Prueba de boletas'),
        actions: [
          IconButton(
            tooltip: 'Copiar resultados (CSV)',
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: _trials.isEmpty
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: _csv()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Resultados copiados')),
                    );
                  },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Boletas: ${_trials.length} · con timbre: $withStamp · '
            'lecturas exitosas: $ok de $withStamp',
            style: TextStyle(color: context.colors.inkSoft),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 260,
              child: MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_stamp != null)
            _StampCard(stamp: _stamp!, elapsed: _elapsed!)
          else ...[
            Text(
              'Apunta al código del timbre. Tiempo: el cronómetro corre '
              'desde la boleta anterior.',
              style: TextStyle(color: context.colors.inkSoft),
            ),
            if (_unreadable != null) ...[
              const SizedBox(height: 8),
              Text(
                  'Se leyó un código que no es un timbre válido: '
                  '$_unreadable',
                  style: TextStyle(color: context.colors.rust)),
            ],
          ],
          const SizedBox(height: 12),
          Text('Estado de la boleta',
              style: TextStyle(color: context.colors.inkSoft)),
          Wrap(
            spacing: 8,
            children: [
              for (final c in _conditions)
                ChoiceChip(
                  label: Text(c),
                  selected: _condition == c,
                  onSelected: (_) => setState(() => _condition = c),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: () => _save(hasStamp: true),
                child: Text(_stamp != null
                    ? 'Guardar y siguiente'
                    : 'Trae timbre, no se pudo leer'),
              ),
              OutlinedButton(
                onPressed: _stamp != null ? null : () => _save(hasStamp: false),
                child: const Text('No trae timbre'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StampCard extends StatelessWidget {
  const _StampCard({required this.stamp, required this.elapsed});
  final ReceiptStamp stamp;
  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    final fast = elapsed <= kMaxSuccessfulReadTime;
    final time = stamp.stampedAt == null
        ? ''
        : ' ${DateFormat('HH:mm').format(stamp.stampedAt!)}';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
            color: fast ? context.colors.green : context.colors.rust),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${fast ? 'Lectura exitosa' : 'Leída, pero tardó más de 3 s'} '
            '(${(elapsed.inMilliseconds / 1000).toStringAsFixed(1)} s)',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: fast ? context.colors.green : context.colors.rust),
          ),
          const SizedBox(height: 6),
          Text('${currencyFmt.format(stamp.amount)} · '
              '${DateFormat('d MMM yyyy', 'es_CL').format(stamp.issueDate)}'
              '$time'),
          Text('${stamp.issuerName ?? 'Comercio sin nombre'} · '
              'RUT ${stamp.issuerRut}'),
          Text('Documento tipo ${stamp.documentType} · folio ${stamp.folio}'),
          if (stamp.firstItem != null) Text('Primer ítem: ${stamp.firstItem}'),
        ],
      ),
    );
  }
}

/// Timbre a partir de un código leído por la cámara. Se prefieren los bytes
/// crudos (el timbre va en Latin-1; en Android `rawValue` viene decodificado
/// como UTF-8). En iOS `rawValue` ya viene en Latin-1 y sirve de respaldo.
ReceiptStamp? stampFromBarcode(Barcode barcode) {
  final bytes = switch (barcode.rawDecodedBytes) {
    DecodedBarcodeBytes(:final bytes) => bytes,
    DecodedVisionBarcodeBytes(:final bytes) => bytes,
    null => null,
  };
  if (bytes != null) {
    final stamp = ReceiptStamp.fromBytes(bytes);
    if (stamp != null) return stamp;
  }
  final text = barcode.rawValue;
  return text == null ? null : ReceiptStamp.tryParse(text);
}
