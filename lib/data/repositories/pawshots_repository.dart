import '../../domain/models/records.dart';
import '../database/local_database.dart';

class PawshotsRepository {
  PawshotsRepository(this.database);
  final LocalDatabase database;
  Future<int> pendingCount() => database.pendingCount();
  Future<List<Pet>> pets() async =>
      (await database.read('pet')).map(Pet.fromJson).toList();
  Future<List<Vaccine>> vaccines() async =>
      (await database.read('vaccine')).map(Vaccine.fromJson).toList();
  Future<ReminderPreferences> preferences() async {
    final rows = await database.read('preferences');
    return rows.isEmpty
        ? const ReminderPreferences()
        : ReminderPreferences.fromJson(rows.single);
  }

  Future<void> savePet(Pet pet, {required bool isNew}) =>
      database.transaction(() async {
        await database.put('pet', pet.id, pet.toJson());
        await database.enqueue(
          isNew ? 'POST' : 'PUT',
          isNew ? '/pets' : '/pets/${pet.id}',
          pet.toJson(),
        );
      });
  Future<void> deletePet(Pet pet) => database.transaction(() async {
    for (final vaccine in await vaccines()) {
      if (vaccine.petId == pet.id) await database.remove('vaccine', vaccine.id);
    }
    await database.remove('pet', pet.id);
    await database.enqueue('DELETE', '/pets/${pet.id}', {});
  });
  Future<void> saveVaccine(Vaccine vaccine, {required bool isNew}) =>
      database.transaction(() async {
        await database.put('vaccine', vaccine.id, vaccine.toJson());
        final path = '/pets/${vaccine.petId}/vaccines';
        await database.enqueue(
          isNew ? 'POST' : 'PUT',
          isNew ? path : '$path/${vaccine.id}',
          vaccine.toJson(),
        );
      });
  Future<void> deleteVaccine(Vaccine vaccine) => database.transaction(() async {
    await database.put('vaccine', vaccine.id, {
      ...vaccine.toJson(),
      'is_deleted': true,
    });
    await database.enqueue(
      'DELETE',
      '/pets/${vaccine.petId}/vaccines/${vaccine.id}',
      {},
    );
  });
  Future<void> savePreferences(ReminderPreferences value) =>
      database.transaction(() async {
        await database.put('preferences', 'local', value.toJson());
        await database.enqueue('PUT', '/reminder-settings', value.toJson());
      });
}
