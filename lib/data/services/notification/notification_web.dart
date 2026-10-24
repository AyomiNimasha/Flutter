import '../../../domain/models/records.dart';
import 'reminder_scheduler.dart';

// Browser preview deliberately does not promise background device alarms.
class NotificationService implements ReminderScheduler {
  Future<void> initialize() async {}
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<void> rebuild(
    List<Vaccine> vaccines,
    ReminderPreferences preferences,
    String title,
    String channelName,
  ) async {}
}
