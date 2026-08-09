import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/medication.dart';
import '../../domain/entities/pet.dart';
import '../../domain/entities/treatment.dart';
import '../../utils/strings.dart';
import '../blocs/medications/medications_bloc.dart';
import '../blocs/treatments/treatments_bloc.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/pet_avatar.dart';
import 'medication_form_screen.dart';
import 'treatment_form_screen.dart';

/// Treatments tab with a Treatments / Medications toggle.
/// - Treatments: schedules grouped per pet.
/// - Medications: the medication catalog (add/edit/delete).
/// Expects a [TreatmentsBloc] and a [MedicationsBloc] above it.
class TreatmentsScreen extends StatefulWidget {
  const TreatmentsScreen({super.key});

  @override
  State<TreatmentsScreen> createState() => _TreatmentsScreenState();
}

class _TreatmentsScreenState extends State<TreatmentsScreen> {
  /// 0 = treatments, 1 = medications.
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final showTreatments = _segment == 0;
    return Scaffold(
      appBar: AppBar(
        title: SegmentedButton<int>(
          segments: [
            ButtonSegment(value: 0, label: Text(s.treatmentsTab)),
            ButtonSegment(value: 1, label: Text(s.medicationsTab)),
          ],
          selected: {_segment},
          showSelectedIcon: false,
          onSelectionChanged: (sel) => setState(() => _segment = sel.first),
        ),
        centerTitle: true,
      ),
      body: showTreatments
          ? const _TreatmentsView()
          : const _MedicationsView(),
      floatingActionButton: FloatingActionButton(
        heroTag: 'treatments_tab_fab',
        tooltip: showTreatments ? s.addTreatment : s.addMedication,
        onPressed: () => showTreatments
            ? _openTreatmentForm(context)
            : _openMedicationForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ── Treatments ──────────────────────────────────────────────────────

void _openTreatmentForm(BuildContext context,
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

class _TreatmentsView extends StatelessWidget {
  const _TreatmentsView();

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

  /// Pet subtitle: a status breakdown when any treatment is not active,
  /// otherwise just the total count.
  String _petSubtitle(S s, List<TreatmentEntry> entries) {
    final now = DateTime.now();
    var active = 0, inactive = 0, completed = 0;
    for (final e in entries) {
      switch (e.treatment.statusOn(now)) {
        case TreatmentStatus.active:
          active++;
        case TreatmentStatus.inactive:
          inactive++;
        case TreatmentStatus.completed:
          completed++;
      }
    }
    if (inactive == 0 && completed == 0) {
      return s.nTreatments(entries.length);
    }
    return s.treatmentCountsBreakdown(active, inactive, completed);
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
    return BlocBuilder<TreatmentsBloc, TreatmentsState>(
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
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    clipBehavior: Clip.antiAlias,
                    child: ExpansionTile(
                      leading: PetAvatar(pet: pet),
                      initiallyExpanded: true,
                      title: Text(pet.name),
                      subtitle: Text(_petSubtitle(s, entries)),
                      children: [
                        for (final e in entries)
                          _TreatmentTile(
                            entry: e,
                            onEdit: () => _openTreatmentForm(context,
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
    final status = t.statusOn(DateTime.now());
    return ExpansionTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: status == TreatmentStatus.active
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.medication, size: 18),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
                '${t.medicationName} · ${s.formatDose(t.doseAmount, t.doseUnit)}'),
          ),
          if (status != TreatmentStatus.active) ...[
            const SizedBox(width: 8),
            _StatusPill(status: status),
          ],
        ],
      ),
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
                      : '${s.endDateShort}: ${_fmtDate(t.endDate!)} · $remaining'),
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

/// Small coloured status label for inactive/completed treatments.
class _StatusPill extends StatelessWidget {
  final TreatmentStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final (bg, fg) = switch (status) {
      TreatmentStatus.completed => (
          theme.colorScheme.primaryContainer,
          theme.colorScheme.onPrimaryContainer,
        ),
      _ => (
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurfaceVariant,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        s.treatmentStatusName(status),
        style: theme.textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}

// ── Medications catalog ─────────────────────────────────────────────

Future<void> _openMedicationForm(BuildContext context,
    {Medication? medication}) async {
  final bloc = context.read<MedicationsBloc>();
  await Navigator.of(context).push<Medication>(
    MaterialPageRoute(
      builder: (_) => MedicationFormScreen(medication: medication),
    ),
  );
  bloc.add(const MedicationsRequested());
}

class _MedicationsView extends StatelessWidget {
  const _MedicationsView();

  Future<void> _delete(
      BuildContext context, Medication medication, int usage) async {
    final s = S.of(context);
    final bloc = context.read<MedicationsBloc>();
    final confirmed = await showConfirmDialog(
      context,
      title: s.deleteMedication,
      content: usage > 0
          ? s.deleteMedicationInUse(usage)
          : s.deleteMedicationConfirm,
    );
    if (confirmed) bloc.add(MedicationDeleted(medication.id!));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return BlocBuilder<MedicationsBloc, MedicationsState>(
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
            return ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                for (final m in state.medications)
                  _MedicationTile(
                    medication: m,
                    usage: state.usageOf(m.id),
                    onEdit: () => _openMedicationForm(context, medication: m),
                    onDelete: () => _delete(context, m, state.usageOf(m.id)),
                  ),
              ],
            );
        }
      },
    );
  }
}

class _MedicationTile extends StatelessWidget {
  final Medication medication;
  final int usage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedicationTile({
    required this.medication,
    required this.usage,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final subtitleParts = [
      if (usage > 0) s.nTreatmentsUsing(usage),
      if (medication.notes != null && medication.notes!.isNotEmpty)
        medication.notes!,
    ];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: const Icon(Icons.medication),
        ),
        title: Text(medication.name),
        subtitle:
            subtitleParts.isEmpty ? null : Text(subtitleParts.join(' · ')),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
              case 'delete':
                onDelete();
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
                    leading: const Icon(Icons.delete_outline),
                    title: Text(s.deleteMedication))),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}
