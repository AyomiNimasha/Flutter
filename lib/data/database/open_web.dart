import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

Future<QueryExecutor> openLocalDatabase() async {
  final result = await WasmDatabase.open(
    databaseName: 'pawshots_browser',
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.dart.js'),
  );
  // Do not silently present an ephemeral cache as durable pet records.
  if (result.chosenImplementation == WasmStorageImplementation.inMemory) {
    await result.resolvedExecutor.close();
    throw StateError('Persistent browser storage is unavailable');
  }
  return result.resolvedExecutor;
}
