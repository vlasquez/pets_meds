part of 'today_bloc.dart';

sealed class TodayEvent extends Equatable {
  const TodayEvent();

  @override
  List<Object?> get props => [];
}

final class TodayRequested extends TodayEvent {
  const TodayRequested();
}

/// Marks a dose as given from the Home tab.
final class TodayDoseGiven extends TodayEvent {
  final Medication medication;
  final String notificationTitle;
  final String notificationBody;

  const TodayDoseGiven({
    required this.medication,
    required this.notificationTitle,
    required this.notificationBody,
  });

  @override
  List<Object?> get props => [medication, notificationTitle, notificationBody];
}
