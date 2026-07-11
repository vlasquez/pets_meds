import 'package:flutter/material.dart';

import '../../domain/entities/pet.dart';
import 'pet_avatar.dart';

/// List tile for a pet with its photo (or species icon).
class PetListTile extends StatelessWidget {
  final Pet pet;
  final VoidCallback onTap;

  const PetListTile({super.key, required this.pet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: PetAvatar(pet: pet),
      title: Text(pet.name),
      subtitle: pet.notes == null || pet.notes!.isEmpty
          ? null
          : Text(pet.notes!, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }
}
