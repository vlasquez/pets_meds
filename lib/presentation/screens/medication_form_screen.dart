import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/medication.dart';
import '../../domain/entities/pet.dart';
import '../../domain/entities/schedule_time.dart';
import '../../l10n/strings.dart';
import '../blocs/medications/medications_bloc.dart';

/// Expects a [MedicationsBloc] to be provided above it (via BlocProvider.value).
class MedicationFormScreen extends StatefulWidget {
  final Pet pet;
  final Medication? medication;
  const MedicationFormScreen({super.key, required this.pet, this.medication});

  @override
  State<MedicationFormScreen> createState() => _MedicationFormScreenState();
}

class _MedicationFormScreenState extends State<MedicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _dosageCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _intervalCtrl;

  FrequencyType _frequencyType = FrequencyType.daily;
  List<ScheduleTime> _times = [const ScheduleTime(8, 0)];
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final med = widget.medication;
    _nameCtrl = TextEditingController(text: med?.name ?? '');
    _dosageCtrl = TextEditingController(text: med?.dosage ?? '');
    _notesCtrl = TextEditingController(text: med?.notes ?? '');
    _intervalCtrl =
        TextEditingController(text: (med?.intervalDays ?? 2).toString());
    if (med != null) {
      _frequencyType = med.frequencyType;
      _times = List.of(med.times);
      _startDate = med.startDate;
      _endDate = med.endDate;
      _active = med.active;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
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

  void _save() {
    final s = S.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_times.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.atLeastOneTime)));
      return;
    }

    // Interval mode uses a single time of day.
    final times = _frequencyType == FrequencyType.intervalDays
        ? [_times.first]
        : _times;

    final med = Medication(
      id: widget.medication?.id,
      petId: widget.pet.id!,
      name: _nameCtrl.text.trim(),
      dosage: _dosageCtrl.text.trim(),
      frequencyType: _frequencyType,
      times: times,
      intervalDays: int.tryParse(_intervalCtrl.text) ?? 1,
      startDate: _startDate,
      endDate: _endDate,
      active: _active,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    context.read<MedicationsBloc>().add(MedicationSaved(
          medication: med,
          notificationTitle: s.reminderTitle(widget.pet.name),
          notificationBody: s.reminderBody(med.name, med.dosage),
        ));

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.medication == null ? s.addMedication : s.editMedication),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: s.medicationName),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? s.requiredField : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dosageCtrl,
              decoration: InputDecoration(labelText: s.dosage),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? s.requiredField : null,
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
