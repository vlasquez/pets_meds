part of 'medications_bloc.dart';

sealed class MedicationsEvent extends Equatable {
  const MedicationsEvent();

  @override
  List<Object?> get props => [];
}

final class MedicationsRequested extends MedicationsEvent {
  const MedicationsRequested();
}

/// Insert (id == null) or update a medication and (re)schedule its reminders.
/// [notificationTitle] and [notificationBody] are localized by the UI.
final class MedicationSaved extends MedicationsEvent {
  final Medication medication;
  final String notificationTitle;
  final String notificationBody;

  const MedicationSaved({
    required this.medication,
    required this.notificationTitle,
    required this.notificationBody,
  });

  @override
  List<Object?> get props => [medication, notificationTitle, notificationBody];
}

final class MedicationDeleted extends MedicationsEvent {
  final Medication medication;
  const MedicationDeleted(this.medication);

  @override
  List<Object?> get props => [medication];
}

/// Logs a dose as given now; reschedules interval-based reminders.
final class DoseMarkedGiven extends MedicationsEvent {
  final Medication medication;
  final String notificationTitle;
  final String notificationBody;

  const DoseMarkedGiven({
    required this.medication,
    required this.notificationTitle,
    required this.notificationBody,
  });

  @override
  List<Object?> get props => [medication, notificationTitle, notificationBody];
}
