import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pet.dart';
import '../../utils/strings.dart';
import '../blocs/pets_overview/pets_overview_bloc.dart';
import '../blocs/today/today_bloc.dart';
import '../blocs/treatments/treatments_bloc.dart';
import '../widgets/empty_state.dart';
import '../widgets/gender_icon.dart';
import '../widgets/pet_avatar.dart';
import 'pet_detail_screen.dart';
import 'pet_form_screen.dart';

/// Pets tab: the roster of every pet as an expandable card. Expanding a
/// card shows a summary (last weight, last vaccination, active
/// treatments); tapping the pet opens its full detail.
/// Expects a [PetsOverviewBloc] above it.
class PetsScreen extends StatelessWidget {
  const PetsScreen({super.key});

  void _openDetail(BuildContext context, Pet pet) {
    final overviewBloc = context.read<PetsOverviewBloc>();
    final todayBloc = context.read<TodayBloc>();
    final treatmentsBloc = context.read<TreatmentsBloc>();
    Navigator.of(context)
        .push(
      MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pet)),
    )
        .then((_) {
      overviewBloc.add(const PetsOverviewRequested());
      todayBloc.add(const TodayRequested());
      treatmentsBloc.add(const TreatmentsRequested());
    });
  }

  Future<void> _addPet(BuildContext context) async {
    final overviewBloc = context.read<PetsOverviewBloc>();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PetFormScreen()),
    );
    overviewBloc.add(const PetsOverviewRequested());
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.myPets)),
      body: BlocBuilder<PetsOverviewBloc, PetsOverviewState>(
        builder: (context, state) {
          switch (state.status) {
            case PetsOverviewStatus.initial:
            case PetsOverviewStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case PetsOverviewStatus.failure:
              return EmptyState(message: state.error ?? 'Error');
            case PetsOverviewStatus.success:
              if (state.items.isEmpty) {
                return EmptyState(message: s.noPets);
              }
              return ListView(
                padding: const EdgeInsets.only(bottom: 88),
                children: [
                  for (final item in state.items)
                    _PetCard(
                      item: item,
                      onOpen: () => _openDetail(context, item.pet),
                    ),
                ],
              );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'pets_fab',
        tooltip: s.addPet,
        onPressed: () => _addPet(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final PetOverview item;
  final VoidCallback onOpen;
  const _PetCard({required this.item, required this.onOpen});

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _row(BuildContext context, IconData icon, String text,
      {bool muted = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: muted ? theme.colorScheme.onSurfaceVariant : null,
                )),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final pet = item.pet;
    final age = pet.ageAt(DateTime.now());
    final breed = s.breedName(pet.species, pet.breed);
    final headerParts = [
      if (breed != null) breed,
      if (age != null) s.age(age.$1, age.$2),
    ];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
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
            headerParts.isEmpty ? null : Text(headerParts.join(' · ')),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row(
                  context,
                  Icons.monitor_weight_outlined,
                  item.lastWeightKg != null
                      ? '${s.lastWeight}: ${item.lastWeightKg} kg'
                      : s.noWeightYet,
                  muted: item.lastWeightKg == null,
                ),
                _row(
                  context,
                  Icons.vaccines_outlined,
                  item.lastVaccinationDate != null
                      ? '${s.lastVaccination}: ${_fmtDate(item.lastVaccinationDate!)}'
                      : s.noVaccinationYet,
                  muted: item.lastVaccinationDate == null,
                ),
                _row(
                  context,
                  Icons.medication_outlined,
                  item.totalTreatments == 0
                      ? s.nTreatments(0)
                      : s.treatmentSummary(
                          item.activeTreatments,
                          item.inactiveTreatments,
                          item.completedTreatments,
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.chevron_right, size: 18),
              label: Text(s.viewPetDetails),
              onPressed: onOpen,
            ),
          ),
        ],
      ),
    );
  }
}
