part of 'progress_bloc.dart';

enum ProgressStatus { initial, loading, success, failure }

/// One scheduled day of a treatment with its logged intakes.
final class DayProgress extends Equatable {
  final Treatment treatment;
  final DateTime date;
  final int expected;

  /// One entry per expected intake (aligned with the treatment's intake
  /// hours): the dose log id when that intake was taken, or null. Each
  /// intake is independent — no need to check earlier ones first.
  final List<int?> slotLogIds;

  const DayProgress({
    required this.treatment,
    required this.date,
    required this.expected,
    required this.slotLogIds,
  });

  int get given => slotLogIds.where((id) => id != null).length;
  bool get completed => given >= expected;

  bool isTaken(int index) =>
      index >= 0 && index < slotLogIds.length && slotLogIds[index] != null;

  int? logIdAt(int index) =>
      (index >= 0 && index < slotLogIds.length) ? slotLogIds[index] : null;

  @override
  List<Object?> get props => [treatment, date, expected, slotLogIds];
}

/// A treatment's day-by-day progress (most recent day first).
final class TreatmentProgress extends Equatable {
  final Treatment treatment;
  final Pet pet;
  final List<DayProgress> days;

  const TreatmentProgress({
    required this.treatment,
    required this.pet,
    required this.days,
  });

  int get expectedTotal =>
      days.fold(0, (sum, d) => sum + d.expected);
  int get givenTotal => days.fold(
      0, (sum, d) => sum + (d.given > d.expected ? d.expected : d.given));
  double get progress =>
      expectedTotal == 0 ? 0 : (givenTotal / expectedTotal).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [treatment, pet, days];
}

final class ProgressState extends Equatable {
  final ProgressStatus status;
  final List<TreatmentProgress> entries;
  final String? error;

  const ProgressState({
    this.status = ProgressStatus.initial,
    this.entries = const [],
    this.error,
  });

  ProgressState copyWith({
    ProgressStatus? status,
    List<TreatmentProgress>? entries,
    String? error,
  }) =>
      ProgressState(
        status: status ?? this.status,
        entries: entries ?? this.entries,
        error: error,
      );

  @override
  List<Object?> get props => [status, entries, error];
}
