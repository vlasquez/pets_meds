import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pet.dart';
import '../../injection.dart';
import '../../utils/strings.dart';
import '../blocs/history/history_bloc.dart';
import '../widgets/empty_state.dart';

class HistoryScreen extends StatelessWidget {
  final Pet pet;
  const HistoryScreen({super.key, required this.pet});

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return BlocProvider(
      create: (_) => HistoryBloc(
        pet: pet,
        getDoseHistory: sl(),
      )..add(const HistoryRequested()),
      child: Scaffold(
        appBar: AppBar(title: Text('${s.history} · ${pet.name}')),
        body: BlocBuilder<HistoryBloc, HistoryState>(
          builder: (context, state) {
            switch (state.status) {
              case HistoryStatus.initial:
              case HistoryStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case HistoryStatus.failure:
                return EmptyState(message: state.error ?? 'Error');
              case HistoryStatus.success:
                if (state.logs.isEmpty) {
                  return EmptyState(message: s.noHistory);
                }
                return ListView.builder(
                  itemCount: state.logs.length,
                  itemBuilder: (context, i) {
                    final log = state.logs[i];
                    final t = state.treatmentsById[log.treatmentId];
                    return ListTile(
                      leading:
                          const Icon(Icons.check_circle, color: Colors.green),
                      title: Text(t == null
                          ? '#${log.treatmentId}'
                          : '${t.medicationName} · ${s.formatDose(t.doseAmount, t.doseUnit)}'),
                      subtitle: Text(_fmt(log.givenAt)),
                    );
                  },
                );
            }
          },
        ),
      ),
    );
  }
}
