part of 'vaccinations_bloc.dart';

sealed class VaccinationsEvent extends Equatable {
  const VaccinationsEvent();

  @override
  List<Object?> get props => [];
}

final class VaccinationsRequested extends VaccinationsEvent {
  const VaccinationsRequested();
}

/// Inserts a vaccination and schedules its reminder.
/// [notificationTitle] and [notificationBody] are localized by the UI.
final class VaccinationSaved extends VaccinationsEvent {
  final Vaccination vaccination;
  final String notificationTitle;
  final String notificationBody;

  const VaccinationSaved({
    required this.vaccination,
    required this.notificationTitle,
    required this.notificationBody,
  });

  @override
  List<Object?> get props =>
      [vaccination, notificationTitle, notificationBody];
}

final class VaccinationDeleted extends VaccinationsEvent {
  final Vaccination vaccination;
  const VaccinationDeleted(this.vaccination);

  @override
  List<Object?> get props => [vaccination];
}
