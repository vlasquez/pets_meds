part of 'medications_bloc.dart';

enum MedicationsStatus { initial, loading, success, failure }

final class MedicationsState extends Equatable {
  final MedicationsStatus status;
  final List<Medication> medications;

  /// Incremented every time a dose is logged; [lastDosedMedName] holds the
  /// medication name so the UI can show a confirmation (via BlocListener).
  final int doseLogCount;
  final String? lastDosedMedName;

  final String? error;

  const MedicationsState({
    this.status = MedicationsStatus.initial,
    this.medications = const [],
    this.doseLogCount = 0,
    this.lastDosedMedName,
    this.error,
  });

  MedicationsState copyWith({
    MedicationsStatus? status,
    List<Medication>? medications,
    int? doseLogCount,
    String? lastDosedMedName,
    String? error,
  }) =>
      MedicationsState(
        status: status ?? this.status,
        medications: medications ?? this.medications,
        doseLogCount: doseLogCount ?? this.doseLogCount,
        lastDosedMedName: lastDosedMedName ?? this.lastDosedMedName,
        error: error,
      );

  @override
  List<Object?> get props =>
      [status, medications, doseLogCount, lastDosedMedName, error];
}
