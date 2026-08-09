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

part 'today_event.dart';
part 'today_state.dart';

/// Home tab: the treatments scheduled for today, grouped by pet.
class TodayBloc extends Bloc<TodayEvent, TodayState> {
  final GetPets _getPets;
  final GetAllTreatments _getAllTreatments;
  final GetDoseHistory _getDoseHistory;
  final LogDose _logDose;
  final DeleteDoseLog _deleteDoseLog;

  TodayBloc({
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
        super(const TodayState()) {
    on<TodayRequested>(_onRequested);
    on<TodayDoseGiven>(_onDoseGiven);
    on<TodayDoseUnmarked>(_onDoseUnmarked);
  }

  Future<void> _onRequested(
      TodayRequested event, Emitter<TodayState> emit) async {
    emit(state.copyWith(status: TodayStatus.loading));
    await _emitToday(emit);
  }

  Future<void> _onDoseGiven(
      TodayDoseGiven event, Emitter<TodayState> emit) async {
    await _logDose(
      event.treatment,
      notificationTitle: event.notificationTitle,
      notificationBody: event.notificationBody,
      givenAt: event.at,
    );
    emit(state.copyWith(
      doseLogCount: state.doseLogCount + 1,
      lastDosedName: event.treatment.medicationName,
    ));
    await _emitToday(emit);
  }

  Future<void> _onDoseUnmarked(
      TodayDoseUnmarked event, Emitter<TodayState> emit) async {
    await _deleteDoseLog(event.logId);
    await _emitToday(emit);
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Maps today's dose logs to one slot per expected intake. Slots align
  /// with the treatment's intake hours: a log is matched to the slot with
  /// the same hour:minute, so each intake is independent. On-demand (no
  /// intake hours) fills its single slot with any log of the day.
  List<int?> _slotLogIds(
      Treatment t, List<DoseLog> allLogs, DateTime today) {
    final logs = allLogs
        .where((l) => l.treatmentId == t.id && _isSameDay(l.givenAt, today))
        .toList();
    final intakes = t.intakeTimesPerDay;

    if (intakes.isEmpty) {
      // No fixed hours: fill slots positionally by count.
      final slots = List<int?>.filled(t.dosesPerDay, null);
      for (var i = 0; i < slots.length && i < logs.length; i++) {
        slots[i] = logs[i].id;
      }
      return slots;
    }

    final remaining = List.of(logs);
    return [
      for (final time in intakes)
        _takeMatching(remaining, time.hour, time.minute),
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

  Future<void> _emitToday(Emitter<TodayState> emit) async {
    try {
      final today = DateTime.now();
      final pets = await _getPets();
      final treatments = await _getAllTreatments();

      // One entry per pet (even with no treatments today), so Home can
      // list every pet.
      final entries = <TodayEntry>[];
      for (final pet in pets) {
        final petTreatments = treatments
            .where((t) => t.petId == pet.id && t.isScheduledOn(today))
            .toList();
        if (petTreatments.isEmpty) {
          entries.add(TodayEntry(pet: pet, items: const []));
          continue;
        }

        final history = await _getDoseHistory(pet.id!);
        entries.add(TodayEntry(
          pet: pet,
          items: [
            for (final t in petTreatments)
              TodayItem(
                treatment: t,
                slotLogIds: _slotLogIds(t, history.logs, today),
              ),
          ],
        ));
      }
      // Pets with treatments today first; empty ones at the end.
      // Stable within each group (preserves the pets' name order).
      final withItems = entries.where((e) => e.items.isNotEmpty);
      final withoutItems = entries.where((e) => e.items.isEmpty);
      emit(state.copyWith(
        status: TodayStatus.success,
        entries: [...withItems, ...withoutItems],
      ));
    } catch (e) {
      emit(state.copyWith(status: TodayStatus.failure, error: e.toString()));
    }
  }
}
