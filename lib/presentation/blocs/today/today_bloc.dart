import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/medication.dart';
import '../../../domain/entities/pet.dart';
import '../../../domain/usecases/get_all_medications.dart';
import '../../../domain/usecases/get_dose_history.dart';
import '../../../domain/usecases/get_pets.dart';
import '../../../domain/usecases/log_dose.dart';

part 'today_event.dart';
part 'today_state.dart';

/// Home tab: the treatments scheduled for today, grouped by pet.
class TodayBloc extends Bloc<TodayEvent, TodayState> {
  final GetPets _getPets;
  final GetAllMedications _getAllMedications;
  final GetDoseHistory _getDoseHistory;
  final LogDose _logDose;

  TodayBloc({
    required GetPets getPets,
    required GetAllMedications getAllMedications,
    required GetDoseHistory getDoseHistory,
    required LogDose logDose,
  })  : _getPets = getPets,
        _getAllMedications = getAllMedications,
        _getDoseHistory = getDoseHistory,
        _logDose = logDose,
        super(const TodayState()) {
    on<TodayRequested>(_onRequested);
    on<TodayDoseGiven>(_onDoseGiven);
  }

  Future<void> _onRequested(
      TodayRequested event, Emitter<TodayState> emit) async {
    emit(state.copyWith(status: TodayStatus.loading));
    await _emitToday(emit);
  }

  Future<void> _onDoseGiven(
      TodayDoseGiven event, Emitter<TodayState> emit) async {
    await _logDose(
      event.medication,
      notificationTitle: event.notificationTitle,
      notificationBody: event.notificationBody,
    );
    emit(state.copyWith(
      doseLogCount: state.doseLogCount + 1,
      lastDosedMedName: event.medication.name,
    ));
    await _emitToday(emit);
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _emitToday(Emitter<TodayState> emit) async {
    try {
      final today = DateTime.now();
      final pets = await _getPets();
      final meds = await _getAllMedications();

      final entries = <TodayEntry>[];
      for (final pet in pets) {
        final petMeds = meds
            .where((m) => m.petId == pet.id && m.isScheduledOn(today))
            .toList();
        if (petMeds.isEmpty) continue;

        final history = await _getDoseHistory(pet.id!);
        final givenTodayIds = history.logs
            .where((log) => _isSameDay(log.givenAt, today))
            .map((log) => log.medicationId)
            .toSet();

        entries.add(TodayEntry(
          pet: pet,
          items: [
            for (final med in petMeds)
              TodayItem(
                medication: med,
                givenToday: givenTodayIds.contains(med.id),
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
