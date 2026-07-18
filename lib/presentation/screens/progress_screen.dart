import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../l10n/strings.dart';
import '../blocs/progress/progress_bloc.dart';
import '../widgets/empty_state.dart';
import '../widgets/intake_chip.dart';
import '../widgets/pet_avatar.dart';

/// Progress tab: every treatment's dose history until today, day by
/// day, with retroactive check/uncheck.
/// Expects a [ProgressBloc] to be provided above it.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.progressTab)),
      body: BlocBuilder<ProgressBloc, ProgressState>(
        builder: (context, state) {
          switch (state.status) {
            case ProgressStatus.initial:
            case ProgressStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case ProgressStatus.failure:
              return EmptyState(message: state.error ?? 'Error');
            case ProgressStatus.success:
              if (state.entries.isEmpty) {
                return EmptyState(message: s.noTreatments);
              }
              return ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  for (final entry in state.entries)
                    _TreatmentProgressCard(entry: entry),
                ],
              );
          }
        },
      ),
    );
  }
}

class _TreatmentProgressCard extends StatelessWidget {
  final TreatmentProgress entry;
  const _TreatmentProgressCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final t = entry.treatment;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: PetAvatar(pet: entry.pet),
        title: Text(
            '${t.medicationName} · ${s.formatDose(t.doseAmount, t.doseUnit)}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${entry.pet.name} · ${s.frequencyLabel(t)}'),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: entry.progress,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${entry.givenTotal}/${entry.expectedTotal}',
                    style: theme.textTheme.labelMedium),
              ],
            ),
          ],
        ),
        children: [
          for (final day in entry.days) _DayRow(entry: entry, day: day),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final TreatmentProgress entry;
  final DayProgress day;
  const _DayRow({required this.entry, required this.day});

  String _dateLabel(S s, DateTime d) =>
      '${s.weekdayShort(d.weekday)} ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  void _check(BuildContext context) {
    final s = S.of(context);
    final t = entry.treatment;
    context.read<ProgressBloc>().add(ProgressDoseChecked(
          day: day,
          notificationTitle: s.reminderTitle(entry.pet.name),
          notificationBody: s.reminderBody(
              t.medicationName, s.formatDose(t.doseAmount, t.doseUnit)),
        ));
  }

  void _uncheck(BuildContext context) {
    if (day.logIds.isEmpty) return;
    context.read<ProgressBloc>().add(ProgressDoseUnchecked(day.logIds.last));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final intakes = day.treatment.intakeTimesPerDay;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 84,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_dateLabel(s, day.date),
                    style: theme.textTheme.labelLarge),
                Text('${day.given}/${day.expected}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: day.completed
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    )),
              ],
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (var i = 0; i < day.expected; i++)
                  IntakeChip(
                    label: i < intakes.length
                        ? intakes[i].format()
                        : '#${i + 1}',
                    taken: i < day.given,
                    onTap: i < day.given
                        ? () => _uncheck(context)
                        : () => _check(context),
                  ),
              ],
            ),
          ),
          if (day.completed)
            Icon(Icons.check_circle,
                size: 20, color: theme.colorScheme.primary),
        ],
      ),
    );
  }
}
