part of 'treatments_bloc.dart';

sealed class TreatmentsEvent extends Equatable {
  const TreatmentsEvent();

  @override
  List<Object?> get props => [];
}

final class TreatmentsRequested extends TreatmentsEvent {
  const TreatmentsRequested();
}

/// Insert (id == null) or update a treatment, (re)scheduling its reminders.
final class TreatmentSaved extends TreatmentsEvent {
  final Treatment treatment;
  final String notificationTitle;
  final String notificationBody;

  const TreatmentSaved({
    required this.treatment,
    required this.notificationTitle,
    required this.notificationBody,
  });

  @override
  List<Object?> get props => [treatment, notificationTitle, notificationBody];
}

final class TreatmentDeleted extends TreatmentsEvent {
  final Treatment treatment;
  const TreatmentDeleted(this.treatment);

  @override
  List<Object?> get props => [treatment];
}
