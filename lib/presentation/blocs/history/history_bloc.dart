import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/dose_log.dart';
import '../../../domain/entities/pet.dart';
import '../../../domain/entities/treatment.dart';
import '../../../domain/usecases/get_dose_history.dart';

part 'history_event.dart';
part 'history_state.dart';

/// Loads the dose history of a single [pet].
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final Pet pet;
  final GetDoseHistory _getDoseHistory;

  HistoryBloc({required this.pet, required GetDoseHistory getDoseHistory})
      : _getDoseHistory = getDoseHistory,
        super(const HistoryState()) {
    on<HistoryRequested>(_onRequested);
  }

  Future<void> _onRequested(
      HistoryRequested event, Emitter<HistoryState> emit) async {
    emit(state.copyWith(status: HistoryStatus.loading));
    try {
      final history = await _getDoseHistory(pet.id!);
      emit(state.copyWith(
        status: HistoryStatus.success,
        logs: history.logs,
        treatmentsById: history.treatmentsById,
      ));
    } catch (e) {
      emit(state.copyWith(status: HistoryStatus.failure, error: e.toString()));
    }
  }
}
