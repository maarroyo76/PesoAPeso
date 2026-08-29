import 'package:drift/drift.dart';

import 'connection_native.dart'
    if (dart.library.js_interop) 'connection_web.dart';

QueryExecutor openDatabaseConnection() => openConnection();
