part of 'medications_bloc.dart';

sealed class MedicationsEvent extends Equatable {
  const MedicationsEvent();

  @override
  List<Object?> get props => [];
}

final class MedicationsRequested extends MedicationsEvent {
  const MedicationsRequested();
}

final class MedicationDeleted extends MedicationsEvent {
  final int medicationId;
  const MedicationDeleted(this.medicationId);

  @override
  List<Object?> get props => [medicationId];
}
