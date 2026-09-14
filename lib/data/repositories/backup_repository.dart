import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../backup/backup_io.dart';
import '../local/app_database.dart';

/// RF16/RF17/RNF09: respaldo local — exportar todos los datos a un archivo
/// JSON e importarlos de vuelta, sin conexión a internet.
class BackupRepository {
  BackupRepository(this._db);
  final AppDatabase _db;

  Future<String> _exportJson() async {
    final data = await _db.exportAllData();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Devuelve true si el usuario completó el guardado (false si canceló).
  Future<bool> exportBackup() async {
    final jsonStr = await _exportJson();
    final bytes = Uint8List.fromList(utf8.encode(jsonStr));
    final fileName =
        'peso_a_peso_backup_${DateTime.now().toIso8601String().substring(0, 10)}.json';

    final path = await FilePicker.saveFile(
      dialogTitle: 'Guardar respaldo',
      fileName: fileName,
      bytes: bytes,
    );
    if (path == null) return false;
    if (!kIsWeb) {
      await writeBytesToFile(path, bytes);
    }
    return true;
  }

  /// Reemplaza todos los datos actuales por los del archivo elegido.
  /// Devuelve true si se restauró, false si el usuario canceló la selección.
  /// Lanza [FormatException] si el archivo no tiene el formato esperado.
  Future<bool> importBackup() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return false;

    final bytes = result.files.single.bytes;
    if (bytes == null) return false;

    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic> || decoded['categories'] is! List) {
      throw const FormatException(
          'El archivo no tiene el formato de respaldo esperado.');
    }
    await _db.restoreAllData(decoded);
    return true;
  }
}
