import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/medication.dart';
import '../../domain/entities/pet.dart';
import '../../injection.dart';
import '../../l10n/strings.dart';
import '../blocs/medications/medications_bloc.dart';
import '../blocs/pets/pets_bloc.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/medication_card.dart';
import 'history_screen.dart';
import 'medication_form_screen.dart';
import 'pet_form_screen.dart';

class PetDetailScreen extends StatelessWidget {
  final Pet pet;
  const PetDetailScreen({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MedicationsBloc(
        pet: pet,
        getMedications: sl(),
        saveMedication: sl(),
        deleteMedication: sl(),
        logDose: sl(),
      )..add(const MedicationsRequested()),
      child: _PetDetailView(pet: pet),
    );
  }
}

class _PetDetailView extends StatelessWidget {
  final Pet pet;
  const _PetDetailView({required this.pet});

  void _markGiven(BuildContext context, Medication med) {
    final s = S.of(context);
    context.read<MedicationsBloc>().add(DoseMarkedGiven(
          medication: med,
          notificationTitle: s.reminderTitle(pet.name),
          notificationBody: s.reminderBody(med.name, med.dosage),
        ));
  }

  Future<void> _deleteMedication(BuildContext context, Medication med) async {
    final s = S.of(context);
    final bloc = context.read<MedicationsBloc>();
    final confirmed = await showConfirmDialog(
      context,
      title: s.deleteMedication,
      content: s.deleteMedicationConfirm,
    );
    if (confirmed) bloc.add(MedicationDeleted(med));
  }

  Future<void> _deletePet(BuildContext context) async {
    final s = S.of(context);
    final petsBloc = context.read<PetsBloc>();
    final navigator = Navigator.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: s.deletePet,
      content: s.deletePetConfirm,
    );
    if (confirmed) {
      petsBloc.add(PetDeleted(pet));
      navigator.pop();
    }
  }

  void _openMedicationForm(BuildContext context, {Medication? medication}) {
    final bloc = context.read<MedicationsBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: MedicationFormScreen(pet: pet, medication: medication),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(pet.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: s.history,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => HistoryScreen(pet: pet)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: s.editPet,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PetFormScreen(pet: pet)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: s.deletePet,
            onPressed: () => _deletePet(context),
          ),
        ],
      ),
      body: BlocConsumer<MedicationsBloc, MedicationsState>(
        listenWhen: (prev, curr) => curr.doseLogCount > prev.doseLogCount,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(s.doseGivenSnack(state.lastDosedMedName ?? ''))),
          );
        },
        builder: (context, state) {
          switch (state.status) {
            case MedicationsStatus.initial:
            case MedicationsStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case MedicationsStatus.failure:
              return EmptyState(message: state.error ?? 'Error');
            case MedicationsStatus.success:
              if (state.medications.isEmpty) {
                return EmptyState(message: s.noMedications);
              }
              return ListView.builder(
                itemCount: state.medications.length,
                itemBuilder: (context, i) {
                  final med = state.medications[i];
                  return MedicationCard(
                    medication: med,
                    onMarkGiven: () => _markGiven(context, med),
                    onEdit: () =>
                        _openMedicationForm(context, medication: med),
                    onDelete: () => _deleteMedication(context, med),
                  );
                },
              );
          }
        },
      ),
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton(
          tooltip: s.addMedication,
          onPressed: () => _openMedicationForm(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
