part of 'today_bloc.dart';

enum TodayStatus { initial, loading, success, failure }

/// A treatment scheduled today plus today's dose logs.
final class TodayItem extends Equatable {
  final Treatment treatment;

  /// Ids of today's dose logs for this treatment, oldest first.
  /// Each log is one intake; unchecking deletes the latest one.
  final List<int> todayLogIds;

  const TodayItem({required this.treatment, this.todayLogIds = const []});

  /// Intakes taken today.
  int get givenCount => todayLogIds.length;

  /// Intakes expected today.
  int get targetCount => treatment.dosesPerDay;

  /// The intake hours of the day (may be empty for on-demand).
  List<ScheduleTime> get intakeTimes => treatment.intakeTimesPerDay;

  /// The treatment is complete for the day when every intake was taken.
  bool get completed => givenCount >= targetCount;

  double get progress =>
      targetCount == 0 ? 0 : (givenCount / targetCount).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [treatment, todayLogIds];
}

/// A pet with its treatments scheduled for today.
final class TodayEntry extends Equatable {
  final Pet pet;
  final List<TodayItem> items;

  const TodayEntry({required this.pet, required this.items});

  @override
  List<Object?> get props => [pet, items];
}

final class TodayState extends Equatable {
  final TodayStatus status;
  final List<TodayEntry> entries;

  /// Incremented on each dose logged from Home (for a snackbar via listener).
  final int doseLogCount;
  final String? lastDosedName;

  final String? error;

  const TodayState({
    this.status = TodayStatus.initial,
    this.entries = const [],
    this.doseLogCount = 0,
    this.lastDosedName,
    this.error,
  });

  TodayState copyWith({
    TodayStatus? status,
    List<TodayEntry>? entries,
    int? doseLogCount,
    String? lastDosedName,
    String? error,
  }) =>
      TodayState(
        status: status ?? this.status,
        entries: entries ?? this.entries,
        doseLogCount: doseLogCount ?? this.doseLogCount,
        lastDosedName: lastDosedName ?? this.lastDosedName,
        error: error,
      );

  @override
  List<Object?> get props =>
      [status, entries, doseLogCount, lastDosedName, error];
}
