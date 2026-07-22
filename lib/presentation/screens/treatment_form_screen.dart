import 'package:flutter/material.dart';

import '../../domain/entities/dose_unit.dart';
import '../../domain/entities/medication.dart';
import '../../domain/entities/pet.dart';
import '../../domain/entities/schedule_time.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/usecases/get_medications.dart';
import '../../injection.dart';
import '../../utils/strings.dart';
import '../../utils/time_format.dart';
import '../widgets/pet_avatar.dart';
import 'frequency_screen.dart';
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

  /// Selected pets. Creating supports several (one treatment per pet);
  /// editing is single-select (a treatment belongs to one pet).
  final Set<int> _selectedPetIds = {};
  int? _medicationId;
  List<Medication> _medications = [];
  bool _loadingMedications = true;

  DoseUnit _doseUnit = DoseUnit.pill;
  FrequencyConfig _frequency = const FrequencyConfig(type: FrequencyType.daily);
  List<ScheduleTime> _times = [const ScheduleTime(8, 0)];
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final t = widget.treatment;
    final initialPetId = t?.petId ?? widget.initialPet?.id;
    if (initialPetId != null) _selectedPetIds.add(initialPetId);
    _medicationId = t?.medicationId;
    _amountCtrl = TextEditingController(
        text: t == null
            ? '1'
            : (t.doseAmount == t.doseAmount.roundToDouble()
                ? t.doseAmount.toInt().toString()
                : t.doseAmount.toString()));
    _doseUnit = t?.doseUnit ?? DoseUnit.pill;
    _notesCtrl = TextEditingController(text: t?.notes ?? '');
    if (t != null) {
      _frequency = FrequencyConfig(
        type: t.frequencyType,
        intervalValue: t.intervalValue,
        intervalUnit: t.intervalUnit,
        weekdays: t.weekdays,
        cycleDaysOn: t.cycleDaysOn,
        cycleDaysOff: t.cycleDaysOff,
      );
      _times = List.of(t.times);
      if (_times.isEmpty) _times = [const ScheduleTime(8, 0)];
      _startDate = t.startDate;
      _endDate = t.endDate;
      _active = t.active;
    }
    _loadMedications();
  }

  bool get _isHourlyInterval =>
      _frequency.type == FrequencyType.interval &&
      _frequency.intervalUnit == IntervalUnit.hours;

  /// Whether the schedule uses the times-of-day chips.
  bool get _usesTimes =>
      _frequency.type != FrequencyType.onDemand && !_isHourlyInterval;

  /// Whether multiple times per day make sense (daily/weekdays/cyclic).
  bool get _multipleTimes =>
      _frequency.type == FrequencyType.daily ||
      _frequency.type == FrequencyType.weekdays ||
      _frequency.type == FrequencyType.cyclic;

  String _frequencySummary(S s) {
    final t = Treatment(
      petId: 0,
      medicationId: 0,
      doseAmount: 1,
      doseUnit: _doseUnit,
      frequencyType: _frequency.type,
      times: const [],
      intervalValue: _frequency.intervalValue,
      intervalUnit: _frequency.intervalUnit,
      weekdays: _frequency.weekdays,
      cycleDaysOn: _frequency.cycleDaysOn,
      cycleDaysOff: _frequency.cycleDaysOff,
      startDate: _startDate,
    );
    return s.frequencyLabel(t);
  }

  Future<void> _openFrequencyScreen() async {
    final result = await Navigator.of(context).push<FrequencyConfig>(
      MaterialPageRoute(builder: (_) => FrequencyScreen(initial: _frequency)),
    );
    if (result != null && mounted) {
      setState(() => _frequency = result);
    }
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

  /// Edits the time at [index] (tap a chip to change it).
  Future<void> _editTime(int index) async {
    final current = _times[index];
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked != null) {
      setState(() {
        _times[index] = ScheduleTime(picked.hour, picked.minute);
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
        _medications = [
          ..._medications,
          created
        ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _medicationId = created.id;
      });
    }
  }

  void _save() {
    final s = S.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_usesTimes && _times.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.atLeastOneTime)));
      return;
    }

    final selectedPets =
        widget.pets.where((p) => _selectedPetIds.contains(p.id)).toList();
    if (selectedPets.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.selectAtLeastOnePet)));
      return;
    }
    Medication? medication;
    for (final m in _medications) {
      if (m.id == _medicationId) medication = m;
    }
    if (medication == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.selectMedication)));
      return;
    }

    // Times only where the schedule uses them; day/month intervals take
    // a single time of day; hourly intervals keep the first intake time
    // (the anchor from which the day's intake hours are generated).
    final List<ScheduleTime> times;
    if (_frequency.type == FrequencyType.onDemand) {
      times = const [];
    } else if (_isHourlyInterval || !_multipleTimes) {
      times = [_times.first];
    } else {
      times = _times;
    }

    // One treatment per selected pet. Editing is single-select, so the
    // existing treatment keeps its id (even if reassigned to another pet).
    for (final pet in selectedPets) {
      final treatment = Treatment(
        id: widget.treatment?.id,
        petId: pet.id!,
        medicationId: medication.id!,
        medicationName: medication.name,
        doseAmount: double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 1,
        doseUnit: _doseUnit,
        frequencyType: _frequency.type,
        times: times,
        intervalValue: _frequency.intervalValue,
        intervalUnit: _frequency.intervalUnit,
        weekdays: _frequency.weekdays,
        cycleDaysOn: _frequency.cycleDaysOn,
        cycleDaysOff: _frequency.cycleDaysOff,
        startDate: _startDate,
        endDate: _endDate,
        active: _active,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      widget.onSave(treatment, pet);
    }
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
            // Which pet(s) this treatment is for. Creating allows
            // several (one treatment per pet); editing is single-select.
            Text(s.petLabel, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in widget.pets)
                  FilterChip(
                    avatar: _selectedPetIds.contains(p.id)
                        ? null
                        : PetAvatar(pet: p, radius: 12),
                    label: Text(p.name),
                    selected: _selectedPetIds.contains(p.id),
                    onSelected: (sel) => setState(() {
                      if (widget.treatment != null) {
                        // Editing: a treatment belongs to one pet.
                        _selectedPetIds
                          ..clear()
                          ..add(p.id!);
                      } else if (sel) {
                        _selectedPetIds.add(p.id!);
                      } else {
                        _selectedPetIds.remove(p.id);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Which catalog medication, with a shortcut to create one.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _medicationId,
                    decoration: InputDecoration(labelText: s.medicationLabel),
                    hint: Text(_loadingMedications ? '…' : s.selectMedication),
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
                    decoration: InputDecoration(labelText: s.doseAmountLabel),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                      return (n == null || n <= 0) ? s.invalidNumber : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<DoseUnit>(
                    initialValue: _doseUnit,
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.repeat),
              title: Text(s.frequency),
              subtitle: Text(_frequencySummary(s)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _openFrequencyScreen,
            ),
            if (_isHourlyInterval)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text(s.firstIntakeTime),
                subtitle: Text(formatScheduleTime(context, _times.first)),
                onTap: () async {
                  final first = _times.first;
                  final picked = await showTimePicker(
                    context: context,
                    initialTime:
                        TimeOfDay(hour: first.hour, minute: first.minute),
                  );
                  if (picked != null) {
                    setState(() =>
                        _times = [ScheduleTime(picked.hour, picked.minute)]);
                  }
                },
              ),
            if (_usesTimes) ...[
              const SizedBox(height: 8),
              Text(s.timesOfDay, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _times.length; i++)
                    InputChip(
                      label: Text(formatScheduleTime(context, _times[i])),
                      // Tap to change the time; only offer delete when
                      // there is more than one.
                      onPressed: () => _editTime(i),
                      onDeleted: _times.length > 1
                          ? () => setState(() => _times.removeAt(i))
                          : null,
                    ),
                  if (_multipleTimes)
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 18),
                      label: Text(s.addTime),
                      onPressed: _addTime,
                    ),
                ],
              ),
            ],
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
