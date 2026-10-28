import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

const _dbName = 'libro_de_gastos';
final _sqlite3Uri = Uri.parse('sqlite3.wasm');
final _driftWorkerUri = Uri.parse('drift_worker.js');

QueryExecutor openConnection() {
  return DatabaseConnection.delayed(Future(() async {
    final result = await WasmDatabase.open(
      databaseName: _dbName,
      sqlite3Uri: _sqlite3Uri,
      driftWorkerUri: _driftWorkerUri,
    );
    return result.resolvedExecutor;
  }));
}

Future<void> deleteStorage() async {
  final probed = await WasmDatabase.probe(
    sqlite3Uri: _sqlite3Uri,
    driftWorkerUri: _driftWorkerUri,
    databaseName: _dbName,
  );
  for (final existing in probed.existingDatabases) {
    if (existing.$2 == _dbName) await probed.deleteDatabase(existing);
  }
}
