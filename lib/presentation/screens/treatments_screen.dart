import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/medication.dart';
import '../../domain/entities/pet.dart';
import '../../l10n/strings.dart';
import '../blocs/treatments/treatments_bloc.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/pet_avatar.dart';
import 'medication_form_screen.dart';

/// Treatments tab: all medications across pets. New medications are
/// assigned to a pet chosen from a picker.
/// Expects a [TreatmentsBloc] to be provided above it.
class TreatmentsScreen extends StatelessWidget {
  const TreatmentsScreen({super.key});

  void _openForm(BuildContext context, Pet pet, {Medication? medication}) {
    final s = S.of(context);
    final bloc = context.read<TreatmentsBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MedicationFormScreen(
          pet: pet,
          medication: medication,
          onSave: (med) => bloc.add(TreatmentSaved(
            medication: med,
            notificationTitle: s.reminderTitle(pet.name),
            notificationBody: s.reminderBody(
                med.name, s.formatDose(med.doseAmount, med.doseUnit)),
          )),
        ),
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final s = S.of(context);
    final state = context.read<TreatmentsBloc>().state;
    if (state.pets.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.addPetFirst)));
      return;
    }

    // Assign the medication to a pet.
    final pet = await showModalBottomSheet<Pet>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(s.selectPet,
                  style: Theme.of(sheetContext).textTheme.titleMedium),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final p in state.pets)
                    ListTile(
                      leading: PetAvatar(pet: p),
                      title: Text(p.name),
                      onTap: () => Navigator.of(sheetContext).pop(p),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (pet != null && context.mounted) {
      _openForm(context, pet);
    }
  }

  Future<void> _delete(BuildContext context, Treatment treatment) async {
    final s = S.of(context);
    final bloc = context.read<TreatmentsBloc>();
    final confirmed = await showConfirmDialog(
      context,
      title: s.deleteMedication,
      content: s.deleteMedicationConfirm,
    );
    if (confirmed) bloc.add(TreatmentDeleted(treatment.medication));
  }

  String _scheduleLabel(S s, Medication med) {
    final times = med.times.map((t) => t.format()).join(', ');
    final freq = med.frequencyType == FrequencyType.daily
        ? s.everyDay
        : s.everyXDays(med.intervalDays);
    return '$freq · $times';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.treatmentsTab)),
      body: BlocBuilder<TreatmentsBloc, TreatmentsState>(
        builder: (context, state) {
          switch (state.status) {
            case TreatmentsStatus.initial:
            case TreatmentsStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case TreatmentsStatus.failure:
              return EmptyState(message: state.error ?? 'Error');
            case TreatmentsStatus.success:
              if (state.treatments.isEmpty) {
                return EmptyState(message: s.noTreatments);
              }
              return ListView(
                padding: const EdgeInsets.only(bottom: 88),
                children: [
                  for (final t in state.treatments)
                    Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: PetAvatar(pet: t.pet),
                        title: Text(
                            '${t.medication.name} · ${s.formatDose(t.medication.doseAmount, t.medication.doseUnit)}'),
                        subtitle: Text(
                            '${t.pet.name} · ${_scheduleLabel(s, t.medication)}'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _openForm(context, t.pet,
                                    medication: t.medication);
                              case 'delete':
                                _delete(context, t);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                    leading: const Icon(Icons.edit),
                                    title: Text(s.editMedication))),
                            PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                    leading:
                                        const Icon(Icons.delete_outline),
                                    title: Text(s.deleteMedication))),
                          ],
                        ),
                        onTap: () => _openForm(context, t.pet,
                            medication: t.medication),
                      ),
                    ),
                ],
              );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'treatments_fab', // Unique within the IndexedStack.
        tooltip: s.addMedication,
        onPressed: () => _add(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
