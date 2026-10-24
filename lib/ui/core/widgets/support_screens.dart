import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../pets/view_models/workspace_view_model.dart';
import '../../reminders/widgets/reminder_settings_screen.dart';
import '../../vaccinations/widgets/plan_screen.dart';
import '../theme/pawshots_theme.dart';
import 'pawshots_widgets.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key, required this.model});
  final WorkspaceViewModel model;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.records)),
      body: ListenableBuilder(
        listenable: model,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            EditorHeader(
              icon: Icons.description_outlined,
              title: s.recordsHeading,
              subtitle: s.recordsHint,
            ),
            for (final pet in model.pets)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    leading: SizedBox(
                      width: 54,
                      height: 54,
                      child: PetPortrait(species: pet.species),
                    ),
                    title: Text(
                      pet.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(s.vaccinePlan),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: PawColors.muted,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => PlanScreen(model: model, petId: pet.id),
                      ),
                    ),
                  ),
                ),
              ),
            if (model.pets.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(s.emptyVaccinesBody),
                ),
              ),
            const SizedBox(height: 16),
            IceNotice(
              text: s.certificatePending,
              icon: Icons.picture_as_pdf_outlined,
            ),
            const SizedBox(height: 14),
            Text(
              s.certificateNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.model});
  final WorkspaceViewModel model;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(child: BrandMark(size: 62)),
          const SizedBox(height: 16),
          Center(
            child: Text(
              s.appName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 28),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.notifications_none_rounded,
                    color: PawColors.petrol,
                  ),
                  title: Text(s.reminders),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ReminderSettingsScreen(model: model),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.language, color: PawColors.petrol),
                  title: Text(s.language),
                  subtitle: Text(s.english),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(s.language),
                      content: Text(s.languagePending),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(s.cancel),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          IceNotice(
            text: model.isDemo
                ? s.demoNotice
                : (kIsWeb ? s.browserPreviewNote : s.localWorkspace),
            icon: Icons.offline_pin_outlined,
          ),
          const SizedBox(height: 18),
          Text(
            s.illustrativePhotos,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Text(s.disclaimer, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
