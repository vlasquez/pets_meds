import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pet.dart';
import '../../utils/strings.dart';
import '../blocs/pets/pets_bloc.dart';
import '../blocs/today/today_bloc.dart';
import '../blocs/treatments/treatments_bloc.dart';
import '../widgets/empty_state.dart';
import '../widgets/gender_icon.dart';
import '../widgets/pet_avatar.dart';
import 'pet_detail_screen.dart';
import 'pet_form_screen.dart';

/// Pets tab: the roster of every pet. Tap a pet to open its full detail
/// (profile, weight, vaccinations, treatments). Add pets from the FAB.
class PetsScreen extends StatelessWidget {
  const PetsScreen({super.key});

  void _openDetail(BuildContext context, Pet pet) {
    final todayBloc = context.read<TodayBloc>();
    final treatmentsBloc = context.read<TreatmentsBloc>();
    Navigator.of(context)
        .push(
      MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pet)),
    )
        .then((_) {
      // Edits/deletes on the detail screen may affect other tabs.
      todayBloc.add(const TodayRequested());
      treatmentsBloc.add(const TreatmentsRequested());
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.myPets)),
      body: BlocBuilder<PetsBloc, PetsState>(
        builder: (context, state) {
          switch (state.status) {
            case PetsStatus.initial:
            case PetsStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case PetsStatus.failure:
              return EmptyState(message: state.error ?? 'Error');
            case PetsStatus.success:
              if (state.pets.isEmpty) {
                return EmptyState(message: s.noPets);
              }
              return ListView(
                padding: const EdgeInsets.only(bottom: 88),
                children: [
                  for (final pet in state.pets)
                    _PetTile(
                      pet: pet,
                      onTap: () => _openDetail(context, pet),
                    ),
                ],
              );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'pets_fab',
        tooltip: s.addPet,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PetFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PetTile extends StatelessWidget {
  final Pet pet;
  final VoidCallback onTap;
  const _PetTile({required this.pet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final age = pet.ageAt(DateTime.now());
    final breed = s.breedName(pet.species, pet.breed);
    final subtitleParts = [
      if (breed != null) breed,
      if (age != null) s.age(age.$1, age.$2),
    ];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: PetAvatar(pet: pet, radius: 24),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(pet.name,
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis),
            ),
            if (pet.gender != null) ...[
              const SizedBox(width: 6),
              GenderIcon(gender: pet.gender),
            ],
          ],
        ),
        subtitle:
            subtitleParts.isEmpty ? null : Text(subtitleParts.join(' · ')),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
