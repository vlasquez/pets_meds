part of 'today_bloc.dart';

enum TodayStatus { initial, loading, success, failure }

/// A treatment scheduled today with per-intake state.
final class TodayItem extends Equatable {
  final Treatment treatment;

  /// One entry per expected intake (aligned with [intakeTimes]): the dose
  /// log id when that intake was taken, or null when it wasn't. Each intake
  /// is checked independently — no need to check earlier ones first.
  final List<int?> slotLogIds;

  const TodayItem({required this.treatment, required this.slotLogIds});

  /// Intakes taken today.
  int get givenCount => slotLogIds.where((id) => id != null).length;

  /// Intakes expected today.
  int get targetCount => slotLogIds.length;

  /// The intake hours of the day (may be empty for on-demand).
  List<ScheduleTime> get intakeTimes => treatment.intakeTimesPerDay;

  bool isTaken(int index) =>
      index >= 0 && index < slotLogIds.length && slotLogIds[index] != null;

  int? logIdAt(int index) =>
      (index >= 0 && index < slotLogIds.length) ? slotLogIds[index] : null;

  /// The treatment is complete for the day when every intake was taken.
  bool get completed => targetCount > 0 && givenCount >= targetCount;

  double get progress =>
      targetCount == 0 ? 0 : (givenCount / targetCount).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [treatment, slotLogIds];
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
