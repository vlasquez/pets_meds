part of 'pets_bloc.dart';

enum PetsStatus { initial, loading, success, failure }

final class PetsState extends Equatable {
  final PetsStatus status;
  final List<Pet> pets;
  final String? error;

  const PetsState({
    this.status = PetsStatus.initial,
    this.pets = const [],
    this.error,
  });

  PetsState copyWith({
    PetsStatus? status,
    List<Pet>? pets,
    String? error,
  }) =>
      PetsState(
        status: status ?? this.status,
        pets: pets ?? this.pets,
        error: error,
      );

  @override
  List<Object?> get props => [status, pets, error];
}
