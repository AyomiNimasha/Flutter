import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawshots/data/database/local_database.dart';
import 'package:pawshots/data/repositories/pawshots_repository.dart';
import 'package:pawshots/domain/models/records.dart';

void main() {
  late LocalDatabase db;
  late PawshotsRepository repository;
  bool databaseClosed = false;
  setUp(() {
    databaseClosed = false;
    db = LocalDatabase(NativeDatabase.memory());
    repository = PawshotsRepository(db);
  });
  tearDown(() async {
    if (!databaseClosed) await db.close();
  });
  const pet = Pet(
    id: 'pet',
    name: 'Milo',
    species: 'cat',
    birthDate: '2024-01-01',
  );
  const vaccine = Vaccine(
    id: 'vaccine',
    petId: 'pet',
    name: 'Custom',
    nextDue: '2027-01-01',
  );

  test(
    'soft delete preserves tombstone; pet deletion removes cache children and queues deletion',
    () async {
      await repository.savePet(pet, isNew: true);
      await repository.saveVaccine(vaccine, isNew: true);
      await repository.deleteVaccine(vaccine);
      expect((await repository.vaccines()).single.deleted, true);
      expect(await db.pendingCount(), 3);
      await repository.deletePet(pet);
      expect(await repository.pets(), isEmpty);
      expect(await repository.vaccines(), isEmpty);
      final queued = await db
          .customSelect('SELECT method, path FROM outbox ORDER BY sequence')
          .get();
      expect(queued.last.read<String>('method'), 'DELETE');
      expect(queued.last.read<String>('path'), '/pets/pet');
    },
  );
  test('a failed outbox write rolls back the cached write', () async {
    await db.read('pet');
    await db.customStatement(
      "CREATE TRIGGER fail_outbox BEFORE INSERT ON outbox BEGIN SELECT RAISE(ABORT, 'test failure'); END",
    );
    await expectLater(repository.savePet(pet, isNew: true), throwsA(anything));
    expect(await repository.pets(), isEmpty);
  });
  test('records and preferences survive database reopening', () async {
    await db.close(); // This test uses its own file-backed connections.
    databaseClosed = true;
    final directory = await Directory.systemTemp.createTemp('pawshots-test-');
    final file = File('${directory.path}/cache.sqlite');
    final first = LocalDatabase(NativeDatabase(file));
    try {
      await PawshotsRepository(first).savePet(pet, isNew: true);
      await PawshotsRepository(
        first,
      ).savePreferences(const ReminderPreferences(days: [1], hour: 10));
    } finally {
      await first.close();
    }
    final second = LocalDatabase(NativeDatabase(file));
    try {
      final reopened = PawshotsRepository(second);
      expect((await reopened.pets()).single.name, 'Milo');
      expect((await reopened.preferences()).days, [1]);
      expect((await reopened.preferences()).hour, 10);
      expect(await second.pendingCount(), 2);
    } finally {
      await second.close();
      await directory.delete(recursive: true);
    }
  });
}
