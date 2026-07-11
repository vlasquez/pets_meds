part of 'pets_bloc.dart';

sealed class PetsEvent extends Equatable {
  const PetsEvent();

  @override
  List<Object?> get props => [];
}

final class PetsRequested extends PetsEvent {
  const PetsRequested();
}

/// Insert (id == null) or update a pet.
final class PetSaved extends PetsEvent {
  final Pet pet;
  const PetSaved(this.pet);

  @override
  List<Object?> get props => [pet];
}

final class PetDeleted extends PetsEvent {
  final Pet pet;
  const PetDeleted(this.pet);

  @override
  List<Object?> get props => [pet];
}
