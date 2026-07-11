import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/medication.dart';
import '../../../domain/entities/pet.dart';
import '../../../domain/usecases/delete_medication.dart';
import '../../../domain/usecases/get_medications.dart';
import '../../../domain/usecases/log_dose.dart';
import '../../../domain/usecases/save_medication.dart';

part 'medications_event.dart';
part 'medications_state.dart';

/// Manages the medications of a single [pet].
class MedicationsBloc extends Bloc<MedicationsEvent, MedicationsState> {
  final Pet pet;
  final GetMedications _getMedications;
  final SaveMedication _saveMedication;
  final DeleteMedication _deleteMedication;
  final LogDose _logDose;

  MedicationsBloc({
    required this.pet,
    required GetMedications getMedications,
    required SaveMedication saveMedication,
    required DeleteMedication deleteMedication,
    required LogDose logDose,
  })  : _getMedications = getMedications,
        _saveMedication = saveMedication,
        _deleteMedication = deleteMedication,
        _logDose = logDose,
        super(const MedicationsState()) {
    on<MedicationsRequested>(_onRequested);
    on<MedicationSaved>(_onSaved);
    on<MedicationDeleted>(_onDeleted);
    on<DoseMarkedGiven>(_onDoseMarkedGiven);
  }

  Future<void> _onRequested(
      MedicationsRequested event, Emitter<MedicationsState> emit) async {
    emit(state.copyWith(status: MedicationsStatus.loading));
    await _emitMedications(emit);
  }

  Future<void> _onSaved(
      MedicationSaved event, Emitter<MedicationsState> emit) async {
    await _saveMedication(
      event.medication,
      notificationTitle: event.notificationTitle,
      notificationBody: event.notificationBody,
    );
    await _emitMedications(emit);
  }

  Future<void> _onDeleted(
      MedicationDeleted event, Emitter<MedicationsState> emit) async {
    await _deleteMedication(event.medication);
    await _emitMedications(emit);
  }

  Future<void> _onDoseMarkedGiven(
      DoseMarkedGiven event, Emitter<MedicationsState> emit) async {
    await _logDose(
      event.medication,
      notificationTitle: event.notificationTitle,
      notificationBody: event.notificationBody,
    );
    emit(state.copyWith(
      doseLogCount: state.doseLogCount + 1,
      lastDosedMedName: event.medication.name,
    ));
  }

  Future<void> _emitMedications(Emitter<MedicationsState> emit) async {
    try {
      final meds = await _getMedications(pet.id!);
      emit(state.copyWith(
          status: MedicationsStatus.success, medications: meds));
    } catch (e) {
      emit(state.copyWith(
          status: MedicationsStatus.failure, error: e.toString()));
    }
  }
}
