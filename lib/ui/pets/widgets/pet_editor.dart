import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/models/records.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/widgets/date_field.dart';
import '../../core/widgets/pawshots_widgets.dart';
import '../view_models/workspace_view_model.dart';

class PetEditor extends StatefulWidget {
  const PetEditor({super.key, required this.model, this.pet});
  final WorkspaceViewModel model;
  final Pet? pet;
  @override
  State<PetEditor> createState() => _PetEditorState();
}

class _PetEditorState extends State<PetEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.pet?.name);
  late final _breed = TextEditingController(text: widget.pet?.breed);
  late final _chip = TextEditingController(text: widget.pet?.microchip);
  late String _species = widget.pet?.species ?? 'dog';
  late String? _birthDate = widget.pet?.birthDate;
  bool _saving = false;
  bool _dateMissing = false;
  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    _chip.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _dateMissing = _birthDate == null;
    });
    if (!_form.currentState!.validate() || _dateMissing) return;
    final s = AppLocalizations.of(context)!;
    setState(() {
      _saving = true;
    });
    final pet = Pet(
      id: widget.pet?.id ?? const Uuid().v4(),
      name: _name.text.trim(),
      species: _species,
      birthDate: _birthDate!,
      breed: _breed.text.trim(),
      microchip: _chip.text.trim(),
    );
    final success = await widget.model.change(
      () => widget.model.repository.savePet(pet, isNew: widget.pet == null),
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
      appBar: AppBar(title: Text(widget.pet == null ? s.addPet : s.editPet)),
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
                    icon: Icons.pets,
                    title: s.petDetails,
                    subtitle: s.petDetailsHint,
                  ),
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(labelText: s.name),
                    maxLength: 100,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? s.requiredField : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _species,
                    decoration: InputDecoration(labelText: s.species),
                    items: [
                      DropdownMenuItem(value: 'dog', child: Text(s.dog)),
                      DropdownMenuItem(value: 'cat', child: Text(s.cat)),
                    ],
                    onChanged: (v) => setState(() {
                      _species = v!;
                    }),
                  ),
                  const SizedBox(height: 20),
                  DateField(
                    label: s.birthDate,
                    value: _birthDate,
                    allowFuture: false,
                    clearable: false,
                    onChanged: (v) => setState(() {
                      _birthDate = v;
                      _dateMissing = false;
                    }),
                  ),
                  if (_dateMissing)
                    Text(
                      s.requiredField,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _breed,
                    decoration: InputDecoration(labelText: s.breed),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _chip,
                    decoration: InputDecoration(labelText: s.microchip),
                  ),
                  const SizedBox(height: 28),
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
