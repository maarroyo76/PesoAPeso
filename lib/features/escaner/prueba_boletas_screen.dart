import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatting.dart';
import 'delete_file.dart';
import 'receipt_stamp.dart';
import 'receipt_text.dart';

/// Herramienta del equipo para la prueba con boletas reales (pendientes
/// técnicos del escáner): mide cuántas boletas traen timbre y si se lee bien.
/// No es parte de la app para usuarios: se entra desde Ajustes mientras dure
/// la prueba (ver ajustes_screen.dart).
///
/// Por cada boleta, dos formas de leer:
/// - En vivo: se encuadra el timbre, se toca "Medir" y se cronometra hasta
///   la primera lectura válida. Exitosa = 3 s o menos.
/// - Foto: una foto a resolución completa, donde se busca el timbre y se lee
///   el texto impreso (plan B para boletas sin timbre). Si hay timbre, el
///   texto se compara solo contra él; si no, se marca a mano qué leyó bien.
///
/// Los resultados se copian como CSV para la tabla del documento.
class PruebaBoletasScreen extends StatefulWidget {
  const PruebaBoletasScreen({super.key});

  @override
  State<PruebaBoletasScreen> createState() => _PruebaBoletasScreenState();
}

/// Lectura en vivo exitosa según el protocolo de la prueba.
const kMaxSuccessfulReadTime = Duration(seconds: 3);

const _conditions = ['normal', 'arrugada', 'desteñida', 'enrollada'];
const _voucherTypes = [
  'boleta',
  'comprobante de tarjeta',
  'boleta con QR',
  'boleta manual',
  'otro',
];
const _payments = ['no sé', 'débito', 'crédito', 'efectivo', 'otro'];

/// Campos del texto que se evalúan (plan B).
const _textFields = ['RUT', 'folio', 'fecha', 'total'];

enum _Method { live, photo }

class _Trial {
  _Trial({
    required this.hasStamp,
    required this.condition,
    required this.voucher,
    required this.payment,
    required this.zoom,
    this.method,
    this.stamp,
    this.elapsed,
    this.text,
    this.textCorrect = const {},
    this.textCheckedByStamp = false,
  });
  final bool hasStamp;
  final String condition;
  final String voucher;
  final String payment;
  final double zoom;
  final _Method? method;
  final ReceiptStamp? stamp;
  final Duration? elapsed;
  final ReceiptText? text;
  final Set<String> textCorrect;
  final bool textCheckedByStamp;

  bool get successful => switch (method) {
        _Method.live => stamp != null &&
            elapsed != null &&
            elapsed! <= kMaxSuccessfulReadTime,
        _Method.photo => stamp != null,
        null => false,
      };
}

