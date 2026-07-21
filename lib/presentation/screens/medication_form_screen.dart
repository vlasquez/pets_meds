import 'package:flutter/material.dart';

import '../../domain/entities/medication.dart';
import '../../domain/usecases/save_medication.dart';
import '../../injection.dart';
import '../../utils/strings.dart';

/// Form to create (or edit) a catalog medication.
/// Pops with the saved [Medication] so callers (e.g. the treatment form)
/// can select it right away.
class MedicationFormScreen extends StatefulWidget {
  final Medication? medication;
  const MedicationFormScreen({super.key, this.medication});

  @override
  State<MedicationFormScreen> createState() => _MedicationFormScreenState();
}

class _MedicationFormScreenState extends State<MedicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _notesCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.medication?.name ?? '');
    _notesCtrl = TextEditingController(text: widget.medication?.notes ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final saved = await sl<SaveMedication>()(Medication(
      id: widget.medication?.id,
      name: _nameCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    ));
    navigator.pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.medication == null ? s.newMedication : s.editMedication),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: s.medicationName),
              autofocus: widget.medication == null,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? s.requiredField : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              decoration: InputDecoration(labelText: s.notes),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(s.save),
            ),
          ],
        ),
      ),
    );
  }
}
