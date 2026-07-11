part of 'history_bloc.dart';

enum HistoryStatus { initial, loading, success, failure }

final class HistoryState extends Equatable {
  final HistoryStatus status;
  final List<DoseLog> logs;
  final Map<int, Medication> medicationsById;
  final String? error;

  const HistoryState({
    this.status = HistoryStatus.initial,
    this.logs = const [],
    this.medicationsById = const {},
    this.error,
  });

  HistoryState copyWith({
    HistoryStatus? status,
    List<DoseLog>? logs,
    Map<int, Medication>? medicationsById,
    String? error,
  }) =>
      HistoryState(
        status: status ?? this.status,
        logs: logs ?? this.logs,
        medicationsById: medicationsById ?? this.medicationsById,
        error: error,
      );

  @override
  List<Object?> get props => [status, logs, medicationsById, error];
}
