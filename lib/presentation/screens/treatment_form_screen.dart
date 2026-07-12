import 'package:flutter/material.dart';

import '../../domain/entities/dose_unit.dart';
import '../../domain/entities/medication.dart';
import '../../domain/entities/pet.dart';
import '../../domain/entities/schedule_time.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/usecases/get_medications.dart';
import '../../injection.dart';
import '../../l10n/strings.dart';
import 'medication_form_screen.dart';

/// Form to create/edit a treatment: pick the pet it belongs to, pick a
/// medication from the catalog (or create one on the spot), and set the
/// dose and schedule. Saving is delegated to [onSave] so both the pet
/// detail flow and the Treatments tab can dispatch to their own blocs.
class TreatmentFormScreen extends StatefulWidget {
  /// Pets available in the pet selector.
  final List<Pet> pets;

  /// Preselected pet (e.g. when opened from a pet's detail screen).
  final Pet? initialPet;

  /// Treatment being edited, or null to create a new one.
  final Treatment? treatment;

  final void Function(Treatment treatment, Pet pet) onSave;

  const TreatmentFormScreen({
    super.key,
    required this.pets,
    this.initialPet,
    this.treatment,
    required this.onSave,
  });

  @override
  State<TreatmentFormScreen> createState() => _TreatmentFormScreenState();
}

class _TreatmentFormScreenState extends State<TreatmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _intervalCtrl;

  int? _petId;
  int? _medicationId;
  List<Medication> _medications = [];
  bool _loadingMedications = true;

  DoseUnit _doseUnit = DoseUnit.pill;
  FrequencyType _frequencyType = FrequencyType.daily;
  List<ScheduleTime> _times = [const ScheduleTime(8, 0)];
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final t = widget.treatment;
    _petId = t?.petId ?? widget.initialPet?.id;
    _medicationId = t?.medicationId;
    _amountCtrl = TextEditingController(
        text: t == null
            ? '1'
            : (t.doseAmount == t.doseAmount.roundToDouble()
                ? t.doseAmount.toInt().toString()
                : t.doseAmount.toString()));
    _doseUnit = t?.doseUnit ?? DoseUnit.pill;
    _notesCtrl = TextEditingController(text: t?.notes ?? '');
    _intervalCtrl =
        TextEditingController(text: (t?.intervalDays ?? 2).toString());
    if (t != null) {
      _frequencyType = t.frequencyType;
      _times = List.of(t.times);
      _startDate = t.startDate;
      _endDate = t.endDate;
      _active = t.active;
    }
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    final meds = await sl<GetMedications>()();
    if (!mounted) return;
    setState(() {
      _medications = meds;
      _loadingMedications = false;
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    _intervalCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _times.add(ScheduleTime(picked.hour, picked.minute));
        _times.sort();
      });
    }
  }

  /// Create a medication in the catalog and select it right away.
  Future<void> _createMedication() async {
    final created = await Navigator.of(context).push<Medication>(
      MaterialPageRoute(builder: (_) => const MedicationFormScreen()),
    );
    if (created != null && mounted) {
      setState(() {
        _medications = [..._medications, created]
          ..sort((a, b) =>
              a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _medicationId = created.id;
      });
    }
  }

  void _save() {
    final s = S.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_times.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.atLeastOneTime)));
      return;
    }

    final pet = widget.pets.firstWhere((p) => p.id == _petId);
    Medication? medication;
    for (final m in _medications) {
      if (m.id == _medicationId) medication = m;
    }
    if (medication == null) return;

    // Interval mode uses a single time of day.
    final times = _frequencyType == FrequencyType.intervalDays
        ? [_times.first]
        : _times;

    final treatment = Treatment(
      id: widget.treatment?.id,
      petId: pet.id!,
      medicationId: medication.id!,
      medicationName: medication.name,
      doseAmount:
          double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 1,
      doseUnit: _doseUnit,
      frequencyType: _frequencyType,
      times: times,
      intervalDays: int.tryParse(_intervalCtrl.text) ?? 1,
      startDate: _startDate,
      endDate: _endDate,
      active: _active,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    widget.onSave(treatment, pet);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.treatment == null ? s.addTreatment : s.editTreatment),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Which pet this treatment is for.
            DropdownButtonFormField<int>(
              value: _petId,
              decoration: InputDecoration(labelText: s.petLabel),
              items: [
                for (final p in widget.pets)
                  DropdownMenuItem(value: p.id, child: Text(p.name)),
              ],
              validator: (v) => v == null ? s.requiredField : null,
              onChanged: (v) => setState(() => _petId = v),
            ),
            const SizedBox(height: 16),
            // Which catalog medication, with a shortcut to create one.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _medicationId,
                    decoration:
                        InputDecoration(labelText: s.medicationLabel),
                    hint: Text(_loadingMedications
                        ? '…'
                        : s.selectMedication),
                    items: [
                      for (final m in _medications)
                        DropdownMenuItem(value: m.id, child: Text(m.name)),
                    ],
                    validator: (v) => v == null ? s.requiredField : null,
                    onChanged: (v) => setState(() => _medicationId = v),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: IconButton.filledTonal(
                    icon: const Icon(Icons.add),
                    tooltip: s.newMedication,
                    onPressed: _createMedication,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _amountCtrl,
                    decoration:
                        InputDecoration(labelText: s.doseAmountLabel),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    validator: (v) {
                      final n =
                          double.tryParse((v ?? '').replaceAll(',', '.'));
                      return (n == null || n <= 0) ? s.invalidNumber : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<DoseUnit>(
                    value: _doseUnit,
                    decoration: InputDecoration(labelText: s.doseUnitLabel),
                    items: () {
                      final units = List.of(DoseUnit.values)
                        ..sort((a, b) => s
                            .doseUnitName(a, 1)
                            .toLowerCase()
                            .compareTo(s.doseUnitName(b, 1).toLowerCase()));
                      return [
                        for (final u in units)
                          DropdownMenuItem(
                              value: u, child: Text(s.doseUnitName(u, 1))),
                      ];
                    }(),
                    onChanged: (v) =>
                        setState(() => _doseUnit = v ?? DoseUnit.pill),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<FrequencyType>(
              value: _frequencyType,
              decoration: InputDecoration(labelText: s.frequency),
              items: [
                DropdownMenuItem(
                    value: FrequencyType.daily, child: Text(s.everyDay)),
                DropdownMenuItem(
                    value: FrequencyType.intervalDays,
                    child: Text(s.everyXDays(
                        int.tryParse(_intervalCtrl.text) ?? 2))),
              ],
              onChanged: (v) =>
                  setState(() => _frequencyType = v ?? FrequencyType.daily),
            ),
            if (_frequencyType == FrequencyType.intervalDays) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _intervalCtrl,
                decoration: InputDecoration(labelText: s.intervalDaysLabel),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return (n == null || n < 1) ? s.requiredField : null;
                },
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: 16),
            Text(s.timesOfDay,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _times.length; i++)
                  InputChip(
                    label: Text(_times[i].format()),
                    onDeleted: _times.length > 1
                        ? () => setState(() => _times.removeAt(i))
                        : null,
                  ),
                if (_frequencyType == FrequencyType.daily)
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: Text(s.addTime),
                    onPressed: _addTime,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(s.startDate),
              subtitle: Text(_fmtDate(_startDate)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_busy),
              title: Text(s.endDate),
              subtitle:
                  Text(_endDate == null ? s.noEndDate : _fmtDate(_endDate!)),
              trailing: _endDate == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _endDate = null),
                    ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? _startDate,
                  firstDate: _startDate,
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _endDate = picked);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.active),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
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
