import 'delete_file_native.dart'
    if (dart.library.js_interop) 'delete_file_web.dart';

/// Borra una foto temporal de la prueba de boletas: las imágenes no se
/// guardan en el teléfono (ni salen de él).
Future<void> deleteTempFile(String path) => deleteFileAt(path);