class _PruebaBoletasScreenState extends State<PruebaBoletasScreen> {
  // PDF417 es denso: ML Kit pide unos 1.156 px de ancho como mínimo y, sin
  // indicar resolución, Android usa 640x480.
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.pdf417],
    cameraResolution: const Size(1920, 1080),
  );
  final _textRecognizer = TextRecognizer();
  final _stopwatch = Stopwatch();
  final _trials = <_Trial>[];

  /// El cronómetro corre solo después de tocar "Medir", con la boleta ya
  /// encuadrada: antes incluía el tiempo de cambiar de boleta.
  bool _measuring = false;
  bool _busy = false;
  bool _torch = false;
  double _zoom = 0;

  _Method? _method;
  ReceiptStamp? _stamp;
  Duration? _elapsed;
  ReceiptText? _text;
  final _textCorrect = <String>{};

  /// Último código leído que no resultó ser un timbre válido.
  String? _unreadable;

  String _condition = _conditions.first;
  String _voucher = _voucherTypes.first;
  String _payment = _payments.first;

  @override
  void dispose() {
    _controller.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  void _startMeasuring() {
    setState(() {
      _measuring = true;
      _unreadable = null;
    });
    _stopwatch
      ..reset()
      ..start();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_measuring || _stamp != null) return;
    for (final barcode in capture.barcodes) {
      final stamp = stampFromBarcode(barcode);
      if (stamp != null) {
        _stopwatch.stop();
        HapticFeedback.mediumImpact();
        setState(() {
          _measuring = false;
          _method = _Method.live;
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

  /// Toma una foto a resolución completa y la analiza dos veces: busca el
  /// timbre y lee el texto impreso.
  Future<void> _takePhoto() async {
    setState(() => _busy = true);
    // La cámara de la foto no puede abrirse con la vista previa encendida.
    await _controller.stop();
    XFile? photo;
    try {
      photo = await ImagePicker()
          .pickImage(source: ImageSource.camera, requestFullMetadata: false);
    } finally {
      await _controller.start();
      await _controller.setZoomScale(_zoom);
      if (_torch) await _controller.toggleTorch();
    }
    if (photo == null) {
      if (mounted) setState(() => _busy = false);
      return;
    }

    try {
      final capture = await _controller
          .analyzeImage(photo.path, formats: const [BarcodeFormat.pdf417]);
      ReceiptStamp? stamp;
      for (final barcode in capture?.barcodes ?? const <Barcode>[]) {
        stamp = stampFromBarcode(barcode);
        if (stamp != null) break;
      }

      final recognized = await _textRecognizer
          .processImage(InputImage.fromFilePath(photo.path));
      final text = parseReceiptText([
        for (final block in recognized.blocks)
          for (final line in block.lines) OcrLine(line.text, line.boundingBox),
      ]);

      if (!mounted) return;
      setState(() {
        _stopwatch.stop();
        // Si ya se leyó en vivo, la foto solo agrega el texto.
        if (_stamp == null) {
          _method = _Method.photo;
          _stamp = stamp;
          _elapsed = _measuring ? _stopwatch.elapsed : null;
        }
        _measuring = false;
        _text = text;
        _textCorrect
          ..clear()
          ..addAll(_stamp == null ? const {} : _matchingFields(text, _stamp!));
      });
    } finally {
      await deleteTempFile(photo.path);
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Campos del texto que coinciden con el timbre (verificación automática).
  static Set<String> _matchingFields(ReceiptText text, ReceiptStamp stamp) => {
        if (text.rut == stamp.issuerRut) 'RUT',
        if (text.folio == stamp.folio) 'folio',
        if (text.date != null &&
            DateUtils.isSameDay(text.date, stamp.issueDate))
          'fecha',
        if (text.total == stamp.amount) 'total',
      };

  void _save({required bool hasStamp}) {
    setState(() {
      _trials.add(_Trial(
        hasStamp: hasStamp,
        condition: _condition,
        voucher: _voucher,
        payment: _payment,
        zoom: _zoom,
        method: hasStamp ? (_method ?? _Method.live) : null,
        stamp: hasStamp ? _stamp : null,
        elapsed: hasStamp ? _elapsed : null,
        text: _text,
        textCorrect: {..._textCorrect},
        textCheckedByStamp: _text != null && _stamp != null,
      ));
      _measuring = false;
      _method = null;
      _stamp = null;
      _elapsed = null;
      _text = null;
      _textCorrect.clear();
      _unreadable = null;
      _condition = _conditions.first;
      _voucher = _voucherTypes.first;
      _payment = _payments.first;
    });
    _stopwatch
      ..stop()
      ..reset();
  }

  String _csv() {
    String quote(Object? v) => '"${'${v ?? ''}'.replaceAll('"', '""')}"';
    String date(DateTime? d) =>
        d == null ? '' : DateFormat('yyyy-MM-dd').format(d);
    final rows = [
      '#,Comprobante,Pago,Estado,¿Trae timbre?,Método,¿Lectura exitosa?,'
          'Segundos,Zoom,Comercio,Tipo,RUT,Folio,Fecha,Monto,Primer ítem,'
          'Texto RUT,Texto folio,Texto fecha,Texto total,'
          'Texto correcto,Texto verificado con',
      for (final (i, t) in _trials.indexed)
        [
          i + 1,
          quote(t.voucher),
          quote(t.payment),
          t.condition,
          t.hasStamp ? 'Sí' : 'No',
          switch (t.method) {
            _Method.live => 'en vivo',
            _Method.photo => 'foto',
            null => '',
          },
          t.hasStamp ? (t.successful ? 'Sí' : 'No') : '',
          t.elapsed == null
              ? ''
              : (t.elapsed!.inMilliseconds / 1000).toStringAsFixed(1),
          t.zoom.toStringAsFixed(2),
          quote(t.stamp?.issuerName),
          t.stamp?.documentType ?? '',
          t.stamp?.issuerRut ?? '',
          t.stamp?.folio ?? '',
          date(t.stamp?.issueDate),
          t.stamp?.amount ?? '',
          quote(t.stamp?.firstItem),
          t.text?.rut ?? '',
          t.text?.folio ?? '',
          date(t.text?.date),
          t.text?.total ?? '',
          t.text == null
              ? ''
              : quote(_textFields.where(t.textCorrect.contains).join(' ')),
          t.text == null ? '' : (t.textCheckedByStamp ? 'timbre' : 'a mano'),
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
              height: 380,
              child: LayoutBuilder(
                builder: (context, constraints) => GestureDetector(
                  // Tocar enfoca en ese punto.
                  onTapUp: (d) => _controller.setFocusPoint(Offset(
                    d.localPosition.dx / constraints.maxWidth,
                    d.localPosition.dy / constraints.maxHeight,
                  )),
                  child: MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // La resolución real puede ser menor que la pedida: se muestra
          // para anotarla en el documento.
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, state, _) {
              final size = state.size;
              return Text(
                'Gira la boleta 90° (timbre vertical en la pantalla), a unos '
                '15–20 cm, y usa zoom. Toca la imagen para enfocar.'
                '${size.isEmpty ? '' : ' Cámara: ${size.width.round()}×${size.height.round()}.'}',
                style: TextStyle(fontSize: 12, color: context.colors.inkSoft),
              );
            },
          ),
          Row(
            children: [
              const Icon(Icons.zoom_in, size: 20),
              Expanded(
                child: Slider(
                  value: _zoom,
                  label: 'Zoom ${(_zoom * 100).round()}%',
                  divisions: 20,
                  onChanged: (v) {
                    setState(() => _zoom = v);
                    _controller.setZoomScale(v);
                  },
                ),
              ),
              IconButton(
                tooltip: _torch ? 'Apagar linterna' : 'Encender linterna',
                icon: Icon(_torch ? Icons.flash_on : Icons.flash_off),
                onPressed: () {
                  setState(() => _torch = !_torch);
                  _controller.toggleTorch();
                },
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _busy || _measuring || _stamp != null
                    ? null
                    : _startMeasuring,
                icon: const Icon(Icons.timer_outlined),
                label: Text(_measuring ? 'Midiendo…' : 'Medir'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _takePhoto,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Tomar foto'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_busy) const LinearProgressIndicator(),
          if (_stamp != null)
            _StampCard(stamp: _stamp!, elapsed: _elapsed, method: _method!)
          else if (_measuring)
            Text('Apunta al timbre. Si no lo lee, prueba con "Tomar foto".',
                style: TextStyle(color: context.colors.inkSoft))
          else if (_method == null && _text == null)
            Text('Encuadra el timbre y toca "Medir", o toma una foto.',
                style: TextStyle(color: context.colors.inkSoft)),
          if (_unreadable != null) ...[
            const SizedBox(height: 8),
            Text('Se leyó un código que no es un timbre válido: $_unreadable',
                style: TextStyle(color: context.colors.rust)),
          ],
          if (_text != null) ...[
            const SizedBox(height: 12),
            _TextCard(
              text: _text!,
              correct: _textCorrect,
              checkedByStamp: _stamp != null,
              onToggle: (field) => setState(() {
                if (!_textCorrect.remove(field)) _textCorrect.add(field);
              }),
            ),
          ],
          const SizedBox(height: 16),
          _ChoiceRow(
            label: 'Comprobante',
            options: _voucherTypes,
            selected: _voucher,
            onSelected: (v) => setState(() => _voucher = v),
          ),
          _ChoiceRow(
            label: 'Pagado con',
            options: _payments,
            selected: _payment,
            onSelected: (v) => setState(() => _payment = v),
          ),
          _ChoiceRow(
            label: 'Estado de la boleta',
            options: _conditions,
            selected: _condition,
            onSelected: (v) => setState(() => _condition = v),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: _busy ? null : () => _save(hasStamp: true),
                child: Text(_stamp != null
                    ? 'Guardar y siguiente'
                    : 'Trae timbre, no se pudo leer'),
              ),
              OutlinedButton(
                onPressed: _busy || _stamp != null
                    ? null
                    : () => _save(hasStamp: false),
                child: const Text('No trae timbre'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });
  final String label;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: context.colors.inkSoft)),
          Wrap(
            spacing: 8,
            children: [
              for (final o in options)
                ChoiceChip(
                  label: Text(o),
                  selected: selected == o,
                  onSelected: (_) => onSelected(o),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StampCard extends StatelessWidget {
  const _StampCard(
      {required this.stamp, required this.elapsed, required this.method});
  final ReceiptStamp stamp;
  final Duration? elapsed;
  final _Method method;

  @override
  Widget build(BuildContext context) {
    final fast = method == _Method.photo ||
        (elapsed != null && elapsed! <= kMaxSuccessfulReadTime);
    final seconds = elapsed == null
        ? ''
        : ' (${(elapsed!.inMilliseconds / 1000).toStringAsFixed(1)} s)';
    final title = switch (method) {
      _Method.photo => 'Timbre leído en la foto$seconds',
      _Method.live when fast => 'Lectura exitosa$seconds',
      _Method.live => 'Leída, pero tardó más de 3 s$seconds',
    };
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
            title,
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

/// Lo que leyó el reconocimiento de texto. Con timbre, cada campo se marca
/// solo según coincida; sin timbre, se toca cada campo que esté correcto.
class _TextCard extends StatelessWidget {
  const _TextCard({
    required this.text,
    required this.correct,
    required this.checkedByStamp,
    required this.onToggle,
  });
  final ReceiptText text;
  final Set<String> correct;
  final bool checkedByStamp;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final values = {
      'RUT': text.rut,
      'folio': text.folio?.toString(),
      'fecha': text.date == null
          ? null
          : DateFormat(
                  text.date!.hour == 0 && text.date!.minute == 0
                      ? 'd MMM yyyy'
                      : 'd MMM yyyy HH:mm',
                  'es_CL')
              .format(text.date!),
      'total': text.total == null ? null : currencyFmt.format(text.total),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.rule),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Texto leído (plan B)',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            checkedByStamp
                ? 'Comparado automáticamente con el timbre.'
                : 'Toca los campos que coinciden con la boleta.',
            style: TextStyle(fontSize: 12, color: context.colors.inkSoft),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final field in _textFields)
                FilterChip(
                  label: Text('$field: ${values[field] ?? '—'}'),
                  selected: correct.contains(field),
                  onSelected: checkedByStamp || values[field] == null
                      ? null
                      : (_) => onToggle(field),
                ),
            ],
          ),
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
