import 'dart:convert';
import 'package:drift/drift.dart';
import 'open_native.dart' if (dart.library.js_interop) 'open_web.dart';

// A document cache keeps the API payload intact. Mutations and cached writes
// are committed together. No code generation is needed for these SQL queries.
class LocalDatabase extends GeneratedDatabase {
  LocalDatabase(super.executor);
  static Future<LocalDatabase> open() async {
    return LocalDatabase(await openLocalDatabase());
  }

  @override
  int get schemaVersion => 1;
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => const [];
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) async {
      await customStatement(
        'CREATE TABLE documents (kind TEXT NOT NULL, id TEXT NOT NULL, body TEXT NOT NULL, PRIMARY KEY(kind, id))',
      );
      await customStatement(
        'CREATE TABLE outbox (sequence INTEGER PRIMARY KEY AUTOINCREMENT, method TEXT NOT NULL, path TEXT NOT NULL, body TEXT NOT NULL)',
      );
    },
  );

  Future<List<Map<String, dynamic>>> read(String kind) async {
    final rows = await customSelect(
      'SELECT body FROM documents WHERE kind = ? ORDER BY rowid',
      variables: [Variable.withString(kind)],
    ).get();
    return rows
        .map(
          (row) => jsonDecode(row.read<String>('body')) as Map<String, dynamic>,
        )
        .toList();
  }

  Future<void> put(
    String kind,
    String id,
    Map<String, dynamic> body,
  ) => customStatement(
    'INSERT INTO documents(kind,id,body) VALUES (?,?,?) ON CONFLICT(kind,id) DO UPDATE SET body=excluded.body',
    [kind, id, jsonEncode(body)],
  );
  Future<void> remove(String kind, String id) => customStatement(
    'DELETE FROM documents WHERE kind = ? AND id = ?',
    [kind, id],
  );
  Future<void> enqueue(String method, String path, Map<String, dynamic> body) =>
      customStatement('INSERT INTO outbox(method,path,body) VALUES (?,?,?)', [
        method,
        path,
        jsonEncode(body),
      ]);
  Future<int> pendingCount() async => (await customSelect(
    'SELECT count(*) AS count FROM outbox',
  ).getSingle()).read<int>('count');
}
