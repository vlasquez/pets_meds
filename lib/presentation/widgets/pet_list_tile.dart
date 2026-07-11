import 'package:flutter/material.dart';

import '../../domain/entities/pet.dart';

/// List tile for a pet with a species icon.
class PetListTile extends StatelessWidget {
  final Pet pet;
  final VoidCallback onTap;

  const PetListTile({super.key, required this.pet, required this.onTap});

  IconData get _speciesIcon {
    switch (pet.species) {
      case 'dog':
        return Icons.pets;
      case 'cat':
        return Icons.pets_outlined;
      default:
        return Icons.cruelty_free;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Icon(_speciesIcon)),
      title: Text(pet.name),
      subtitle: pet.notes == null || pet.notes!.isEmpty
          ? null
          : Text(pet.notes!, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }
}
