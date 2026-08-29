import 'backup_io_native.dart'
    if (dart.library.js_interop) 'backup_io_web.dart';

/// Escribe [bytes] en el sistema de archivos nativo, en [path]. No-op en
/// web: ahí la descarga ya la dispara `FilePicker.saveFile(bytes: ...)`.
Future<void> writeBytesToFile(String path, List<int> bytes) =>
    writeBytesToFileImpl(path, bytes);
