import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pet.dart';
import '../../domain/entities/weight_entry.dart';
import '../../l10n/strings.dart';
import '../blocs/weight/weight_bloc.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/log_weight_dialog.dart';
import '../widgets/weight_chart.dart';

/// Expects a [WeightBloc] to be provided above it (via BlocProvider.value).
class WeightHistoryScreen extends StatelessWidget {
  final Pet pet;
  const WeightHistoryScreen({super.key, required this.pet});

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _delete(BuildContext context, WeightEntry entry) async {
    final s = S.of(context);
    final bloc = context.read<WeightBloc>();
    final confirmed = await showConfirmDialog(
      context,
      title: s.deleteWeightEntry,
      content: s.deleteWeightEntryConfirm,
    );
    if (confirmed) bloc.add(WeightEntryDeleted(entry));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${s.weightHistory} · ${pet.name}')),
      body: BlocBuilder<WeightBloc, WeightState>(
        builder: (context, state) {
          switch (state.status) {
            case WeightStatus.initial:
            case WeightStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case WeightStatus.failure:
              return EmptyState(message: state.error ?? 'Error');
            case WeightStatus.success:
              if (state.entries.isEmpty) {
                return EmptyState(message: s.noWeightEntries);
              }
              return Column(
                children: [
                  if (state.entries.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 24, 8),
                      child: SizedBox(
                        height: 200,
                        child: WeightChart(entries: state.entries),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.entries.length,
                      itemBuilder: (context, i) {
                        final entry = state.entries[i];
                        return ListTile(
                          leading: const Icon(Icons.monitor_weight_outlined),
                          title: Text('${entry.weightKg} kg'),
                          subtitle: Text(_fmtDate(entry.measuredAt)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: s.deleteWeightEntry,
                            onPressed: () => _delete(context, entry),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
          }
        },
      ),
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton(
          tooltip: s.logWeight,
          onPressed: () => showLogWeightDialog(context,
              bloc: context.read<WeightBloc>()),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
