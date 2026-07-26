import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../utils/strings.dart';
import '../../utils/time_format.dart';
import '../blocs/pets/pets_bloc.dart';
import '../blocs/today/today_bloc.dart';
import '../blocs/treatments/treatments_bloc.dart';
import '../widgets/empty_state.dart';
import '../widgets/gender_icon.dart';
import '../widgets/intake_chip.dart';
import '../widgets/pet_avatar.dart';
import 'pet_detail_screen.dart';
import 'treatment_form_screen.dart';

/// Home tab: today's agenda — the pets that have doses due today, each a
/// collapsible card of today's treatments. Manage the full roster in the
/// Pets tab. Expects [TodayBloc], [TreatmentsBloc] and [PetsBloc] above it.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _addTreatment(BuildContext context) async {
    final s = S.of(context);
    final todayBloc = context.read<TodayBloc>();
    final treatmentsBloc = context.read<TreatmentsBloc>();
    final pets = context.read<PetsBloc>().state.pets;
    if (pets.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.addPetFirst)));
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TreatmentFormScreen(
          pets: pets,
          onSave: (t, pet) => treatmentsBloc.add(TreatmentSaved(
            treatment: t,
            notificationTitle: s.reminderTitle(pet.name),
            notificationBody: s.reminderBody(
                t.medicationName, s.formatDose(t.doseAmount, t.doseUnit)),
          )),
        ),
      ),
    );
    todayBloc.add(const TodayRequested());
    treatmentsBloc.add(const TreatmentsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.today)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_fab',
        tooltip: s.addTreatment,
        onPressed: () => _addTreatment(context),
        child: const Icon(Icons.add),
      ),
      body: BlocListener<TodayBloc, TodayState>(
        listenWhen: (prev, curr) => curr.doseLogCount > prev.doseLogCount,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(s.doseGivenSnack(state.lastDosedName ?? ''))),
          );
        },
        child: BlocBuilder<TodayBloc, TodayState>(
          builder: (context, state) {
            switch (state.status) {
              case TodayStatus.initial:
              case TodayStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case TodayStatus.failure:
                return EmptyState(message: state.error ?? 'Error');
              case TodayStatus.success:
                // Agenda shows only pets that have doses due today.
                final due =
                    state.entries.where((e) => e.items.isNotEmpty).toList();
                if (due.isEmpty) {
                  return EmptyState(message: s.noTreatmentsToday);
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 88),
                  children: [
                    for (final entry in due) _PetCard(entry: entry),
                  ],
                );
            }
          },
        ),
      ),
    );
  }
}

/// Collapsible card for one pet with its today's treatments.
class _PetCard extends StatefulWidget {
  final TodayEntry entry;
  const _PetCard({required this.entry});

  @override
  State<_PetCard> createState() => _PetCardState();
}

class _PetCardState extends State<_PetCard> {
  /// Pets with treatments today start expanded; pets with none collapsed.
  late bool _expanded = widget.entry.items.isNotEmpty;

  void _openDetail(BuildContext context) {
    final todayBloc = context.read<TodayBloc>();
    final treatmentsBloc = context.read<TreatmentsBloc>();
    Navigator.of(context)
        .push(
      MaterialPageRoute(
          builder: (_) => PetDetailScreen(pet: widget.entry.pet)),
    )
        .then((_) {
      todayBloc.add(const TodayRequested());
      treatmentsBloc.add(const TreatmentsRequested());
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final entry = widget.entry;
    final age = entry.pet.ageAt(DateTime.now());
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: PetAvatar(pet: entry.pet),
            // Tap the name (or avatar) to open the pet's detail screen.
            title: InkWell(
              onTap: () => _openDetail(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(entry.pet.name,
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (entry.pet.gender != null) ...[
                    const SizedBox(width: 6),
                    GenderIcon(gender: entry.pet.gender),
                  ],
                ],
              ),
            ),
            subtitle: age == null ? null : Text(s.age(age.$1, age.$2)),
            trailing: IconButton(
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: !_expanded
                ? const SizedBox(width: double.infinity)
                : Column(
                    children: [
                      if (entry.items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(s.noActiveTreatmentsForPet,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant)),
                          ),
                        )
                      else
                        for (final item in entry.items)
                          _TodayTreatmentTile(entry: entry, item: item),
                      const SizedBox(height: 8),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _TodayTreatmentTile extends StatelessWidget {
  final TodayEntry entry;
  final TodayItem item;
  const _TodayTreatmentTile({required this.entry, required this.item});

  void _markGiven(BuildContext context) {
    final s = S.of(context);
    final t = item.treatment;
    context.read<TodayBloc>().add(TodayDoseGiven(
          treatment: t,
          notificationTitle: s.reminderTitle(entry.pet.name),
          notificationBody: s.reminderBody(
              t.medicationName, s.formatDose(t.doseAmount, t.doseUnit)),
        ));
  }

  void _unmarkLatest(BuildContext context) {
    if (item.todayLogIds.isEmpty) return;
    context.read<TodayBloc>().add(TodayDoseUnmarked(item.todayLogIds.last));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final t = item.treatment;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                item.completed
                    ? Icons.check_circle
                    : Icons.medication_outlined,
                color: item.completed
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${t.medicationName} · ${s.formatDose(t.doseAmount, t.doseUnit)}',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              Text('${item.givenCount}/${item.targetCount}',
                  style: theme.textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: item.progress, minHeight: 6),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (var i = 0; i < item.targetCount; i++)
                IntakeChip(
                  label: i < item.intakeTimes.length
                      ? formatScheduleTime(context, item.intakeTimes[i])
                      : '#${i + 1}',
                  taken: i < item.givenCount,
                  onTap: i < item.givenCount
                      ? () => _unmarkLatest(context)
                      : () => _markGiven(context),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
