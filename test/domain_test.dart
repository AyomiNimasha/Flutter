import 'package:flutter_test/flutter_test.dart';
import 'package:pawshots/domain/models/records.dart';
import 'package:pawshots/domain/use_cases/reminder_plan.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  setUpAll(tz.initializeTimeZones);
  test('statuses follow Colombo midnight and inclusive 14 day boundary', () {
    const vaccine = Vaccine(
      id: 'v',
      petId: 'p',
      name: 'Custom',
      nextDue: '2026-10-24',
    );
    expect(
      vaccine.status(DateTime.parse('2026-10-24T18:29:59Z')),
      VaccineStatus.dueSoon,
    );
    expect(
      vaccine.status(DateTime.parse('2026-10-24T18:30:00Z')),
      VaccineStatus.overdue,
    );
    expect(
      vaccine.status(DateTime.parse('2026-10-09T18:30:00Z')),
      VaccineStatus.dueSoon,
    );
    expect(
      vaccine.status(DateTime.parse('2026-10-09T18:29:59Z')),
      VaccineStatus.upcoming,
    );
  });
  test('given date with pending booster is not done', () {
    const vaccine = Vaccine(
      id: 'v',
      petId: 'p',
      name: 'Custom',
      dateGiven: '2026-01-01',
      nextDue: '2027-01-01',
    );
    expect(
      vaccine.status(DateTime.parse('2026-10-23T00:00:00Z')),
      VaccineStatus.upcoming,
    );
    const completed = Vaccine(
      id: 'v',
      petId: 'p',
      name: 'Custom',
      dateGiven: '2026-01-01',
    );
    expect(completed.status(), VaccineStatus.done);
  });
  test(
    'reminders use 09:00 Colombo (03:30 UTC), filter elapsed and deleted records',
    () {
      const vaccine = Vaccine(
        id: 'v',
        petId: 'p',
        name: 'Custom',
        nextDue: '2026-11-15',
      );
      final reminders = buildReminderPlan(
        [vaccine],
        const ReminderPreferences(),
        now: DateTime.utc(2026, 11, 1, 4),
      );
      expect(reminders.map((r) => r.at.toUtc()), [
        DateTime.utc(2026, 11, 12, 3, 30),
        DateTime.utc(2026, 11, 14, 3, 30),
        DateTime.utc(2026, 11, 15, 3, 30),
      ]);
      expect(
        buildReminderPlan(
          [
            const Vaccine(
              id: 'd',
              petId: 'p',
              name: 'Deleted',
              nextDue: '2026-11-15',
              deleted: true,
            ),
          ],
          const ReminderPreferences(),
          now: DateTime.utc(2026),
        ),
        isEmpty,
      );
    },
  );
  test('disabled offsets, API key names, and time round-trip', () {
    const value = ReminderPreferences(days: [1, 0], hour: 17, minute: 45);
    expect(value.toJson()['remind_1_day'], true);
    final loaded = ReminderPreferences.fromJson(value.toJson());
    expect(loaded.days, [1, 0]);
    expect(loaded.hour, 17);
    expect(loaded.minute, 45);
    expect(
      buildReminderPlan([
        const Vaccine(id: 'v', petId: 'p', name: 'Test', nextDue: '2027-01-01'),
      ], const ReminderPreferences(days: [])),
      isEmpty,
    );
  });
}
