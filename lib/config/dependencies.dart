import '../data/database/local_database.dart';
import '../data/repositories/pawshots_repository.dart';
import '../data/services/notification/notification_service.dart';
import '../ui/pets/view_models/workspace_view_model.dart';

Future<WorkspaceViewModel> createWorkspace() async {
  final database = await LocalDatabase.open();
  try {
    final scheduler = NotificationService();
    await scheduler.initialize();
    final model = WorkspaceViewModel(PawshotsRepository(database), scheduler);
    await model.load();
    return model;
  } catch (_) {
    await database.close();
    rethrow;
  }
}
