import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../domain/models/records.dart';
import '../../../l10n/app_localizations.dart';
import '../../pets/view_models/workspace_view_model.dart';
import '../../core/widgets/pawshots_widgets.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key, required this.model});
  final WorkspaceViewModel model;
  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  late final Set<int> _days = widget.model.preferences.days.toSet();
  late TimeOfDay _time = TimeOfDay(
    hour: widget.model.preferences.hour,
    minute: widget.model.preferences.minute,
  );
  bool _saving = false;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.reminders)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              EditorHeader(
                icon: Icons.notifications_none_rounded,
                title: s.reminderHeading,
                subtitle: s.settingsIntro,
              ),
              if (widget.model.isDemo) IceNotice(text: s.demoNotice),
              const SizedBox(height: 20),
              for (final entry in [
                (14, s.remind14),
                (3, s.remind3),
                (1, s.remind1),
                (0, s.remind0),
              ])
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.$2),
                  value: _days.contains(entry.$1),
                  onChanged: _saving
                      ? null
                      : (value) => setState(() {
                          if (value) {
                            _days.add(entry.$1);
                          } else {
                            _days.remove(entry.$1);
                          }
                        }),
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.notificationTime),
                subtitle: Text(_time.format(context)),
                trailing: const Icon(Icons.schedule),
                onTap: _saving
                    ? null
                    : () async {
                        final value = await showTimePicker(
                          context: context,
                          initialTime: _time,
                        );
                        if (value != null && mounted) {
                          setState(() {
                            _time = value;
                          });
                        }
                      },
              ),
              const SizedBox(height: 20),
              if (kIsWeb) Text(s.browserReminderNote),
              if (!kIsWeb)
                OutlinedButton.icon(
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: Text(s.enableNotifications),
                  onPressed: _saving
                      ? null
                      : () async {
                          var allowed = false;
                          try {
                            allowed = await widget.model.scheduler
                                .requestPermission();
                          } catch (_) {
                            /* Show permission failure below. */
                          }
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                allowed
                                    ? s.permissionGranted
                                    : s.permissionDenied,
                              ),
                            ),
                          );
                        },
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() {
                          _saving = true;
                        });
                        final value = ReminderPreferences(
                          days: _days.toList()..sort(),
                          hour: _time.hour,
                          minute: _time.minute,
                        );
                        final success = await widget.model.change(
                          () => widget.model.repository.savePreferences(value),
                          s.notificationTitle,
                          s.notificationChannel,
                        );
                        if (!context.mounted) return;
                        setState(() {
                          _saving = false;
                        });
                        if (success) {
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(s.saveError)));
                        }
                      },
                child: Text(s.save),
              ),
              const SizedBox(height: 24),
              if (!kIsWeb)
                Text(
                  s.reminderLimit,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
