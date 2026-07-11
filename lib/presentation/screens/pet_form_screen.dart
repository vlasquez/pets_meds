import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pet.dart';
import '../../l10n/strings.dart';
import '../blocs/pets/pets_bloc.dart';

class PetFormScreen extends StatefulWidget {
  final Pet? pet;
  const PetFormScreen({super.key, this.pet});

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _notesCtrl;
  String _species = 'dog';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.pet?.name ?? '');
    _notesCtrl = TextEditingController(text: widget.pet?.notes ?? '');
    _species = widget.pet?.species ?? 'dog';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final pet = Pet(
      id: widget.pet?.id,
      name: _nameCtrl.text.trim(),
      species: _species,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    context.read<PetsBloc>().add(PetSaved(pet));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pet == null ? s.addPet : s.editPet),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: s.name),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? s.requiredField : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _species,
              decoration: InputDecoration(labelText: s.species),
              items: [
                DropdownMenuItem(value: 'dog', child: Text(s.dog)),
                DropdownMenuItem(value: 'cat', child: Text(s.cat)),
                DropdownMenuItem(value: 'other', child: Text(s.other)),
              ],
              onChanged: (v) => setState(() => _species = v ?? 'dog'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              decoration: InputDecoration(labelText: s.notes),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(s.save)),
          ],
        ),
      ),
    );
  }
}
