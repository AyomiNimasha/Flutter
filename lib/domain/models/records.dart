// Calendar dates remain YYYY-MM-DD strings across SQLite and the REST API.
String calendarDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

DateTime colomboToday([DateTime? now]) {
  final local = (now ?? DateTime.now()).toUtc().add(
    const Duration(minutes: 330),
  );
  return DateTime.utc(local.year, local.month, local.day);
}

enum VaccineStatus { upcoming, dueSoon, overdue, done }

class Pet {
  const Pet({
    required this.id,
    required this.name,
    required this.species,
    required this.birthDate,
    this.breed = '',
    this.microchip = '',
  });
  final String id, name, species, birthDate, breed, microchip;
  factory Pet.fromJson(Map<String, dynamic> j) => Pet(
    id: j['id'] as String,
    name: j['name'] as String,
    species: j['species'] as String,
    birthDate: j['birth_date'] as String,
    breed: j['breed'] as String? ?? '',
    microchip: j['microchip_no'] as String? ?? '',
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'species': species,
    'birth_date': birthDate,
    'breed': breed,
    'microchip_no': microchip,
  };
}

class Vaccine {
  const Vaccine({
    required this.id,
    required this.petId,
    required this.name,
    this.dateGiven,
    this.nextDue,
    this.batch = '',
    this.vet = '',
    this.clinic = '',
    this.notes = '',
    this.deleted = false,
  });
  final String id, petId, name, batch, vet, clinic, notes;
  final String? dateGiven, nextDue;
  final bool deleted;

  VaccineStatus status([DateTime? now]) {
    if (nextDue == null) return VaccineStatus.done;
    final days = DateTime.parse(
      '${nextDue!}T00:00:00Z',
    ).difference(colomboToday(now)).inDays;
    if (days < 0) return VaccineStatus.overdue;
    return days <= 14 ? VaccineStatus.dueSoon : VaccineStatus.upcoming;
  }

  factory Vaccine.fromJson(Map<String, dynamic> j) => Vaccine(
    id: j['id'] as String,
    petId: j['pet_id'] as String,
    name: j['vaccine_name'] as String,
    dateGiven: j['date_given'] as String?,
    nextDue: j['next_due_date'] as String?,
    batch: j['batch_number'] as String? ?? '',
    vet: j['vet_name'] as String? ?? '',
    clinic: j['clinic'] as String? ?? '',
    notes: j['notes'] as String? ?? '',
    deleted: j['is_deleted'] as bool? ?? false,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'pet_id': petId,
    'vaccine_name': name,
    'date_given': dateGiven,
    'next_due_date': nextDue,
    'batch_number': batch,
    'vet_name': vet,
    'clinic': clinic,
    'notes': notes,
    'is_deleted': deleted,
    'is_custom': true,
    'template_id': null,
  };
}

class ReminderPreferences {
  const ReminderPreferences({
    this.days = const [14, 3, 1, 0],
    this.hour = 9,
    this.minute = 0,
  });
  final List<int> days;
  final int hour, minute;
  factory ReminderPreferences.fromJson(Map<String, dynamic> j) =>
      ReminderPreferences(
        days: [
          for (final day in [14, 3, 1, 0])
            if (j[reminderKey(day)] == true) day,
        ],
        hour: int.parse((j['notify_time'] as String).split(':')[0]),
        minute: int.parse((j['notify_time'] as String).split(':')[1]),
      );
  Map<String, dynamic> toJson() => {
    for (final day in [14, 3, 1, 0]) reminderKey(day): days.contains(day),
    'notify_time':
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00',
  };
}

String reminderKey(int day) => switch (day) {
  0 => 'remind_on_day',
  1 => 'remind_1_day',
  _ => 'remind_${day}_days',
};
