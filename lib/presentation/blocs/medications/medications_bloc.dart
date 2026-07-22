import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/medication.dart';
import '../../../domain/usecases/delete_medication.dart';
import '../../../domain/usecases/get_all_treatments.dart';
import '../../../domain/usecases/get_medications.dart';

part 'medications_event.dart';
part 'medications_state.dart';

/// Manages the medication catalog: list, with how many treatments use
/// each medication, and delete. Add/edit go through MedicationFormScreen
/// (which saves directly); this bloc just reloads afterwards.
class MedicationsBloc extends Bloc<MedicationsEvent, MedicationsState> {
  final GetMedications _getMedications;
  final GetAllTreatments _getAllTreatments;
  final DeleteMedication _deleteMedication;

  MedicationsBloc({
    required GetMedications getMedications,
    required GetAllTreatments getAllTreatments,
    required DeleteMedication deleteMedication,
  })  : _getMedications = getMedications,
        _getAllTreatments = getAllTreatments,
        _deleteMedication = deleteMedication,
        super(const MedicationsState()) {
    on<MedicationsRequested>(_onRequested);
    on<MedicationDeleted>(_onDeleted);
  }

  Future<void> _onRequested(
      MedicationsRequested event, Emitter<MedicationsState> emit) async {
    emit(state.copyWith(status: MedicationsStatus.loading));
    await _emit(emit);
  }

  Future<void> _onDeleted(
      MedicationDeleted event, Emitter<MedicationsState> emit) async {
    await _deleteMedication(event.medicationId);
    await _emit(emit);
  }

  Future<void> _emit(Emitter<MedicationsState> emit) async {
    try {
      final medications = await _getMedications();
      final treatments = await _getAllTreatments();
      final usage = <int, int>{};
      for (final t in treatments) {
        usage[t.medicationId] = (usage[t.medicationId] ?? 0) + 1;
      }
      emit(state.copyWith(
        status: MedicationsStatus.success,
        medications: medications,
        usageCounts: usage,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: MedicationsStatus.failure, error: e.toString()));
    }
  }
}
