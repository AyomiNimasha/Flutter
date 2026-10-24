import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawshots/data/database/local_database.dart';
import 'package:pawshots/data/repositories/pawshots_repository.dart';
import 'package:pawshots/data/services/notification/notification_service.dart';
import 'package:pawshots/domain/models/records.dart';
import 'package:pawshots/main.dart';
import 'package:pawshots/ui/core/widgets/date_field.dart';
import 'package:pawshots/ui/pets/view_models/workspace_view_model.dart';

class FakeScheduler implements ReminderScheduler {
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> rebuild(
    List<Vaccine> vaccines,
    ReminderPreferences preferences,
    String title,
    String channelName,
  ) async {}
}

void main() {
  testWidgets(
    'demo administration changes never enter real records or outbox',
    (tester) async {
      final db = LocalDatabase(NativeDatabase.memory());
      final model = WorkspaceViewModel(PawshotsRepository(db), FakeScheduler());
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        model.dispose();
        await db.close();
      });
      await model.load();
      await tester.pumpWidget(PawshotsApp(loadWorkspace: () async => model));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Explore demo'));
      await tester.pumpAndSettle();
      expect(find.text('6 of 8'), findsOneWidget);
      await tester.tap(find.text('Bruno').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Mark as given'));
      await tester.tap(find.text('Mark as given'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Save'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, 900));
      await tester.pumpAndSettle();
      expect(find.text('7 of 8 doses recorded'), findsOneWidget);
      expect(await model.repository.pets(), isEmpty);
      expect(await model.repository.vaccines(), isEmpty);
      expect(await db.pendingCount(), 0);
    },
  );

  testWidgets('pet plan saves a custom vaccine and shows its status', (
    tester,
  ) async {
    final db = LocalDatabase(NativeDatabase.memory());
    final repository = PawshotsRepository(db);
    await repository.savePet(
      const Pet(
        id: 'pet',
        name: 'Milo',
        species: 'cat',
        birthDate: '2024-01-01',
      ),
      isNew: true,
    );
    final model = WorkspaceViewModel(repository, FakeScheduler());
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      model.dispose();
      await db.close();
    });
    await model.load();
    await tester.pumpWidget(PawshotsApp(loadWorkspace: () async => model));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Milo').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add vaccine'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Clinic vaccine');
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is DateField && widget.label == 'Next due date',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Save'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Clinic vaccine'), findsOneWidget);
    expect(find.text('Due soon'), findsOneWidget);
    expect((await repository.vaccines()).single.name, 'Clinic vaccine');
  });

  testWidgets('empty state opens pet editor and validates required fields', (
    tester,
  ) async {
    final db = LocalDatabase(NativeDatabase.memory());
    final model = WorkspaceViewModel(PawshotsRepository(db), FakeScheduler());
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      model.dispose();
      await db.close();
    });
    await model.load();
    await tester.pumpWidget(PawshotsApp(loadWorkspace: () async => model));
    await tester.pumpAndSettle();
    expect(find.text('Healthy pets.\nBrighter days.'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Save'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter a value.'), findsNWidgets(2));
    expect(await db.pendingCount(), 0);
  });
}
