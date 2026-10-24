import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/models/records.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/widgets/date_field.dart';
import '../../core/widgets/pawshots_widgets.dart';
import '../../pets/view_models/workspace_view_model.dart';

class VaccineEditor extends StatefulWidget {
  const VaccineEditor({
    super.key,
    required this.model,
    required this.petId,
    this.vaccine,
  });
  final WorkspaceViewModel model;
  final String petId;
  final Vaccine? vaccine;
  @override
  State<VaccineEditor> createState() => _VaccineEditorState();
}

class _VaccineEditorState extends State<VaccineEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.vaccine?.name);
  late final _batch = TextEditingController(text: widget.vaccine?.batch);
  late final _vet = TextEditingController(text: widget.vaccine?.vet);
  late final _clinic = TextEditingController(text: widget.vaccine?.clinic);
  late final _notes = TextEditingController(text: widget.vaccine?.notes);
  late String? _given = widget.vaccine?.dateGiven;
  late String? _due = widget.vaccine?.nextDue;
  String? _error;
  bool _saving = false;
  @override
  void dispose() {
    for (final c in [_name, _batch, _vet, _clinic, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final s = AppLocalizations.of(context)!;
    if (!_form.currentState!.validate()) return;
    String? error;
    if (_given == null && _due == null) error = s.requiredDate;
    if (_given != null && _due != null && _due!.compareTo(_given!) < 0) {
      error = s.dateOrder;
    }
    if (_given != null && _given!.compareTo(calendarDate(colomboToday())) > 0) {
      error = s.futureGiven;
    }
    setState(() {
      _error = error;
    });
    if (error != null) return;
    setState(() {
      _saving = true;
    });
    final record = Vaccine(
      id: widget.vaccine?.id ?? const Uuid().v4(),
      petId: widget.petId,
      name: _name.text.trim(),
      dateGiven: _given,
      nextDue: _due,
      batch: _batch.text.trim(),
      vet: _vet.text.trim(),
      clinic: _clinic.text.trim(),
      notes: _notes.text.trim(),
    );
    final success = await widget.model.change(
      () => widget.model.repository.saveVaccine(
        record,
        isNew: widget.vaccine == null,
      ),
      s.notificationTitle,
      s.notificationChannel,
    );
    if (!mounted) return;
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
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vaccine == null ? s.addVaccine : s.editVaccine),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _form,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EditorHeader(
                    icon: Icons.vaccines_outlined,
                    title: s.vaccineDetails,
                    subtitle: s.vaccineDetailsHint,
                  ),
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(labelText: s.vaccineName),
                    maxLength: 160,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? s.requiredField : null,
                  ),
                  const SizedBox(height: 16),
                  DateField(
                    label: s.dateGiven,
                    value: _given,
                    allowFuture: false,
                    onChanged: (v) => setState(() {
                      _given = v;
                    }),
                  ),
                  const SizedBox(height: 20),
                  DateField(
                    label: s.nextDue,
                    value: _due,
                    onChanged: (v) => setState(() {
                      _due = v;
                    }),
                  ),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  const SizedBox(height: 20),
                  for (final field in [
                    (_batch, s.batch),
                    (_vet, s.vet),
                    (_clinic, s.clinic),
                    (_notes, s.notes),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: TextFormField(
                        controller: field.$1,
                        decoration: InputDecoration(labelText: field.$2),
                        maxLines: field.$1 == _notes ? 3 : 1,
                      ),
                    ),
                  Text(
                    s.disclaimer,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.check),
                    label: Text(s.save),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
