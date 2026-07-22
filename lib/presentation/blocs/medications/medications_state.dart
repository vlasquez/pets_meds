part of 'medications_bloc.dart';

enum MedicationsStatus { initial, loading, success, failure }

final class MedicationsState extends Equatable {
  final MedicationsStatus status;
  final List<Medication> medications;

  /// medicationId → number of treatments using it (for delete warnings).
  final Map<int, int> usageCounts;
  final String? error;

  const MedicationsState({
    this.status = MedicationsStatus.initial,
    this.medications = const [],
    this.usageCounts = const {},
    this.error,
  });

  int usageOf(int? medicationId) => usageCounts[medicationId] ?? 0;

  MedicationsState copyWith({
    MedicationsStatus? status,
    List<Medication>? medications,
    Map<int, int>? usageCounts,
    String? error,
  }) =>
      MedicationsState(
        status: status ?? this.status,
        medications: medications ?? this.medications,
        usageCounts: usageCounts ?? this.usageCounts,
        error: error,
      );

  @override
  List<Object?> get props => [status, medications, usageCounts, error];
}
