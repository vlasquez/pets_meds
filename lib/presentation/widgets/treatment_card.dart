import 'package:flutter/material.dart';

import '../../domain/entities/treatment.dart';
import '../../l10n/strings.dart';

/// Card showing a treatment with its schedule and an actions menu.
class TreatmentCard extends StatelessWidget {
  final Treatment treatment;
  final VoidCallback onMarkGiven;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TreatmentCard({
    super.key,
    required this.treatment,
    required this.onMarkGiven,
    required this.onEdit,
    required this.onDelete,
  });

  String _scheduleLabel(S s) {
    final times = treatment.times.map((t) => t.format()).join(', ');
    final freq = treatment.frequencyType == FrequencyType.daily
        ? s.everyDay
        : s.everyXDays(treatment.intervalDays);
    return '$freq · $times';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: treatment.active
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.medication),
        ),
        title: Text(
            '${treatment.medicationName} · ${s.formatDose(treatment.doseAmount, treatment.doseUnit)}'),
        subtitle: Text(
            '${_scheduleLabel(s)}\n${s.remainingDaysLabel(treatment.remainingDays(DateTime.now()))}'),
        isThreeLine: true,
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
                    title: Text(s.editTreatment))),
            PopupMenuItem(
                value: 'delete',
                child: ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: Text(s.deleteTreatment))),
          ],
        ),
        onTap: onMarkGiven,
      ),
    );
  }
}
