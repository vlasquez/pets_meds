part of 'pet_treatments_bloc.dart';

sealed class PetTreatmentsEvent extends Equatable {
  const PetTreatmentsEvent();

  @override
  List<Object?> get props => [];
}

final class PetTreatmentsRequested extends PetTreatmentsEvent {
  const PetTreatmentsRequested();
}

/// Insert (id == null) or update a treatment and (re)schedule its reminders.
/// [notificationTitle] and [notificationBody] are localized by the UI.
final class PetTreatmentSaved extends PetTreatmentsEvent {
  final Treatment treatment;
  final String notificationTitle;
  final String notificationBody;

  const PetTreatmentSaved({
    required this.treatment,
    required this.notificationTitle,
    required this.notificationBody,
  });

  @override
  List<Object?> get props => [treatment, notificationTitle, notificationBody];
}

final class PetTreatmentDeleted extends PetTreatmentsEvent {
  final Treatment treatment;
  const PetTreatmentDeleted(this.treatment);

  @override
  List<Object?> get props => [treatment];
}

/// Logs a dose as given now; reschedules interval-based reminders.
final class DoseMarkedGiven extends PetTreatmentsEvent {
  final Treatment treatment;
  final String notificationTitle;
  final String notificationBody;

  const DoseMarkedGiven({
    required this.treatment,
    required this.notificationTitle,
    required this.notificationBody,
  });

  @override
  List<Object?> get props => [treatment, notificationTitle, notificationBody];
}
