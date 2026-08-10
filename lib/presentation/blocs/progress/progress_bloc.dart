import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/dose_log.dart';
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
    // Log the dose at the selected intake's hour (or noon for on-demand).
    final t = event.day.treatment;
    final intakes = t.intakeTimesPerDay;
    final index = event.intakeIndex;
    final time = index >= 0 && index < intakes.length
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

  /// Maps a day's dose logs to one slot per expected intake, matching each
  /// log to the slot with the same hour:minute so every intake is
  /// independent. On-demand (no fixed hours) fills slots positionally.
  static List<int?> _slotLogIds(Treatment t, List<DoseLog> dayLogs) {
    final intakes = t.intakeTimesPerDay;
    if (intakes.isEmpty) {
      final slots = List<int?>.filled(t.dosesPerDay, null);
      for (var i = 0; i < slots.length && i < dayLogs.length; i++) {
        slots[i] = dayLogs[i].id;
      }
      return slots;
    }
    final remaining = List.of(dayLogs);
    return [
      for (final time in intakes) _takeMatching(remaining, time.hour, time.minute),
    ];
  }

  /// Removes and returns the id of a log at [hour]:[minute], or null.
  static int? _takeMatching(List<DoseLog> logs, int hour, int minute) {
    final idx = logs.indexWhere(
        (l) => l.givenAt.hour == hour && l.givenAt.minute == minute);
    if (idx < 0) return null;
    final id = logs[idx].id;
    logs.removeAt(idx);
    return id;
  }

  Future<void> _emitProgress(Emitter<ProgressState> emit) async {
    try {
      final today = _dateOnly(DateTime.now());
      final pets = await _getPets();
      final treatments = await _getAllTreatments();
      final petsById = {for (final p in pets) p.id!: p};

      // Logs per pet, grouped by treatment and day (oldest first).
      final entries = <TreatmentProgress>[];
      final historyByPet = <int, Map<int, Map<DateTime, List<DoseLog>>>>{};
      for (final t in treatments) {
        final pet = petsById[t.petId];
        if (pet == null) continue;

        final byTreatment = historyByPet[t.petId] ??= await () async {
          final history = await _getDoseHistory(t.petId);
          final grouped = <int, Map<DateTime, List<DoseLog>>>{};
          for (final log in history.logs.reversed) {
            grouped
                .putIfAbsent(log.treatmentId, () => {})
                .putIfAbsent(_dateOnly(log.givenAt), () => [])
                .add(log);
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
              slotLogIds: _slotLogIds(t, logsByDay[day] ?? const []),
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
