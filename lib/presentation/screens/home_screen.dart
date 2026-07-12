import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../l10n/strings.dart';
import '../blocs/today/today_bloc.dart';
import '../blocs/treatments/treatments_bloc.dart';
import '../widgets/empty_state.dart';
import '../widgets/pet_avatar.dart';
import 'pet_detail_screen.dart';

/// Home tab: today's scheduled treatments, grouped by pet.
/// Expects a [TodayBloc] to be provided above it.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.today)),
      body: BlocListener<TodayBloc, TodayState>(
        listenWhen: (prev, curr) => curr.doseLogCount > prev.doseLogCount,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.doseGivenSnack(state.lastDosedName ?? ''))),
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
                if (state.entries.isEmpty) {
                  return EmptyState(message: s.noTreatmentsToday);
                }
                return ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    for (final entry in state.entries) ...[
                      _PetHeader(entry: entry),
                      for (final item in entry.items)
                        _TodayTreatmentTile(entry: entry, item: item),
                    ],
                  ],
                );
            }
          },
        ),
      ),
    );
  }
}

class _PetHeader extends StatelessWidget {
  final TodayEntry entry;
  const _PetHeader({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: InkWell(
        onTap: () => _openPetDetail(context, entry),
        child: Row(
          children: [
            PetAvatar(pet: entry.pet, radius: 16),
            const SizedBox(width: 8),
            Text(entry.pet.name,
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: item.completed
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.primaryContainer,
              child: const Icon(Icons.medication),
            ),
            title: Text(
                '${t.medicationName} · ${s.formatDose(t.doseAmount, t.doseUnit)}'),
            subtitle: Text(
                '${s.scheduleLabel(t)}\n${s.remainingDaysLabel(t.remainingDays(DateTime.now()))}'),
            isThreeLine: true,
            trailing: item.completed
                ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                : null,
            onTap: () => _openPetDetail(context, entry),
          ),
          // Daily progress: one check per intake + progress bar.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: item.progress,
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${item.givenCount}/${item.targetCount}',
                      style: theme.textTheme.labelLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (var i = 0; i < item.targetCount; i++)
                      _IntakeChip(
                        label: i < item.intakeTimes.length
                            ? item.intakeTimes[i].format()
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
          ),
        ],
      ),
    );
  }
}

/// One intake of the day: shows the intake hour and whether it was taken.
class _IntakeChip extends StatelessWidget {
  final String label;
  final bool taken;
  final VoidCallback onTap;

  const _IntakeChip({
    required this.label,
    required this.taken,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      selected: taken,
      showCheckmark: true,
      avatar: taken ? null : const Icon(Icons.schedule, size: 18),
      label: Text(label),
      selectedColor: theme.colorScheme.primaryContainer,
      onSelected: (_) => onTap(),
    );
  }
}

void _openPetDetail(BuildContext context, TodayEntry entry) {
  final todayBloc = context.read<TodayBloc>();
  final treatmentsBloc = context.read<TreatmentsBloc>();
  Navigator.of(context)
      .push(
    MaterialPageRoute(builder: (_) => PetDetailScreen(pet: entry.pet)),
  )
      .then((_) {
    todayBloc.add(const TodayRequested());
    treatmentsBloc.add(const TreatmentsRequested());
  });
}
