import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/pet.dart';
import '../../../domain/entities/weight_entry.dart';
import '../../../domain/usecases/delete_weight_entry.dart';
import '../../../domain/usecases/get_weight_history.dart';
import '../../../domain/usecases/log_weight.dart';

part 'weight_event.dart';
part 'weight_state.dart';

/// Manages the weight history of a single [pet].
class WeightBloc extends Bloc<WeightEvent, WeightState> {
  final Pet pet;
  final GetWeightHistory _getWeightHistory;
  final LogWeight _logWeight;
  final DeleteWeightEntry _deleteWeightEntry;

  WeightBloc({
    required this.pet,
    required GetWeightHistory getWeightHistory,
    required LogWeight logWeight,
    required DeleteWeightEntry deleteWeightEntry,
  })  : _getWeightHistory = getWeightHistory,
        _logWeight = logWeight,
        _deleteWeightEntry = deleteWeightEntry,
        super(const WeightState()) {
    on<WeightHistoryRequested>(_onRequested);
    on<WeightLogged>(_onLogged);
    on<WeightEntryDeleted>(_onDeleted);
  }

  Future<void> _onRequested(
      WeightHistoryRequested event, Emitter<WeightState> emit) async {
    emit(state.copyWith(status: WeightStatus.loading));
    await _emitEntries(emit);
  }

  Future<void> _onLogged(WeightLogged event, Emitter<WeightState> emit) async {
    await _logWeight(WeightEntry(
      petId: pet.id!,
      weightKg: event.weightKg,
      measuredAt: event.measuredAt,
      note: event.note,
    ));
    await _emitEntries(emit);
  }

  Future<void> _onDeleted(
      WeightEntryDeleted event, Emitter<WeightState> emit) async {
    await _deleteWeightEntry(event.entry.id!);
    await _emitEntries(emit);
  }

  Future<void> _emitEntries(Emitter<WeightState> emit) async {
    try {
      final entries = await _getWeightHistory(pet.id!);
      emit(state.copyWith(status: WeightStatus.success, entries: entries));
    } catch (e) {
      emit(state.copyWith(status: WeightStatus.failure, error: e.toString()));
    }
  }
}
