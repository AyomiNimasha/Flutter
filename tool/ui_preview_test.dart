// Visual QA runner. Render real Flutter widgets at the reference's mobile size.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawshots/data/database/local_database.dart';
import 'package:pawshots/data/repositories/pawshots_repository.dart';
import 'package:pawshots/data/services/notification/reminder_scheduler.dart';
import 'package:pawshots/domain/models/records.dart';
import 'package:pawshots/main.dart';
import 'package:pawshots/ui/pets/view_models/workspace_view_model.dart';

class _PreviewScheduler implements ReminderScheduler {
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('render reference-style screens without layout overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    final font = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await font.load();
    await icons.load();
    final db = LocalDatabase(NativeDatabase.memory());
    final model = WorkspaceViewModel(
      PawshotsRepository(db),
      _PreviewScheduler(),
    );
    final boundaryKey = GlobalKey();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      model.dispose();
      await db.close();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await model.load();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: PawshotsApp(loadWorkspace: () async => model),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/images/welcome_pets.png'),
        tester.element(find.byType(MaterialApp)),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: name);
      await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/ui_preview/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('01_welcome');
    await tester.tap(find.text('Explore demo'));
    await tester.pumpAndSettle();
    await capture('02_dashboard');
    await tester.tap(find.text('Bruno').last);
    await tester.pumpAndSettle();
    await capture('03_vaccine_plan');
    await tester.scrollUntilVisible(
      find.text('Add vaccine'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Add vaccine'));
    await tester.pumpAndSettle();
    await capture('04_vaccine_editor');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reminders'));
    await tester.pumpAndSettle();
    await capture('05_reminders');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Records'));
    await tester.pumpAndSettle();
    await capture('08_records');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await capture('06_settings');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add pet'));
    await tester.pumpAndSettle();
    await capture('07_pet_editor');
  });
}
