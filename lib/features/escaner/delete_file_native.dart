import 'dart:io';

Future<void> deleteFileAt(String path) async {
  try {
    await File(path).delete();
  } on FileSystemException {
    // Ya no existe: nada que borrar.
  }
}
