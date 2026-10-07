import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../backup/backup_io.dart';
import '../backup/backup_validation.dart';
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
    if (bytes == null) {
      throw const FormatException(kBackupUnreadableMessage);
    }
    return restoreFromBytes(bytes);
  }

  /// Valida y restaura un respaldo ya leído en memoria. Separado de
  /// [importBackup] para poder probarlo sin el selector de archivos. Cualquier
  /// fallo sale como [FormatException] con un mensaje apto para el usuario, y
  /// los datos actuales no se tocan (la validación corre antes de borrar y
  /// `restoreAllData` es una transacción).
  Future<bool> restoreFromBytes(Uint8List bytes) async {
    if (bytes.isEmpty) throw const FormatException(kBackupUnreadableMessage);
    if (bytes.length > kMaxBackupBytes) {
      throw const FormatException(kBackupTooLargeMessage);
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const FormatException(kBackupNotARespaldoMessage);
    }
    validateBackupData(decoded);
    try {
      await _db.restoreAllData(decoded as Map<String, dynamic>);
    } on TypeError {
      // Campos con tipo equivocado dentro de una fila.
      throw const FormatException(kBackupCorruptMessage);
    }
    return true;
  }
}
