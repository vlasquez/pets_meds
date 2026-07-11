import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../l10n/strings.dart';
import '../blocs/pets/pets_bloc.dart';
import '../widgets/empty_state.dart';
import '../widgets/pet_list_tile.dart';
import 'pet_detail_screen.dart';
import 'pet_form_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              return ListView.builder(
                itemCount: state.pets.length,
                itemBuilder: (context, i) {
                  final pet = state.pets[i];
                  return PetListTile(
                    pet: pet,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PetDetailScreen(pet: pet),
                      ),
                    ),
                  );
                },
              );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: s.addPet,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PetFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
