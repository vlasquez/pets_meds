import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/medication.dart';
import '../../domain/entities/pet.dart';
import '../../domain/entities/vaccination.dart';
import '../../injection.dart';
import '../../l10n/strings.dart';
import '../blocs/medications/medications_bloc.dart';
import '../blocs/pets/pets_bloc.dart';
import '../blocs/vaccinations/vaccinations_bloc.dart';
import '../blocs/weight/weight_bloc.dart';
import '../widgets/add_vaccination_dialog.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/log_weight_dialog.dart';
import '../widgets/medication_card.dart';
import '../widgets/pet_avatar.dart';
import '../widgets/weight_chart.dart';
import 'history_screen.dart';
import 'medication_form_screen.dart';
import 'pet_form_screen.dart';
import 'weight_history_screen.dart';

class PetDetailScreen extends StatelessWidget {
  final Pet pet;
  const PetDetailScreen({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => MedicationsBloc(
            pet: pet,
            getMedications: sl(),
            saveMedication: sl(),
            deleteMedication: sl(),
            logDose: sl(),
          )..add(const MedicationsRequested()),
        ),
        BlocProvider(
          create: (_) => WeightBloc(
            pet: pet,
            getWeightHistory: sl(),
            logWeight: sl(),
            deleteWeightEntry: sl(),
          )..add(const WeightHistoryRequested()),
        ),
        BlocProvider(
          create: (_) => VaccinationsBloc(
            pet: pet,
            getVaccinations: sl(),
            saveVaccination: sl(),
            deleteVaccination: sl(),
          )..add(const VaccinationsRequested()),
        ),
      ],
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
          notificationBody: s.reminderBody(
              med.name, s.formatDose(med.doseAmount, med.doseUnit)),
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

  void _openWeightHistory(BuildContext context) {
    final bloc = context.read<WeightBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: WeightHistoryScreen(pet: pet),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    // Watch the pets list so edits (name, birth date, breed, photo…) made on
    // the form screen are reflected here immediately; the constructor's pet
    // would otherwise be stale until this screen is reopened.
    final currentPet = context.select<PetsBloc, Pet>((bloc) {
      for (final p in bloc.state.pets) {
        if (p.id == pet.id) return p;
      }
      return pet;
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(currentPet.name),
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
              MaterialPageRoute(
                  builder: (_) => PetFormScreen(pet: currentPet)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: s.deletePet,
            onPressed: () => _deletePet(context),
          ),
        ],
      ),
      body: BlocListener<MedicationsBloc, MedicationsState>(
        listenWhen: (prev, curr) => curr.doseLogCount > prev.doseLogCount,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(s.doseGivenSnack(state.lastDosedMedName ?? ''))),
          );
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 88),
          children: [
            _PetHeader(pet: currentPet),
            const Divider(height: 1),
            _WeightSection(onSeeHistory: _openWeightHistory),
            const Divider(height: 1),
            const _VaccinationsSection(),
            const Divider(height: 1),
            _MedicationsSection(
              onMarkGiven: _markGiven,
              onEdit: (ctx, med) =>
                  _openMedicationForm(ctx, medication: med),
              onDelete: _deleteMedication,
            ),
          ],
        ),
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

/// Header with photo and age.
class _PetHeader extends StatelessWidget {
  final Pet pet;
  const _PetHeader({required this.pet});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final age = pet.ageAt(DateTime.now());
    final breedName = s.breedName(pet.species, pet.breed);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          PetAvatar(pet: pet, radius: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pet.name,
                    style: Theme.of(context).textTheme.titleMedium),
                if (breedName != null)
                  Text(breedName,
                      style: Theme.of(context).textTheme.bodyMedium),
                if (age != null)
                  Text(s.age(age.$1, age.$2),
                      style: Theme.of(context).textTheme.bodyMedium),
                if (pet.notes != null && pet.notes!.isNotEmpty)
                  Text(pet.notes!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Weight section: latest value, chart, and a log-weight button.
class _WeightSection extends StatelessWidget {
  final void Function(BuildContext) onSeeHistory;
  const _WeightSection({required this.onSeeHistory});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: BlocBuilder<WeightBloc, WeightState>(
        builder: (context, state) {
          final latest = state.latest;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(s.weight,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  if (latest != null)
                    Text(
                      '${latest.weightKg} kg',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                              color: Theme.of(context).colorScheme.primary),
                    ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    tooltip: s.weightHistory,
                    onPressed: () => onSeeHistory(context),
                  ),
                ],
              ),
              if (state.entries.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 180,
                  child: WeightChart(entries: state.entries),
                ),
              ] else if (state.status == WeightStatus.success) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(s.noWeightEntries,
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.add),
                  label: Text(s.logWeight),
                  onPressed: () => showLogWeightDialog(context,
                      bloc: context.read<WeightBloc>()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Vaccinations section: registered vaccines with next-dose reminders.
class _VaccinationsSection extends StatelessWidget {
  const _VaccinationsSection();

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _delete(BuildContext context, Vaccination vaccination) async {
    final s = S.of(context);
    final bloc = context.read<VaccinationsBloc>();
    final confirmed = await showConfirmDialog(
      context,
      title: s.deleteVaccination,
      content: s.deleteVaccinationConfirm,
    );
    if (confirmed) bloc.add(VaccinationDeleted(vaccination));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: BlocBuilder<VaccinationsBloc, VaccinationsState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.vaccinations,
                  style: Theme.of(context).textTheme.titleMedium),
              if (state.vaccinations.isEmpty &&
                  state.status == VaccinationsStatus.success)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(s.noVaccinations,
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              for (final v in state.vaccinations)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.vaccines),
                  title: Text(v.vaccineType),
                  subtitle: Text([
                    _fmtDate(v.appliedAt),
                    if (v.hasReminder)
                      s.reminderEvery(v.reminderValue!, v.reminderUnit!),
                    if (v.nextDueDate != null)
                      s.nextDose(_fmtDate(v.nextDueDate!)),
                  ].join(' · ')),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: s.deleteVaccination,
                    onPressed: () => _delete(context, v),
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add),
                label: Text(s.addVaccination),
                onPressed: () => showAddVaccinationDialog(context,
                    bloc: context.read<VaccinationsBloc>()),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Medications section: title + cards (or empty message).
class _MedicationsSection extends StatelessWidget {
  final void Function(BuildContext, Medication) onMarkGiven;
  final void Function(BuildContext, Medication) onEdit;
  final void Function(BuildContext, Medication) onDelete;

  const _MedicationsSection({
    required this.onMarkGiven,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(s.medications,
              style: Theme.of(context).textTheme.titleMedium),
        ),
        BlocBuilder<MedicationsBloc, MedicationsState>(
          builder: (context, state) {
            switch (state.status) {
              case MedicationsStatus.initial:
              case MedicationsStatus.loading:
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              case MedicationsStatus.failure:
                return EmptyState(message: state.error ?? 'Error');
              case MedicationsStatus.success:
                if (state.medications.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Text(s.noMedications,
                        style: Theme.of(context).textTheme.bodyMedium),
                  );
                }
                return Column(
                  children: [
                    for (final med in state.medications)
                      MedicationCard(
                        medication: med,
                        onMarkGiven: () => onMarkGiven(context, med),
                        onEdit: () => onEdit(context, med),
                        onDelete: () => onDelete(context, med),
                      ),
                  ],
                );
            }
          },
        ),
      ],
    );
  }
}
