import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import '../../../domain/models/records.dart';
import '../../../domain/use_cases/reminder_plan.dart';
import 'reminder_scheduler.dart';

class NotificationService implements ReminderScheduler {
  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void> _pending = Future.value();
  bool _initialized = false;
  Future<void> initialize() async {
    tz.initializeTimeZones();
    if (_isAndroid) {
      try {
        _initialized =
            await _plugin.initialize(
              const InitializationSettings(
                android: AndroidInitializationSettings('@mipmap/ic_launcher'),
              ),
            ) ??
            false;
      } catch (_) {
        // Keep pet records usable even if the OS notification service fails.
        _initialized = false;
      }
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!_isAndroid || !_initialized) return false;
    return await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission() ??
        false;
  }

  @override
  Future<void> rebuild(
    List<Vaccine> vaccines,
    ReminderPreferences preferences,
    String title,
    String channelName,
  ) {
    // A permission dialog can resume the app during a save. Serialize rebuilds
    // so one cancellation cannot erase another rebuild's newly queued alarms.
    final next = _pending.then(
      (_) => _rebuild(vaccines, preferences, title, channelName),
    );
    _pending = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return next;
  }

  Future<void> _rebuild(
    List<Vaccine> vaccines,
    ReminderPreferences preferences,
    String title,
    String channelName,
  ) async {
    if (!_isAndroid) return;
    if (!_initialized) throw StateError('Notifications unavailable');
    await _plugin.cancelAll();
    final reminders = buildReminderPlan(vaccines, preferences);
    for (var i = 0; i < reminders.length; i++) {
      final item = reminders[i];
      await _plugin.zonedSchedule(
        i,
        title,
        item.vaccine.name,
        item.at,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'pawshots_vaccines',
            channelName,
            importance: Importance.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: item.vaccine.petId,
      );
    }
  }
}
