import 'package:flutter/foundation.dart';
import '../../../data/repositories/pawshots_repository.dart';
import '../../../data/services/notification/notification_service.dart';
import '../../../domain/models/records.dart';

class WorkspaceViewModel extends ChangeNotifier {
  WorkspaceViewModel(this.repository, this.scheduler, {this.isDemo = false});
  final bool isDemo;
  final PawshotsRepository repository;
  final ReminderScheduler scheduler;
  List<Pet> pets = [];
  List<Vaccine> vaccines = [];
  ReminderPreferences preferences = const ReminderPreferences();
  int pending = 0;
  bool busy = false;
  bool failed = false;
  bool reminderFailed = false;

  void refreshStatuses() => notifyListeners();

  Future<void> load() async {
    pets = await repository.pets();
    vaccines = await repository.vaccines();
    preferences = await repository.preferences();
    pending = await repository.pendingCount();
    notifyListeners();
  }

  List<Vaccine> forPet(String id) =>
      vaccines.where((v) => v.petId == id && !v.deleted).toList();

  Future<bool> change(
    Future<void> Function() write,
    String title,
    String channel,
  ) async {
    if (busy) return false;
    busy = true;
    failed = false;
    notifyListeners();
    try {
      await write();
      await load();
      await refreshReminders(title, channel);
      return true;
    } catch (_) {
      failed = true;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> refreshReminders(String title, String channel) async {
    try {
      await scheduler.rebuild(vaccines, preferences, title, channel);
      reminderFailed = false;
    } catch (_) {
      reminderFailed = true;
    }
    notifyListeners();
  }
}
