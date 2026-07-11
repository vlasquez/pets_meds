import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/pet.dart';
import '../../../domain/usecases/delete_pet.dart';
import '../../../domain/usecases/get_pets.dart';
import '../../../domain/usecases/save_pet.dart';

part 'pets_event.dart';
part 'pets_state.dart';

class PetsBloc extends Bloc<PetsEvent, PetsState> {
  final GetPets _getPets;
  final SavePet _savePet;
  final DeletePet _deletePet;

  PetsBloc({
    required GetPets getPets,
    required SavePet savePet,
    required DeletePet deletePet,
  })  : _getPets = getPets,
        _savePet = savePet,
        _deletePet = deletePet,
        super(const PetsState()) {
    on<PetsRequested>(_onRequested);
    on<PetSaved>(_onSaved);
    on<PetDeleted>(_onDeleted);
  }

  Future<void> _onRequested(
      PetsRequested event, Emitter<PetsState> emit) async {
    emit(state.copyWith(status: PetsStatus.loading));
    await _emitPets(emit);
  }

  Future<void> _onSaved(PetSaved event, Emitter<PetsState> emit) async {
    await _savePet(event.pet);
    await _emitPets(emit);
  }

  Future<void> _onDeleted(PetDeleted event, Emitter<PetsState> emit) async {
    await _deletePet(event.pet);
    await _emitPets(emit);
  }

  Future<void> _emitPets(Emitter<PetsState> emit) async {
    try {
      final pets = await _getPets();
      emit(state.copyWith(status: PetsStatus.success, pets: pets));
    } catch (e) {
      emit(state.copyWith(status: PetsStatus.failure, error: e.toString()));
    }
  }
}
