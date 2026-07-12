part of 'treatments_bloc.dart';

sealed class TreatmentsEvent extends Equatable {
  const TreatmentsEvent();

  @override
  List<Object?> get props => [];
}

final class TreatmentsRequested extends TreatmentsEvent {
  const TreatmentsRequested();
}

/// Insert (id == null) or update a medication assigned to a pet,
/// (re)scheduling its reminders.
final class TreatmentSaved extends TreatmentsEvent {
  final Medication medication;
  final String notificationTitle;
  final String notificationBody;

  const TreatmentSaved({
    required this.medication,
    required this.notificationTitle,
    required this.notificationBody,
  });

  @override
  List<Object?> get props => [medication, notificationTitle, notificationBody];
}

final class TreatmentDeleted extends TreatmentsEvent {
  final Medication medication;
  const TreatmentDeleted(this.medication);

  @override
  List<Object?> get props => [medication];
}
