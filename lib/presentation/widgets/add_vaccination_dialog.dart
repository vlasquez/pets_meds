import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/vaccination.dart';
import '../../l10n/strings.dart';
import '../blocs/vaccinations/vaccinations_bloc.dart';

/// Dialog to register a vaccination: type, application date and an
/// optional revaccination reminder (every N weeks/months/years).
Future<void> showAddVaccinationDialog(BuildContext context,
    {required VaccinationsBloc bloc}) {
  return showDialog(
    context: context,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: const _AddVaccinationDialog(),
    ),
  );
}

class _AddVaccinationDialog extends StatefulWidget {
  const _AddVaccinationDialog();

  @override
  State<_AddVaccinationDialog> createState() => _AddVaccinationDialogState();
}

class _AddVaccinationDialogState extends State<_AddVaccinationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _typeCtrl = TextEditingController();
  final _reminderValueCtrl = TextEditingController(text: '1');

  DateTime _appliedAt = DateTime.now();
  bool _withReminder = true;
  ReminderUnit _reminderUnit = ReminderUnit.years;

  @override
  void dispose() {
    _typeCtrl.dispose();
    _reminderValueCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _appliedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _appliedAt = picked);
  }

  void _save() {
    final s = S.of(context);
    if (!_formKey.currentState!.validate()) return;

    final bloc = context.read<VaccinationsBloc>();
    final vaccination = Vaccination(
      petId: bloc.pet.id!,
      vaccineType: _typeCtrl.text.trim(),
      appliedAt: _appliedAt,
      reminderValue:
          _withReminder ? int.tryParse(_reminderValueCtrl.text) : null,
      reminderUnit: _withReminder ? _reminderUnit : null,
    );

    bloc.add(VaccinationSaved(
      vaccination: vaccination,
      notificationTitle: s.vaccineReminderTitle(bloc.pet.name),
      notificationBody: s.vaccineReminderBody(vaccination.vaccineType),
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final reminderValue = int.tryParse(_reminderValueCtrl.text) ?? 1;
    return AlertDialog(
      title: Text(s.addVaccination),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _typeCtrl,
                decoration: InputDecoration(labelText: s.vaccineType),
                autofocus: true,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? s.requiredField : null,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(s.vaccinationDate),
                subtitle: Text(_fmtDate(_appliedAt)),
                onTap: _pickDate,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.reminderLabel),
                subtitle: Text(_withReminder
                    ? s.reminderEvery(reminderValue, _reminderUnit)
                    : s.noReminder),
                value: _withReminder,
                onChanged: (v) => setState(() => _withReminder = v),
              ),
              if (_withReminder)
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _reminderValueCtrl,
                        decoration:
                            InputDecoration(labelText: s.doseAmountLabel),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (!_withReminder) return null;
                          final n = int.tryParse(v ?? '');
                          return (n == null || n < 1) ? s.invalidNumber : null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<ReminderUnit>(
                        value: _reminderUnit,
                        decoration:
                            InputDecoration(labelText: s.frequency),
                        items: [
                          for (final u in ReminderUnit.values)
                            DropdownMenuItem(
                              value: u,
                              child:
                                  Text(s.reminderUnitName(u, reminderValue)),
                            ),
                        ],
                        onChanged: (v) => setState(
                            () => _reminderUnit = v ?? ReminderUnit.years),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(s.save)),
      ],
    );
  }
}
