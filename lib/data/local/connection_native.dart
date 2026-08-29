import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';

/// RNF01/RNF02: la base queda cifrada en disco con SQLCipher. La clave vive
/// solo en el Keystore (Android) / Keychain (iOS) vía flutter_secure_storage
/// — nunca en el código ni en un archivo plano.
const _secureStorage = FlutterSecureStorage();
const _dbEncryptionKeyStorageKey = 'gasto_a_mano_db_encryption_key';

/// Se ejecuta en el isolate donde se abre la base (ver [NativeDatabase.
/// createInBackground]) para que sqlite3 cargue `libsqlcipher.so` en vez del
/// sqlite3 plano. Debe ser una función top-level para poder enviarse al
/// isolate; en iOS/macOS/Linux/Windows sqlcipher_flutter_libs ya reemplaza la
/// librería sqlite3 estándar a nivel nativo, así que no hace falta overridear
/// nada ahí.
void _overrideOpenForSqlCipher() {
  if (Platform.isAndroid) {
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  }
}

Future<String> _databaseEncryptionKey() async {
  final existing = await _secureStorage.read(key: _dbEncryptionKeyStorageKey);
  if (existing != null && existing.isNotEmpty) return existing;

  final random = Random.secure();
  final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
  final key = base64Url.encode(keyBytes);
  await _secureStorage.write(key: _dbEncryptionKeyStorageKey, value: key);
  return key;
}

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    if (Platform.isAndroid) {
      // Recomendado por sqlcipher_flutter_libs antes de tocar sqlite3 en
      // cualquier isolate: evita crashes al cargar libsqlcipher.so en
      // versiones viejas de Android.
      await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
    }

    final key = await _databaseEncryptionKey();
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'libro_de_gastos.db'));

    return NativeDatabase.createInBackground(
      file,
      isolateSetup: _overrideOpenForSqlCipher,
      setup: (rawDb) {
        // Comillas dobles porque la clave (base64url) puede contener '='.
        rawDb.execute('PRAGMA key = "$key";');

        // PRAGMA key falla en silencio con sqlite3 plano — sin este chequeo
        // la app seguiría funcionando pero guardando todo sin cifrar.
        final cipherVersion = rawDb.select('PRAGMA cipher_version;');
        if (cipherVersion.isEmpty) {
          throw StateError(
            'SQLCipher no está disponible: la base de datos se abriría sin '
            'cifrar. Revisa que sqlcipher_flutter_libs esté correctamente '
            'instalado para esta plataforma.',
          );
        }
      },
    );
  });
}
