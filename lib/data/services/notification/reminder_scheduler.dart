import '../../../domain/models/records.dart';

abstract class ReminderScheduler {
  Future<bool> requestPermission();
  Future<void> rebuild(
    List<Vaccine> vaccines,
    ReminderPreferences preferences,
    String title,
    String channelName,
  );
}
