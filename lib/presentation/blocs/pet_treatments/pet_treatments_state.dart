part of 'pet_treatments_bloc.dart';

enum PetTreatmentsStatus { initial, loading, success, failure }

final class PetTreatmentsState extends Equatable {
  final PetTreatmentsStatus status;
  final List<Treatment> treatments;

  /// Incremented every time a dose is logged; [lastDosedName] holds the
  /// medication name so the UI can show a confirmation (via BlocListener).
  final int doseLogCount;
  final String? lastDosedName;

  final String? error;

  const PetTreatmentsState({
    this.status = PetTreatmentsStatus.initial,
    this.treatments = const [],
    this.doseLogCount = 0,
    this.lastDosedName,
    this.error,
  });

  PetTreatmentsState copyWith({
    PetTreatmentsStatus? status,
    List<Treatment>? treatments,
    int? doseLogCount,
    String? lastDosedName,
    String? error,
  }) =>
      PetTreatmentsState(
        status: status ?? this.status,
        treatments: treatments ?? this.treatments,
        doseLogCount: doseLogCount ?? this.doseLogCount,
        lastDosedName: lastDosedName ?? this.lastDosedName,
        error: error,
      );

  @override
  List<Object?> get props =>
      [status, treatments, doseLogCount, lastDosedName, error];
}
