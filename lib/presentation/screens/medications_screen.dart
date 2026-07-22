import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/medication.dart';
import '../../utils/strings.dart';
import '../blocs/medications/medications_bloc.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import 'medication_form_screen.dart';

/// Medications tab: the catalog of medications. Add, edit or delete
/// entries used to build treatments.
/// Expects a [MedicationsBloc] to be provided above it.
class MedicationsScreen extends StatelessWidget {
  const MedicationsScreen({super.key});

  Future<void> _openForm(BuildContext context, {Medication? medication}) async {
    final bloc = context.read<MedicationsBloc>();
    await Navigator.of(context).push<Medication>(
      MaterialPageRoute(
        builder: (_) => MedicationFormScreen(medication: medication),
      ),
    );
    // The form saves directly; reload to reflect any change.
    bloc.add(const MedicationsRequested());
  }

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
    return Scaffold(
      appBar: AppBar(title: Text(s.medicationsTab)),
      body: BlocBuilder<MedicationsBloc, MedicationsState>(
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
                      onEdit: () => _openForm(context, medication: m),
                      onDelete: () =>
                          _delete(context, m, state.usageOf(m.id)),
                    ),
                ],
              );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'medications_fab', // Unique within the IndexedStack.
        tooltip: s.addMedication,
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
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
        subtitle: subtitleParts.isEmpty ? null : Text(subtitleParts.join(' · ')),
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
