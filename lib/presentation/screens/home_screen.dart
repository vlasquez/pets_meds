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

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = item.treatment;
    final times = t.times.map((x) => x.format()).join(', ');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.givenToday
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : Theme.of(context).colorScheme.primaryContainer,
          child: const Icon(Icons.medication),
        ),
        title: Text(
            '${t.medicationName} · ${s.formatDose(t.doseAmount, t.doseUnit)}'),
        subtitle: Text(times),
        trailing: item.givenToday
            ? Icon(Icons.check_circle,
                color: Theme.of(context).colorScheme.primary)
            : IconButton(
                icon: const Icon(Icons.check_circle_outline),
                tooltip: s.markGiven,
                onPressed: () => _markGiven(context),
              ),
        onTap: () => _openPetDetail(context, entry),
      ),
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
