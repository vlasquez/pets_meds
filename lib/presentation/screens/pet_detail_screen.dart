import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pet.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/entities/vaccination.dart';
import '../../injection.dart';
import '../../l10n/strings.dart';
import '../blocs/pet_treatments/pet_treatments_bloc.dart';
import '../blocs/pets/pets_bloc.dart';
import '../blocs/vaccinations/vaccinations_bloc.dart';
import '../blocs/weight/weight_bloc.dart';
import '../widgets/add_vaccination_dialog.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/log_weight_dialog.dart';
import '../widgets/pet_avatar.dart';
import '../widgets/treatment_card.dart';
import '../widgets/weight_chart.dart';
import 'history_screen.dart';
import 'pet_form_screen.dart';
import 'treatment_form_screen.dart';
import 'weight_history_screen.dart';

class PetDetailScreen extends StatelessWidget {
  final Pet pet;
  const PetDetailScreen({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => PetTreatmentsBloc(
            pet: pet,
            getTreatments: sl(),
            saveTreatment: sl(),
            deleteTreatment: sl(),
            logDose: sl(),
          )..add(const PetTreatmentsRequested()),
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

  void _markGiven(BuildContext context, Treatment treatment) {
    final s = S.of(context);
    context.read<PetTreatmentsBloc>().add(DoseMarkedGiven(
          treatment: treatment,
          notificationTitle: s.reminderTitle(pet.name),
          notificationBody: s.reminderBody(treatment.medicationName,
              s.formatDose(treatment.doseAmount, treatment.doseUnit)),
        ));
  }

  Future<void> _deleteTreatment(
      BuildContext context, Treatment treatment) async {
    final s = S.of(context);
    final bloc = context.read<PetTreatmentsBloc>();
    final confirmed = await showConfirmDialog(
      context,
      title: s.deleteTreatment,
      content: s.deleteTreatmentConfirm,
    );
    if (confirmed) bloc.add(PetTreatmentDeleted(treatment));
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

  void _openTreatmentForm(BuildContext context,
      {Treatment? treatment, required Pet currentPet}) {
    final s = S.of(context);
    final bloc = context.read<PetTreatmentsBloc>();
    final pets = context.read<PetsBloc>().state.pets;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TreatmentFormScreen(
          pets: pets.isEmpty ? [currentPet] : pets,
          initialPet: currentPet,
          treatment: treatment,
          onSave: (t, forPet) => bloc.add(PetTreatmentSaved(
            treatment: t,
            notificationTitle: s.reminderTitle(forPet.name),
            notificationBody: s.reminderBody(t.medicationName,
                s.formatDose(t.doseAmount, t.doseUnit)),
          )),
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
      body: BlocListener<PetTreatmentsBloc, PetTreatmentsState>(
        listenWhen: (prev, curr) => curr.doseLogCount > prev.doseLogCount,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.doseGivenSnack(state.lastDosedName ?? ''))),
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
            _TreatmentsSection(
              onMarkGiven: _markGiven,
              onEdit: (ctx, t) => _openTreatmentForm(ctx,
                  treatment: t, currentPet: currentPet),
              onDelete: _deleteTreatment,
            ),
          ],
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton(
          heroTag: 'pet_detail_fab',
          tooltip: s.addTreatment,
          onPressed: () =>
              _openTreatmentForm(context, currentPet: currentPet),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

/// Header with photo, breed and age.
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

/// Treatments section: title + cards (or empty message).
class _TreatmentsSection extends StatelessWidget {
  final void Function(BuildContext, Treatment) onMarkGiven;
  final void Function(BuildContext, Treatment) onEdit;
  final void Function(BuildContext, Treatment) onDelete;

  const _TreatmentsSection({
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
          child: Text(s.treatmentsTab,
              style: Theme.of(context).textTheme.titleMedium),
        ),
        BlocBuilder<PetTreatmentsBloc, PetTreatmentsState>(
          builder: (context, state) {
            switch (state.status) {
              case PetTreatmentsStatus.initial:
              case PetTreatmentsStatus.loading:
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              case PetTreatmentsStatus.failure:
                return EmptyState(message: state.error ?? 'Error');
              case PetTreatmentsStatus.success:
                if (state.treatments.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Text(s.noTreatments,
                        style: Theme.of(context).textTheme.bodyMedium),
                  );
                }
                return Column(
                  children: [
                    for (final t in state.treatments)
                      TreatmentCard(
                        treatment: t,
                        onMarkGiven: () => onMarkGiven(context, t),
                        onEdit: () => onEdit(context, t),
                        onDelete: () => onDelete(context, t),
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
