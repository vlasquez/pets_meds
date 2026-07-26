part of 'pets_overview_bloc.dart';

sealed class PetsOverviewEvent extends Equatable {
  const PetsOverviewEvent();

  @override
  List<Object?> get props => [];
}

final class PetsOverviewRequested extends PetsOverviewEvent {
  const PetsOverviewRequested();
}
