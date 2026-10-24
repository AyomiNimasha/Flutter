import 'package:flutter/material.dart';
import '../../../domain/models/records.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/theme/pawshots_theme.dart';
import '../../core/widgets/pawshots_widgets.dart';
import '../../pets/view_models/workspace_view_model.dart';
import '../../pets/widgets/pet_editor.dart';
import 'vaccine_editor.dart';

Future<bool> confirmDeletion(
  BuildContext context,
  String title,
  String body,
) async {
  final s = AppLocalizations.of(context)!;
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(s.delete),
            ),
          ],
        ),
      ) ??
      false;
}

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key, required this.model, required this.petId});
  final WorkspaceViewModel model;
  final String petId;
  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  bool _showAll = false;
  WorkspaceViewModel get model => widget.model;
  void _edit(Vaccine? vaccine) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) =>
          VaccineEditor(model: model, petId: widget.petId, vaccine: vaccine),
    ),
  );

  Future<void> _deletePet(Pet pet) async {
    final s = AppLocalizations.of(context)!;
    if (!await confirmDeletion(context, s.deletePet, s.deletePetBody)) return;
    final success = await model.change(
      () => model.repository.deletePet(pet),
      s.notificationTitle,
      s.notificationChannel,
    );
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.saveError)));
    }
  }

  Future<void> _deleteVaccine(Vaccine vaccine) async {
    final s = AppLocalizations.of(context)!;
    if (!await confirmDeletion(context, s.deleteVaccine, s.deleteVaccineBody)) {
      return;
    }
    final success = await model.change(
      () => model.repository.deleteVaccine(vaccine),
      s.notificationTitle,
      s.notificationChannel,
    );
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.saveError)));
    }
  }

  void _recordGiven(Vaccine vaccine) {
    // The editor confirms administration and lets the owner supply a next due
    // date from their veterinarian. No medical booster interval is invented.
    _edit(
      Vaccine(
        id: vaccine.id,
        petId: vaccine.petId,
        name: vaccine.name,
        dateGiven: calendarDate(colomboToday()),
        batch: vaccine.batch,
        vet: vaccine.vet,
        clinic: vaccine.clinic,
        notes: vaccine.notes,
      ),
    );
  }

  void _certificate() {
    final s = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.certificate),
        content: Text('${s.certificatePending}\n\n${s.certificateNote}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final matches = model.pets.where((pet) => pet.id == widget.petId);
        if (matches.isEmpty) return const Scaffold();
        final pet = matches.first;
        final vaccines = model.forPet(pet.id);
        final done = vaccines.where((v) => v.nextDue == null).toList()
          ..sort((a, b) => (b.dateGiven ?? '').compareTo(a.dateGiven ?? ''));
        final pending = vaccines.where((v) => v.nextDue != null).toList()
          ..sort((a, b) => a.nextDue!.compareTo(b.nextDue!));
        final ordered = [...done.take(1), ...pending, ...done.skip(1)];
        final visible = _showAll ? ordered : ordered.take(3).toList();
        final recorded = vaccines.where((v) => v.dateGiven != null).length;
        return Scaffold(
          appBar: AppBar(
            title: Text(s.petPlanTitle(pet.name)),
            actions: [
              PopupMenuButton<String>(
                tooltip: s.settings,
                icon: const Icon(Icons.more_horiz),
                onSelected: (action) {
                  if (action == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => PetEditor(model: model, pet: pet),
                      ),
                    );
                  }
                  if (action == 'delete') _deletePet(pet);
                  if (action == 'pdf') _certificate();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: Text(s.editPet)),
                  PopupMenuItem(value: 'pdf', child: Text(s.certificate)),
                  PopupMenuItem(value: 'delete', child: Text(s.delete)),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: PawColors.iceDeep.withValues(alpha: .45),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 82,
                      height: 82,
                      child: PetPortrait(species: pet.species, radius: 100),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pet.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            petSubtitle(context, pet),
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LinearProgressIndicator(
                              minHeight: 9,
                              backgroundColor: const Color(0xFFC3E4ED),
                              value: vaccines.isEmpty
                                  ? 0
                                  : recorded / vaccines.length,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s.dosesRecorded(recorded, vaccines.length),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              IceNotice(text: model.isDemo ? s.draftReview : s.customPlanNote),
              const SizedBox(height: 12),
              if (vaccines.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.vaccines_outlined,
                          size: 42,
                          color: PawColors.petrol,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          s.emptyVaccines,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(s.emptyVaccinesBody, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              if (visible.isNotEmpty)
                Stack(
                  children: [
                    Positioned(
                      left: 31,
                      top: 34,
                      bottom: 40,
                      child: Container(width: 3, color: PawColors.line),
                    ),
                    Column(
                      children: [
                        for (final vaccine in visible)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _TimelineCard(
                              vaccine: vaccine,
                              busy: model.busy,
                              onGiven: () => _recordGiven(vaccine),
                              onEdit: () => _edit(vaccine),
                              onDelete: () => _deleteVaccine(vaccine),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              if (ordered.length > 3)
                TextButton(
                  onPressed: () => setState(() {
                    _showAll = !_showAll;
                  }),
                  child: Text(
                    _showAll ? s.showFewer : s.showAllDoses(ordered.length),
                  ),
                ),
              const SizedBox(height: 2),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: model.busy ? null : () => _edit(null),
                  style: FilledButton.styleFrom(
                    backgroundColor: PawColors.iceDeep,
                    foregroundColor: PawColors.petrolDark,
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(s.addVaccine),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                s.disclaimer,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (model.isDemo)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    s.demoNotice,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              if (model.reminderFailed)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: IceNotice(text: s.reminderError),
                ),
            ],
          ),
        );
      },
    );
  }
}

(Color, IconData) statusVisual(VaccineStatus status) => switch (status) {
  VaccineStatus.done => (PawColors.green, Icons.check_rounded),
  VaccineStatus.dueSoon => (PawColors.orange, Icons.schedule),
  VaccineStatus.overdue => (
    const Color(0xFFCE4343),
    Icons.priority_high_rounded,
  ),
  VaccineStatus.upcoming => (
    const Color(0xFF78828D),
    Icons.calendar_today_outlined,
  ),
};

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.vaccine,
    required this.busy,
    required this.onGiven,
    required this.onEdit,
    required this.onDelete,
  });
  final Vaccine vaccine;
  final bool busy;
  final VoidCallback onGiven, onEdit, onDelete;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final status = vaccine.status();
    final (color, icon) = statusVisual(status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 3),
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, size: 23, color: Colors.white),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          vaccine.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          iconSize: 18,
                          enabled: !busy,
                          tooltip: s.editVaccine,
                          icon: const Icon(
                            Icons.more_horiz,
                            color: PawColors.muted,
                          ),
                          onSelected: (value) {
                            if (value == 'edit') {
                              onEdit();
                            } else {
                              onDelete();
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(s.editVaccine),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(s.delete),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  StatusBadge(status: status),
                  const SizedBox(height: 6),
                  Text(
                    vaccine.nextDue != null
                        ? displayDate(context, vaccine.nextDue!)
                        : s.recordedOn(
                            displayDate(context, vaccine.dateGiven!),
                          ),
                    style: const TextStyle(
                      color: PawColors.muted,
                      fontSize: 15,
                    ),
                  ),
                  if (status == VaccineStatus.dueSoon ||
                      status == VaccineStatus.overdue) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: busy ? null : onGiven,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          textStyle: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        child: Text(s.markAsGiven),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.plain = false});
  final VaccineStatus status;
  final bool plain;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final label = switch (status) {
      VaccineStatus.done => s.done,
      VaccineStatus.dueSoon => s.dueSoon,
      VaccineStatus.overdue => s.overdue,
      VaccineStatus.upcoming => s.upcoming,
    };
    final (color, icon) = statusVisual(status);
    return Container(
      padding: plain
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      decoration: plain
          ? null
          : BoxDecoration(
              color: color.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(20),
            ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (plain) ...[
            Icon(icon, size: 19, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: plain ? 11 : 12,
              fontWeight: plain ? FontWeight.w500 : FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
