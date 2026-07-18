import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/pet.dart';
import '../../../domain/entities/schedule_time.dart';
import '../../../domain/entities/treatment.dart';
import '../../../domain/usecases/delete_dose_log.dart';
import '../../../domain/usecases/get_all_treatments.dart';
import '../../../domain/usecases/get_dose_history.dart';
import '../../../domain/usecases/get_pets.dart';
import '../../../domain/usecases/log_dose.dart';

part 'progress_event.dart';
part 'progress_state.dart';

/// Progress tab: day-by-day dose history of every treatment from its
/// start date until today, with retroactive check/uncheck.
class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  /// How many scheduled days back to show per treatment.
  static const maxDays = 60;

  final GetPets _getPets;
  final GetAllTreatments _getAllTreatments;
  final GetDoseHistory _getDoseHistory;
  final LogDose _logDose;
  final DeleteDoseLog _deleteDoseLog;

  ProgressBloc({
    required GetPets getPets,
    required GetAllTreatments getAllTreatments,
    required GetDoseHistory getDoseHistory,
    required LogDose logDose,
    required DeleteDoseLog deleteDoseLog,
  })  : _getPets = getPets,
        _getAllTreatments = getAllTreatments,
        _getDoseHistory = getDoseHistory,
        _logDose = logDose,
        _deleteDoseLog = deleteDoseLog,
        super(const ProgressState()) {
    on<ProgressRequested>(_onRequested);
    on<ProgressDoseChecked>(_onChecked);
    on<ProgressDoseUnchecked>(_onUnchecked);
  }

  Future<void> _onRequested(
      ProgressRequested event, Emitter<ProgressState> emit) async {
    emit(state.copyWith(status: ProgressStatus.loading));
    await _emitProgress(emit);
  }

  Future<void> _onChecked(
      ProgressDoseChecked event, Emitter<ProgressState> emit) async {
    // Log the dose at the day's next open intake hour (or noon).
    final t = event.day.treatment;
    final intakes = t.intakeTimesPerDay;
    final index = event.day.logIds.length;
    final time = index < intakes.length
        ? intakes[index]
        : const ScheduleTime(12, 0);
    await _logDose(
      t,
      notificationTitle: event.notificationTitle,
      notificationBody: event.notificationBody,
      givenAt: DateTime(event.day.date.year, event.day.date.month,
          event.day.date.day, time.hour, time.minute),
    );
    await _emitProgress(emit);
  }

  Future<void> _onUnchecked(
      ProgressDoseUnchecked event, Emitter<ProgressState> emit) async {
    await _deleteDoseLog(event.logId);
    await _emitProgress(emit);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _emitProgress(Emitter<ProgressState> emit) async {
    try {
      final today = _dateOnly(DateTime.now());
      final pets = await _getPets();
      final treatments = await _getAllTreatments();
      final petsById = {for (final p in pets) p.id!: p};

      // Logs per pet, grouped by treatment and day (oldest first).
      final entries = <TreatmentProgress>[];
      final historyByPet = <int, Map<int, Map<DateTime, List<int>>>>{};
      for (final t in treatments) {
        final pet = petsById[t.petId];
        if (pet == null) continue;

        final byTreatment = historyByPet[t.petId] ??= await () async {
          final history = await _getDoseHistory(t.petId);
          final grouped = <int, Map<DateTime, List<int>>>{};
          for (final log in history.logs.reversed) {
            grouped
                .putIfAbsent(log.treatmentId, () => {})
                .putIfAbsent(_dateOnly(log.givenAt), () => [])
                .add(log.id!);
          }
          return grouped;
        }();
        final logsByDay = byTreatment[t.id] ?? const {};

        // Scheduled days from start (or the cap) until today, recent first.
        final days = <DayProgress>[];
        var day = today;
        final start = _dateOnly(t.startDate);
        while (!day.isBefore(start) && days.length < maxDays) {
          if (t.isScheduledOn(day)) {
            days.add(DayProgress(
              treatment: t,
              date: day,
              expected: t.dosesPerDay,
              logIds: logsByDay[day] ?? const [],
            ));
          }
          day = day.subtract(const Duration(days: 1));
        }
        if (days.isNotEmpty) {
          entries.add(TreatmentProgress(treatment: t, pet: pet, days: days));
        }
      }
      emit(state.copyWith(status: ProgressStatus.success, entries: entries));
    } catch (e) {
      emit(
          state.copyWith(status: ProgressStatus.failure, error: e.toString()));
    }
  }
}
