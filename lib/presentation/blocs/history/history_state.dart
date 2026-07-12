part of 'history_bloc.dart';

enum HistoryStatus { initial, loading, success, failure }

final class HistoryState extends Equatable {
  final HistoryStatus status;
  final List<DoseLog> logs;
  final Map<int, Treatment> treatmentsById;
  final String? error;

  const HistoryState({
    this.status = HistoryStatus.initial,
    this.logs = const [],
    this.treatmentsById = const {},
    this.error,
  });

  HistoryState copyWith({
    HistoryStatus? status,
    List<DoseLog>? logs,
    Map<int, Treatment>? treatmentsById,
    String? error,
  }) =>
      HistoryState(
        status: status ?? this.status,
        logs: logs ?? this.logs,
        treatmentsById: treatmentsById ?? this.treatmentsById,
        error: error,
      );

  @override
  List<Object?> get props => [status, logs, treatmentsById, error];
}
