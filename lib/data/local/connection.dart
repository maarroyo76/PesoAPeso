import 'package:drift/drift.dart';

import 'connection_native.dart'
    if (dart.library.js_interop) 'connection_web.dart';

QueryExecutor openDatabaseConnection() => openConnection();

/// Borra la base de datos del dispositivo (y en nativo, también su clave de
/// cifrado), para que la próxima apertura cree una base nueva y vacía. Solo
/// para la pantalla de error de arranque, cuando la base existente ya no se
/// puede abrir; la conexión anterior debe estar cerrada.
Future<void> deleteDatabaseStorage() => deleteStorage();
