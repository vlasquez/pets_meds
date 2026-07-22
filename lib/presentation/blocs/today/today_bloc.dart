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
        // All of today's logs per treatment, oldest first (logs come
        // newest-first from the repository).
        final todayLogIds = <int, List<int>>{};
        for (final log in history.logs.reversed) {
          if (_isSameDay(log.givenAt, today)) {
            todayLogIds.putIfAbsent(log.treatmentId, () => []).add(log.id!);
          }
        }

        entries.add(TodayEntry(
          pet: pet,
          items: [
            for (final t in petTreatments)
              TodayItem(
                treatment: t,
                todayLogIds: todayLogIds[t.id] ?? const [],
              ),
          ],
        ));
      }
      emit(state.copyWith(status: TodayStatus.success, entries: entries));
    } catch (e) {
      emit(state.copyWith(status: TodayStatus.failure, error: e.toString()));
    }
  }
}
