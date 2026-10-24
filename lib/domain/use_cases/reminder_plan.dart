import 'package:timezone/timezone.dart' as tz;
import '../models/records.dart';

class ScheduledReminder {
  const ScheduledReminder(this.vaccine, this.at);
  final Vaccine vaccine;
  final tz.TZDateTime at;
}

// Provisional offline schedule, reconciled with API-calculated times once sync
// is implemented. Explicit Colombo location ignores the device timezone.
List<ScheduledReminder> buildReminderPlan(
  List<Vaccine> vaccines,
  ReminderPreferences settings, {
  DateTime? now,
}) {
  final location = tz.getLocation('Asia/Colombo');
  final current = now ?? DateTime.now();
  final result = <ScheduledReminder>[];
  for (final vaccine in vaccines) {
    if (vaccine.deleted || vaccine.nextDue == null) continue;
    final due = DateTime.parse('${vaccine.nextDue}T00:00:00Z');
    for (final offset in settings.days) {
      final date = due.subtract(Duration(days: offset));
      final at = tz.TZDateTime(
        location,
        date.year,
        date.month,
        date.day,
        settings.hour,
        settings.minute,
      );
      if (at.isAfter(current)) result.add(ScheduledReminder(vaccine, at));
    }
  }
  result.sort((a, b) => a.at.compareTo(b.at));
  // Keep device queues bounded. Refresh on every app resume and local change.
  return result.take(60).toList();
}
