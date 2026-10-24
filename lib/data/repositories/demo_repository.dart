import '../../domain/models/records.dart';
import 'pawshots_repository.dart';

// Explicit, non-persistent design demo. Overrides every mutation so sample
// records never reach the user's SQLite database, outbox, or notification queue.
class DemoRepository extends PawshotsRepository {
  DemoRepository(
    PawshotsRepository source, {
    required String coreName,
    required String rabiesName,
  }) : super(source.database) {
    final now = colomboToday();
    _pets = [
      Pet(
        id: 'demo-bruno',
        name: 'Bruno',
        species: 'dog',
        breed: 'Mixed breed',
        birthDate: calendarDate(DateTime(now.year, now.month - 6, now.day)),
      ),
      Pet(
        id: 'demo-mimi',
        name: 'Mimi',
        species: 'cat',
        breed: 'Tabby',
        birthDate: calendarDate(DateTime(now.year - 1, now.month, now.day)),
      ),
    ];
    _vaccines = [
      for (var i = 0; i < 6; i++)
        Vaccine(
          id: 'demo-dose-$i',
          petId: 'demo-bruno',
          name: coreName,
          dateGiven: calendarDate(
            now.subtract(Duration(days: 42 + (5 - i) * 14)),
          ),
        ),
      Vaccine(
        id: 'demo-rabies',
        petId: 'demo-bruno',
        name: rabiesName,
        nextDue: calendarDate(now.add(const Duration(days: 3))),
      ),
      Vaccine(
        id: 'demo-upcoming',
        petId: 'demo-bruno',
        name: coreName,
        nextDue: calendarDate(now.add(const Duration(days: 25))),
      ),
    ];
  }
  late List<Pet> _pets;
  late List<Vaccine> _vaccines;
  ReminderPreferences _settings = const ReminderPreferences();
  @override
  Future<List<Pet>> pets() async => List.of(_pets);
  @override
  Future<List<Vaccine>> vaccines() async => List.of(_vaccines);
  @override
  Future<ReminderPreferences> preferences() async => _settings;
  @override
  Future<void> savePet(Pet pet, {required bool isNew}) async {
    _pets = [..._pets.where((p) => p.id != pet.id), pet];
  }

  @override
  Future<void> deletePet(Pet pet) async {
    _pets.removeWhere((p) => p.id == pet.id);
    _vaccines.removeWhere((v) => v.petId == pet.id);
  }

  @override
  Future<void> saveVaccine(Vaccine vaccine, {required bool isNew}) async {
    _vaccines = [..._vaccines.where((v) => v.id != vaccine.id), vaccine];
  }

  @override
  Future<void> deleteVaccine(Vaccine vaccine) async {
    _vaccines.removeWhere((v) => v.id == vaccine.id);
  }

  @override
  Future<void> savePreferences(ReminderPreferences value) async {
    _settings = value;
  }

  @override
  Future<int> pendingCount() async => 0;
}
