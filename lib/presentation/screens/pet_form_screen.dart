import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/datasources/local/photo_storage.dart';
import '../../domain/entities/pet.dart';
import '../../injection.dart';
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
  String? _photoPath;
  DateTime? _birthDate;
  bool _photoChanged = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.pet?.name ?? '');
    _notesCtrl = TextEditingController(text: widget.pet?.notes ?? '');
    _species = widget.pet?.species ?? 'dog';
    _photoPath = widget.pet?.photoPath;
    _birthDate = widget.pet?.birthDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final s = S.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(s.fromGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(s.fromCamera),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(s.removePhoto),
                onTap: () => Navigator.pop(ctx),
              ),
          ],
        ),
      ),
    );
    if (source == null) {
      // Bottom sheet dismissed or "remove photo" tapped.
      if (_photoPath != null && mounted) {
        setState(() {
          _photoPath = null;
          _photoChanged = true;
        });
      }
      return;
    }
    final picked = await ImagePicker()
        .pickImage(source: source, maxWidth: 1200, imageQuality: 85);
    if (picked != null && mounted) {
      setState(() {
        _photoPath = picked.path;
        _photoChanged = true;
      });
    }
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final bloc = context.read<PetsBloc>();
    final navigator = Navigator.of(context);

    // Persist a newly picked photo into app storage.
    var photoPath = _photoPath;
    if (_photoChanged && photoPath != null) {
      photoPath = await sl<PhotoStorage>().savePetPhoto(photoPath);
      await sl<PhotoStorage>().deletePhoto(widget.pet?.photoPath);
    } else if (_photoChanged && photoPath == null) {
      await sl<PhotoStorage>().deletePhoto(widget.pet?.photoPath);
    }

    final pet = Pet(
      id: widget.pet?.id,
      name: _nameCtrl.text.trim(),
      species: _species,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      photoPath: photoPath,
      birthDate: _birthDate,
    );
    bloc.add(PetSaved(pet));
    navigator.pop();
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: _photoPath != null &&
                              File(_photoPath!).existsSync()
                          ? FileImage(File(_photoPath!))
                          : null,
                      child: _photoPath == null
                          ? const Icon(Icons.pets, size: 40)
                          : null,
                    ),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: const Icon(Icons.photo_camera, size: 18),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cake),
              title: Text(s.birthDate),
              subtitle:
                  Text(_birthDate == null ? s.notSet : _fmtDate(_birthDate!)),
              trailing: _birthDate == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _birthDate = null),
                    ),
              onTap: _pickBirthDate,
            ),
            const SizedBox(height: 8),
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
