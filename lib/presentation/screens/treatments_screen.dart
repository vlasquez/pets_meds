import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pet.dart';
import '../../domain/entities/treatment.dart';
import '../../utils/strings.dart';
import '../blocs/treatments/treatments_bloc.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/pet_avatar.dart';
import 'treatment_form_screen.dart';

/// Treatments tab: treatments grouped per pet in expandable cards.
/// Each treatment expands again into its dates and doses. Within a
/// pet, treatments go from oldest to latest (by start date).
/// Expects a [TreatmentsBloc] to be provided above it.
class TreatmentsScreen extends StatelessWidget {
  const TreatmentsScreen({super.key});

  void _openForm(BuildContext context,
      {Treatment? treatment, Pet? initialPet}) {
    final s = S.of(context);
    final bloc = context.read<TreatmentsBloc>();
    final pets = bloc.state.pets;
    if (pets.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.addPetFirst)));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TreatmentFormScreen(
          pets: pets,
          initialPet: initialPet,
          treatment: treatment,
          onSave: (t, pet) => bloc.add(TreatmentSaved(
            treatment: t,
            notificationTitle: s.reminderTitle(pet.name),
            notificationBody: s.reminderBody(
                t.medicationName, s.formatDose(t.doseAmount, t.doseUnit)),
          )),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, TreatmentEntry entry) async {
    final s = S.of(context);
    final bloc = context.read<TreatmentsBloc>();
    final confirmed = await showConfirmDialog(
      context,
      title: s.deleteTreatment,
      content: s.deleteTreatmentConfirm,
    );
    if (confirmed) bloc.add(TreatmentDeleted(entry.treatment));
  }

  /// Groups entries per pet; treatments sorted oldest → latest.
  List<(Pet, List<TreatmentEntry>)> _groupByPet(TreatmentsState state) {
    final byPetId = <int, List<TreatmentEntry>>{};
    for (final e in state.entries) {
      byPetId.putIfAbsent(e.pet.id!, () => []).add(e);
    }
    final groups = <(Pet, List<TreatmentEntry>)>[];
    for (final pet in state.pets) {
      final entries = byPetId[pet.id];
      if (entries == null || entries.isEmpty) continue;
      entries.sort(
          (a, b) => a.treatment.startDate.compareTo(b.treatment.startDate));
      groups.add((pet, entries));
    }
    return groups;
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
              final groups = _groupByPet(state);
              if (groups.isEmpty) {
                return EmptyState(message: s.noTreatments);
              }
              return ListView(
                padding: const EdgeInsets.only(bottom: 88),
                children: [
                  for (final (pet, entries) in groups)
                    Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      clipBehavior: Clip.antiAlias,
                      child: ExpansionTile(
                        leading: PetAvatar(pet: pet),
                        initiallyExpanded: true,
                        title: Text(pet.name),
                        subtitle: Text(s.nTreatments(entries.length)),
                        children: [
                          for (final e in entries)
                            _TreatmentTile(
                              entry: e,
                              onEdit: () => _openForm(context,
                                  treatment: e.treatment, initialPet: e.pet),
                              onDelete: () => _delete(context, e),
                            ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                ],
              );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'treatments_fab', // Unique within the IndexedStack.
        tooltip: s.addTreatment,
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// One treatment inside a pet's group: expands into dates and doses.
class _TreatmentTile extends StatelessWidget {
  final TreatmentEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TreatmentTile({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _detailRow(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final t = entry.treatment;
    final remaining = s.remainingDaysLabel(t.remainingDays(DateTime.now()));
    return ExpansionTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: t.active
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.medication, size: 18),
      ),
      title: Text(
          '${t.medicationName} · ${s.formatDose(t.doseAmount, t.doseUnit)}'),
      subtitle: Text(s.frequencyLabel(t)),
      childrenPadding: const EdgeInsets.fromLTRB(24, 0, 16, 8),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(context, Icons.repeat, s.scheduleLabel(context, t)),
              _detailRow(context, Icons.calendar_today,
                  '${s.startDate}: ${_fmtDate(t.startDate)}'),
              _detailRow(
                  context,
                  Icons.event_busy,
                  t.endDate == null
                      ? remaining
                      : '${_fmtDate(t.endDate!)} · $remaining'),
              if (t.notes != null && t.notes!.isNotEmpty)
                _detailRow(context, Icons.notes, t.notes!),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.edit, size: 18),
              label: Text(s.editTreatment),
              onPressed: onEdit,
            ),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(s.deleteTreatment),
              onPressed: onDelete,
            ),
          ],
        ),
      ],
    );
  }
}
