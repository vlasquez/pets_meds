import 'package:flutter/material.dart';

import '../../domain/entities/medication.dart';
import '../../l10n/strings.dart';

/// Card showing a medication with its schedule and an actions menu.
class MedicationCard extends StatelessWidget {
  final Medication medication;
  final VoidCallback onMarkGiven;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.onMarkGiven,
    required this.onEdit,
    required this.onDelete,
  });

  String _scheduleLabel(S s) {
    final times = medication.times.map((t) => t.format()).join(', ');
    final freq = medication.frequencyType == FrequencyType.daily
        ? s.everyDay
        : s.everyXDays(medication.intervalDays);
    return '$freq · $times';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: medication.active
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.medication),
        ),
        title: Text('${medication.name} · ${medication.dosage}'),
        subtitle: Text(_scheduleLabel(s)),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'given':
                onMarkGiven();
              case 'edit':
                onEdit();
              case 'delete':
                onDelete();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
                value: 'given',
                child: ListTile(
                    leading: const Icon(Icons.check_circle),
                    title: Text(s.markGiven))),
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
        onTap: onMarkGiven,
      ),
    );
  }
}
