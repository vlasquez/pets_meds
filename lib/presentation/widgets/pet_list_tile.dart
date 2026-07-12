import 'package:flutter/material.dart';

import '../../domain/entities/pet.dart';
import '../../l10n/strings.dart';
import 'pet_avatar.dart';

/// List tile for a pet with its photo (or species silhouette),
/// breed and age.
class PetListTile extends StatelessWidget {
  final Pet pet;
  final VoidCallback onTap;

  const PetListTile({super.key, required this.pet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final age = pet.ageAt(DateTime.now());
    final parts = [
      if (s.breedName(pet.species, pet.breed) != null)
        s.breedName(pet.species, pet.breed)!,
      if (age != null) s.age(age.$1, age.$2),
    ];
    final subtitle = parts.isNotEmpty
        ? parts.join(' · ')
        : (pet.notes == null || pet.notes!.isEmpty ? null : pet.notes);

    return ListTile(
      leading: PetAvatar(pet: pet),
      title: Text(pet.name),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }
}
